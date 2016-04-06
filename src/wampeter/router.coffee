CConf           = require('node-cconf')
util            = require('./util')
logger          = util.logger()
parser          = util.parser()
randomid        = util.randomid
Realm           = require('./realm')
Session         = require('./session')
WebSocketServer = require('ws').Server
q               = require('q')
inherits        = require('util').inherits
http            = require('http')
_               = require('lodash')


class Router extends WebSocketServer
    constructor: (opts)->
        # retrieve configuration and update with default values
        #
        @config = new CConf('router', [], {
            path             : '/wampeter'
            autoCreateRealms : true
            realms           : {}
        }).load(opts || {})

        # initialize the list of realms
        #
        @realms = {}

        logger.info("router option for auto-creating realms is #{if @config.getValue('autoCreateRealms') then 'set' else 'not set'}")

        # configure the HTTP server if it's not already set
        #
        @server = @config.getValue('httpServer')
        if not @server?
            @server = http.createServer((req, res)->
                res.writeHead(200)
                res.end('This is the Wampeter WAMP transport. Please connect over WebSocket!')
            )

        # set up the error handler for the HTTP server
        #
        @server.on('error', (err)->
            logger.error('httpServer error:', err.stack)
        )

        # configure the listening port
        #
        port = @config.getValue('port')
        if port?
            @server.listen(port, ()->
                logger.info("bound and listening at: #{port}")
            )

        WebSocketServer.call(@, {
            'server' : @server
            'path'   : @config.getValue('path')
        })

        @on('error', (err)->
            logger.error('webSocketServer error:', err.stack)
        )

        @on('connection', (socket)=>
            logger.info('incoming socket connection')

            session = new Session(socket, @roles, @config.getValue('auth') ? null)

            session.on('attach', (realm, defer)=>
                try
                    logger.debug("attaching session to realm #{realm}")
                    @realm(realm).addSession(session)
                    defer.resolve()
                catch err
                    defer.reject(err)
            )

            session.on('close', (defer)=>
                try
                    logger.debug("removing & cleaning session from realm #{session.realm}")
                    @realm(session.realm).cleanup(session).removeSession(session)
                    defer.resolve()
                catch err
                    defer.reject(err)
            )

            session.on('subscribe', (uri, defer)=>
                try
                    defer.resolve(@realm(session.realm).subscribe(uri, session))
                catch err
                    defer.reject(err)
            )

            session.on('unsubscribe', (id, defer)=>
                try
                    @realm(session.realm).unsubscribe(id, session)
                    defer.resolve()
                catch err
                    defer.reject(err)
            )

            session.on('publish', (uri, defer)=>
                try
                    defer.resolve(@realm(session.realm).topic(uri))
                catch err
                    defer.reject(err)
            )

            session.on('register', (uri, defer)=>
                try
                    defer.resolve(@realm(session.realm).register(uri, session))
                catch err
                    defer.reject(err)
            )

            session.on('unregister', (id, defer)=>
                try
                    @realm(session.realm).unregister(id, session)
                    defer.resolve()
                catch err
                    defer.reject(err)
            )

            session.on('call', (uri, defer)=>
                try
                    defer.resolve(@realm(session.realm).procedure(uri))
                catch err
                    defer.reject(err)
            )

            session.on('yield', (id, defer)=>
                try
                    defer.resolve(@realm(session.realm).yield(id))
                catch err
                    defer.reject(err)
            )
        )

    roles: {broker: {}, dealer: {}}

    ###
    Router.prototype.__defineGetter__('roles', function () {
        return {
            broker: {},
            dealer: {}
        };
    });
    ###

    close: ()=>
        q.fcall(()=>
            _.forOwn(@realms, (realm)->
                realm.close(1008, 'wamp.error.system_shutdown')
            )
        ).then(()=>
            @server.close()
            super
        ).timeout(500, 'wamp.error.system_shutdown_timeout')

    realm: (uri)=>
        if parser.isUri(uri)
            autoCreateRealms = @config.getValue('autoCreateRealms')

            if not @realms[uri]?
                if autoCreateRealms
                    @realms[uri] = new Realm()
                    logger.info("new realm created #{uri}")
                else
                    throw new Error('wamp.error.no_such_realm')

            @realms[uri]
        else
            throw new TypeError('wamp.error.invalid_uri')

    createRealm: (uri)=>
        if parser.isUri(uri)
            if not @realms[uri]
                @realms[uri] = new Realm()
                logger.info("new realm created #{uri}")
            else
                throw new Error('wamp.error.realm_already_exists')
        else
            throw new TypeError('wamp.error.invalid_uri')


module.exports.Router = Router


module.exports.createRouter = (opts)-> new Router(opts)
