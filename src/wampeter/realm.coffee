util     = require('./util')
logger   = util.logger()
parser   = util.parser()
randomid = util.randomid
Session  = require('./session')
q        = require('q')
_        = require('lodash')


class Realm
    constructor: ()->
        @sessions = []
        @topics = {}
        @procedures = {}


    close: (code, reason, wasClean)=>
        q.fcall(()=>
            promises = []

            _.forEach(@sessions, (session)->
                promises.push(session.close(code, reason, true))
            )

            promises
        ).then(q.all)

    session: (session)=>
        if session? and (session instanceof Session)
            _.find(@sessions, (s)-> s==session)
        else
            throw new Error('wamp.error.invalid_argument')

    addSession: (session)=>
        if not @session(session)?
            @sessions.push(session)
        else
            throw new Error('wamp.error.session_already_exists')

    cleanup: (session)=>
        _.forEach(@procedures, (procedure)=> @unregister(procedure.id, session))

        _.forEach(@topics, (topic, key)->
            topic.removeSession(session)
            if topic.sessions.length==0
                delete @topics[key]
        )

        return @

    removeSession: (session)=>
        if @session(session)
            @sessions = _.filter(@sessions, (s)-> s!=session)
        else
            throw new Error('wamp.error.no_such_session')

    subscribe: (uri, session)=>
        if parser.isUri(uri) and @session(session)?
            if not @topics[uri]?
                @topics[uri] = new Topic()

            @topics[uri].addSession(session)

            @topics[uri].id
        else
            throw new TypeError('wamp.error.invalid_argument')

    unsubscribe: (id, session)=>
        if _.isNumber(id) and @session(session)?

            key = null

            topic = _.find(@topics, (t, k)->
                if t.id==id
                    key = k
                    true
            )

            if topic?
                topic.removeSession(session)
                if topic.sessions.length==0
                    delete @topics[key]
            else
                throw new TypeError('wamp.error.no_such_topic')

    topic: (uri)=>
        if parser.isUri(uri)
            if @topics[uri]?
                @topics[uri]
            else
                throw new Error('wamp.error.no_such_subscription')
        else
            throw new TypeError('wamp.error.invalid_uri')

    procedure: (uri)=>
        if parser.isUri(uri)
            if @procedures[uri]?
                @procedures[uri]
            else
                throw new Error('wamp.error.no_such_registration')
        else
            throw new TypeError('wamp.error.invalid_uri')

    register: (uri, callee)=>
        if parser.isUri(uri) and @session(callee)
            if not @procedures[uri]?
                procedure = new Procedure(callee)
                @procedures[uri] = procedure
                procedure.id
            else
                throw new Error('wamp.error.procedure_already_exists')
        else
            throw new TypeError('wamp.error.invalid_argument')

    unregister: (id, callee)=>
        if _.isNumber(id) and @session(callee)
            uri = _.findKey(@procedures, (p)-> p.id==id and p.callee==callee)

            if uri?
                delete @procedures[uri]
            else
                throw new Error('wamp.error.no_such_registration')
        else
            throw new TypeError('wamp.error.invalid_argument')

    invoke: (uri, session, requestId)=>
        if parser.isUri(uri) and @session(session)? and _.isNumber(requestId)
            procedure = @procedures[uri]

            if procedure? and (procedure instanceof Procedure)
                procedure.invoke(session, requestId)
            else
                throw new Error('wamp.error.no_such_procedure')
        else
            throw new TypeError('wamp.error.invalid_argument')

    yield: (id)=>
        if _.isNumber(id)
            _.find(@procedures, (procedure)-> procedure.caller[id]).yield(id)
        else
            throw new TypeError('wamp.error.invalid_argument')

    module.exports = Realm


class Topic
    constructor: ()->
        @id = randomid()
        @sessions = []

    addSession: (session)=>
        if session? and (session instanceof Session)
            if _.indexOf(@sessions, session)==-1
                @sessions.push(session)
            else
                throw new Error('wamp.error.topic_already_subscribed')
        else
            throw new TypeError('wamp.error.invalid_arguments')

    removeSession: (session)=>
        if session? and (session instanceof Session)
            @sessions = _.filter(@sessions, (s)-> s!=session)
        else
            throw new TypeError('wamp.error.invalid_argument')


class Procedure
    constructor: (callee)->
        if callee? and (callee instanceof Session)
            @callee = callee
        else
            throw new TypeError('wamp.error.invalid_argument')

        @id = randomid()
        @caller = {}

    invoke: (requestId, session)=>
        if session? and (session instanceof Session) and (@callee instanceof Session)
            id = randomid()
            @caller[id] = {requestId: requestId, session: session}
            id
        else
            throw new TypeError('wamp.error.invalid_argument')

    yield: (id)=>
        if _.isNumber(id)
            invocation = @caller[id]
            delete @caller[id]
            invocation
        else
            throw new TypeError('wamp.error.invalid_argument')
