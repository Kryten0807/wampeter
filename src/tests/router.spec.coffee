global.AUTOBAHN_DEBUG = true;

wampeter  = require('../lib/router')
CLogger  = require('node-clogger')
autobahn = require('autobahn')
chai     = require('chai')
expect   = chai.expect
promised = require('chai-as-promised')
spies    = require('chai-spies')

D = require('./done')

logger = new CLogger({name: 'router-tests'})

chai.use(spies).use(promised)

CLEANUP_DELAY = 500











PORT = 3000
URL = "ws://localhost:#{PORT}"

BASE_URI = 'com.to.inge'
REALM_URI = BASE_URI + '.world'

VALID_AUTHID = 'nicolas.cage'
VALID_KEY = 'abc123'

INVALID_AUTHID = 'david.hasselhoff'
INVALID_KEY = 'xyz789'

ROLE = 'role_1'



ROUTER_CONFIG =
    port: PORT

    # path: '/wampeter'
    autoCreateRealms: false
    # logger: new CLogger({name: 'nightlife-router'})

    realm: REALM_URI

    ###
    roles:
        "#{ROLE}": {
            # permissions go here
        }

    auth:
        wampcra:
            type: 'static'
            users:
                "#{VALID_AUTHID}":
                    secret: VALID_KEY
                    role: 'frontend'
    ###




















describe('Router#constructor', ()->

    it('should instantiate', (done_func)->
        done = D(done_func)

        router = wampeter.createRouter(ROUTER_CONFIG)

        expect(router).to.be.an.instanceof(wampeter.Router)
        expect(router.roles).to.have.property('broker')
        expect(router.roles).to.have.property('dealer')
        router.close().then(done).catch(done).done()
    )

)

describe('Router:Session', ()->

    router = null
    connection = null
    session = null

    before((done_func)->
        done = D(done_func)

        router = wampeter.createRouter(ROUTER_CONFIG)

        setTimeout((()-> done()), CLEANUP_DELAY)
    )

    after((done_func)->
        done = D(done_func)

        setTimeout((()-> router.close().then(done).catch(done).done()), CLEANUP_DELAY)
    )

    it('should establish a new session', (done_func)->
        done = D(done_func)

        router.createRealm('com.to.inge.world')

        connection = new autobahn.Connection({
            realm: 'com.to.inge.world'
            url: 'ws://localhost:3000/wampeter'
        })

        connection.onopen = (s)->
            expect(s).to.be.an.instanceof(autobahn.Session)
            expect(s.isOpen).to.be.true
            session = s
            done()

        connection.open()
    )

    it('should close a session', (done_func)->
        done = D(done_func)

        expect(connection).to.be.an.instanceof(autobahn.Connection)

        connection.onclose = (reason)->
            expect(reason).to.be.equal('closed')
            done()

        connection.close()
    )
)


describe('Router:Publish/Subscribe', ()->

    router = null
    connection = null
    session = null
    subscription = null

    before((done_func)->
        done = D(done_func)

        router = wampeter.createRouter(ROUTER_CONFIG)

        setTimeout((()->
            connection = new autobahn.Connection({
                realm: 'com.to.inge.world'
                url: 'ws://localhost:3000/wampeter'
            })

            connection.onopen = (s)->
                logger.info('router up and session connected');
                session = s
                done()

            connection.open()
        ), CLEANUP_DELAY)
    )

    after((done_func)->
        done = D(done_func)

        connection.close()

        setTimeout((()-> router.close().then(done).catch(done).done()), CLEANUP_DELAY)
    )

    onevent = (args, kwargs, details)->
        logger.info('on event')
        expect(args).to.be.ok
        expect(kwargs).to.be.ok
        expect(details).to.be.ok

    spyEvent = chai.spy(onevent)

    it('should subscribe to a topic', (done_func)->
        done = D(done_func)

        logger.info('try to subscribe')
        expect(session.isOpen).to.be.true
        session.subscribe('com.example.inge', spyEvent)
        .then((s)->
            logger.info('subscribed to topic')
            subscription = s
            done()
        ).catch((err)->
            done(new TypeError(err.stack))
        ).done()
    )

    it('should publish to a topic', (done_func)->
        done = D(done_func)

        expect(session.isOpen).to.be.true
        session.publish(
            'com.example.inge',
            ['hello inge!'],
            {to: 'inge'},
            {acknowledge: true}
        ).then((published)->
            expect(published).to.have.property('id')
        ).catch((err)->
            done(new Error(err.stack))
        ).done()

        setTimeout((()->
            expect(spyEvent).to.have.been.called.once;
            done();
        ), 500)
    )

    it('should unsubscribe from a topic', (done_func)->
        done = D(done_func)

        expect(session.isOpen).to.be.true
        session.unsubscribe(subscription).then(()->
            done()
        ).catch((err)->
            done(new Error(err.stack))
        ).done()
    )
)


describe('Router:Remote Procedures', ()->
    router = null
    connection = null
    session = null
    registration = null

    before((done_func)->
        done = D(done_func)

        router = wampeter.createRouter(ROUTER_CONFIG)

        setTimeout((()->
            connection = new autobahn.Connection({
                realm: 'com.to.inge.world'
                url: 'ws://localhost:3000/wampeter'
            })

            connection.onopen = (s)->
                session = s
                done()

            connection.open()
        ), CLEANUP_DELAY)
    )

    after((done_func)->
        done = D(done_func)

        connection.close()

        setTimeout((()-> router.close().then(done).catch(done).done()), CLEANUP_DELAY)
    )

    onCall = (args, kwargs, details)->
        expect(args).to.be.deep.equal(['hello inge!'])
        expect(kwargs).to.have.property('to')
        expect(details).to.be.ok

        if kwargs.to=='world'
            throw new autobahn.Error('com.example.inge.error', args, kwargs)
        else
            return 'inge'

    spyCall = chai.spy(onCall)

    it('should register a remote procedure', (done_func)->
        done = D(done_func)

        expect(session.isOpen).to.be.true
        session.register('com.example.inge', spyCall).then((r)->
            expect(r).to.have.property('id')
            registration = r
            done()
        ).catch((err)->
            console.log(err.stack)
        ).done()
    )

    it('should call a remote procedure', (done_func)->
        done = D(done_func)

        expect(session.isOpen).to.be.true
        session.call('com.example.inge', ['hello inge!'], {to: 'inge'})
        .then((result)->
            expect(result).to.be.equal('inge')
            expect(spyCall).to.have.been.called.once
            done()
        ).catch((err)-> done(new Error(err))).done()
    )

    it('should return an error, if remote procedure throws', (done_func)->
        done = D(done_func)

        expect(session.isOpen).to.be.true
        session.call('com.example.inge', ['hello inge!'], {to: 'world'})
        .catch((err)->
            expect(err).to.be.an.instanceof(autobahn.Error)
            expect(err.error).to.be.equal('com.example.inge.error')
            expect(err.args).to.be.deep.equal(['hello inge!'])
            expect(err.kwargs).to.have.property('to', 'world')
            expect(spyCall).to.have.been.called.twice
            done()
        )
    )

    it('should unregister a remote procedure', (done_func)->
        done = D(done_func)

        expect(session.isOpen).to.be.true
        session.unregister(registration).then(()->
            done()
        ).catch((err)-> done(new Error(err.stack))).done()
    )
)
