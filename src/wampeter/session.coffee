util          = require('./util')
logger        = util.logger()
parser        = util.parser()
randomid      = util.randomid
inherits      = require('util').inherits
EventEmitter  = require('events').EventEmitter
WebSocket     = require('ws')
q             = require('q')
_             = require('lodash')
Authenticator = require('./authenticator')

class Session extends EventEmitter
    constructor: (socket, supportedRoles, authenticationConfig = null, realms = null)->

        if not (socket instanceof WebSocket)
            throw new TypeError('wamp.error.invalid_socket')

        if not (_.isPlainObject(supportedRoles))
            throw new TypeError('wamp.error.invalid_roles')

        # save the realms configuration
        #
        @realms = realms

        # create the authenticator - this function will return null if no
        # authenticator is required (ie. if `authConfig` is null)
        #
        @authenticator = Authenticator(@, authConfig)

        EventEmitter.call(@)

        socket.on('open', ()->
            logger.debug('socket open')
        )

        socket.on('message', (data)=>
            logger.debug('socket message', data)
            @parse(data)
        )

        socket.on('error', (err)=>
            logger.error('socket error', err.stack)
            @close(null, null, false)
        )

        socket.on('close', (code, reason)=>
            logger.debug('socket close', code, reason ? '')
            @close(code, reason, code==1000)
        )

        @socket = socket
        @roles = supportedRoles

        @clientRole = null



    send: (type, opts)=>
        parser.encode(type, opts)
        .then((message)=>
            logger.debug('trying to send message', message)
            WebSocket.prototype.send.call(@socket, message, ()->
                logger.debug('%s message sent', type, message)
            )
        ).catch((err)->
            logger.error('cannot send %s message!', type, opts, err.stack)
        ).done()

    error: (type, id, err)=>
        if _.isString(type) and _.isNumber(id) and (err instanceof Error)
            @send('ERROR', {
                request:
                    type: type
                    id: id

                details:
                    stack: err.stack

                error: err.message
                args: []
                kwargs: {}
            })
        else
            throw new TypeError('wamp.error.invalid_argument')

    close: (code, reason, wasClean)=>
        if code>1006
            @send('GOODBYE', {details: {message: 'Close connection'}, reason: reason})

        defer = q.defer()
        @emit('close', defer)
        defer.promise

    parse: (data)=>
        parser.decode(data)
        .then((message)=>
            logger.debug('parsing message', message)
            switch message.type

                when 'HELLO'
                    # set an ID for the session
                    #
                    @id = randomid()

                    # start a promise to sort out the remainder of the message
                    #
                    q.fcall(()=>
                        # initialize the realm associated with this session
                        #
                        @realm = message.realm

                        defer = q.defer()
                        @emit('attach', message.realm, defer)
                        defer.promise
                    ).then(()=>
                        # time to send the next message - do we need to
                        # authenticate?
                        #
                        if not @authenticator?
                            # no authentication - send welcome message
                            #
                            @send('WELCOME', {
                                session: {id: @id},
                                details: {roles: @roles}
                            })
                        else
                            # need to authenticate - send the challenge message
                            #
                            @authenticator.challenge(message).then((challengeMessage)=>
                                logger.debug("------------------ challenge message", challengeMessage)
                                @send('CHALLENGE', challengeMessage)
                            ).catch((err)=>
                                logger.error('cannot send CHALLENGE message', err)
                                @send('ABORT', {
                                    details:
                                        message: 'Cannot establish session!'
                                    reason: err.message
                                })
                            ).done()
                    ).catch((err)=>
                        logger.error('cannot establish session', err.stack)
                        @send('ABORT', {
                            details:
                                message: 'Cannot establish session!'
                            reason: err.message
                        })
                    ).done()

                when 'AUTHENTICATE'
                    @authenticator?.authenticate(message).then((clientRole)=>

                        # save the client role for future authentication
                        #
                        @clientRole = clientRole

                        # if no exception was thrown, then we authenticated
                        # successfully. Time to send the welcome message
                        #
                        @send('WELCOME', {
                            session:
                                id: @id
                            details:
                                roles: @roles
                        })
                    ).catch((err)=>
                        # unable to authenticate - log the error and send an
                        # abort message to the client
                        #
                        logger.error('cannot authenticate', err)
                        @send('ABORT', {
                            details:
                                message: 'Cannot authenticate'
                            reason: err.message
                        })
                    ).done()

                when 'GOODBYE'
                    @close(1009, 'wamp.error.close_normal')

                when 'SUBSCRIBE'
                    q.fcall(()=>
                        logger.debug('try to subscribe to topic:', message.topic)
                        defer = q.defer()
                        @emit('subscribe', message.topic, defer)
                        defer.promise
                    ).then((subscriptionId)=>
                        @send('SUBSCRIBED', {
                            subscribe:
                                request:
                                    id: message.request.id
                            subscription:
                                id: subscriptionId
                        })
                    ).catch((err)=>
                        logger.error('cannot subscribe to topic', @realm, message.topic, err.stack)
                        @error('SUBSCRIBE', message.request.id, err)
                    ).done()

                when 'UNSUBSCRIBE'
                    q.fcall(()=>
                        defer = q.defer()
                        @emit('unsubscribe', message.subscribed.subscription.id, defer)
                        defer.promise
                    ).then(()=>
                        @send('UNSUBSCRIBED', {
                            unsubscribe:
                                request:
                                    id: message.request.id
                        })
                    ).catch((err)=>
                        logger.error('cannot unsubscribe from topic', message.subscribed.subscription.id, err.stack)
                        @error('UNSUBSCRIBE', message.request.id, err)
                    ).done()

                when 'PUBLISH'
                    q.fcall(()=>
                        defer = q.defer()
                        @emit('publish', message.topic, defer)
                        defer.promise
                    ).then((topic)=>
                        publicationId = randomid()

                        if message.options and message.options.acknowledge
                            @send('PUBLISHED', {
                                publish:
                                    request:
                                        id: message.request.id
                                publication:
                                    id: publicationId
                            })

                        queue = []
                        _.forEach(topic.sessions, (session)->
                            event = session.send('EVENT', {
                                subscribed:
                                    subscription:
                                        id: topic.id
                                published:
                                    publication:
                                        id: publicationId
                                details: {}
                                publish:
                                    args: message.args
                                    kwargs: message.kwargs
                            })

                            queue.push(event)
                        )

                        return q.all(queue)
                    ).then(()->
                        logger.info('published event to topic', message.topic)
                    ).catch((err)=>
                        logger.error('cannot publish event to topic', message.topic, err.stack)
                        @error('PUBLISH', message.request.id, err)
                    ).done()

                when 'REGISTER'
                    q.fcall(()=>
                        defer = q.defer()
                        @emit('register', message.procedure, defer)
                        defer.promise
                    ).then((registrationId)=>
                        @send('REGISTERED', {
                            register:
                                request:
                                    id: message.request.id
                            registration:
                                id: registrationId
                        })
                    ).catch((err)=>
                        logger.error('cannot register remote procedure', message.procedure, err.stack)
                        @error('REGISTER', message.request.id, err)
                    ).done()

                when 'UNREGISTER'
                    q.fcall(()=>
                        defer = q.defer()
                        @emit('unregister', message.registered.registration.id, defer)
                        defer.promise
                    ).then(()=>
                        @send('UNREGISTERED', {
                            unregister:
                                request:
                                    id: message.request.id
                        })
                    ).catch((err)=>
                        logger.error('cannot unregister remote procedure', message.registered.registration.id, err.stack)
                        @error('UNREGISTER', message.request.id, err)
                    ).done()

                when 'CALL'
                    q.fcall(()=>
                        defer = q.defer()
                        @emit('call', message.procedure, defer)
                        defer.promise
                    ).then((procedure)=>
                        invocationId = procedure.invoke(message.request.id, @)
                        procedure.callee.send('INVOCATION', {
                            request:
                                id: invocationId
                            registered:
                                registration:
                                    id: procedure.id
                            details: {}
                            call:
                                args: message.args
                                kwargs: message.kwargs
                        })
                    ).catch((err)=>
                        logger.error('cannot call remote procedure', message.procedure, err.stack)
                        @error('CALL', message.request.id, err)
                    ).done()

                when 'YIELD'
                    q.fcall(()=>
                        defer = q.defer()
                        @emit('yield', message.invocation.request.id, defer)
                        defer.promise
                    ).then((invocation)->
                        invocation.session.send('RESULT', {
                            call:
                                request:
                                    id: invocation.requestId
                            options: {}
                            yield:
                                args: message.args
                                kwargs: message.kwargs
                        })
                    ).catch((err)->
                        logger.error('cannot yield remote procedure', message.request.id, err.stack)
                    ).done()

                when 'ERROR'
                    switch parser.TYPES[message.request.type].type
                        when 'INVOCATION'
                            q.fcall(()=>
                                defer = q.defer()
                                @emit('yield', message.request.id, defer)
                                defer.promise
                            ).then((invocation)->
                                logger.error('trying to send error message for:', message)
                                invocation.session.send('ERROR', {
                                    request:
                                        type: 'CALL'
                                        id: invocation.requestId
                                    details: message.details
                                    error: message.error
                                    args: message.args
                                    kwargs: message.kwargs
                                })
                            ).catch((err)->
                                logger.error('cannot respond to invocation error!', message.request.id, err.stack)
                            ).done()

                        else
                            logger.error('error response for message type %s is not implemented yet!', message.request.type)

                else
                    logger.error('wamp.error.not_implemented')
        ).catch((err)=>
            logger.error('session parse error!', err.stack)
            @close(1011, 'wamp.error.internal_server_error')
        ).done()

module.exports = Session
