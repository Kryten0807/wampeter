global.AUTOBAHN_DEBUG = true;

wampeter  = require('../lib/router')
CLogger  = require('node-clogger')
autobahn = require('autobahn')
chai     = require('chai')
expect   = chai.expect
promised = require('chai-as-promised')
spies    = require('chai-spies')
Q        = require('q')

D = require('./done')

logger = new CLogger({name: 'router-tests'})

chai.use(spies).use(promised)

CLEANUP_DELAY = 500


Cfg = require('./router-config')

ROUTER_CONFIG = Cfg.static
REALM_URI =     Cfg.realm

ROLE = Cfg.role

VALID_AUTHID =  Cfg.valid_authid
VALID_SECRET =  Cfg.valid_secret

INVALID_AUTHID = 'david.hasselhoff'
INVALID_SECRET = 'xyz789'


describe('Router:Static Authorization CALL', ()->

    router = null
    connection = null

    afterEach((done_func)->
        done = D(done_func)

        cleanup = ()-> router.close().then(done).catch(done).done()
        setTimeout(cleanup, CLEANUP_DELAY)
    )

    connect = (authConfig)->
        deferred = Q.defer()

        cfg = ROUTER_CONFIG
        cfg.realms[REALM_URI].roles[ROLE] = authConfig

        router = wampeter.createRouter(cfg)

        onchallenge = (session, method, extra)->
            expect(method).to.equal('wampcra')

            # respond to the challenge
            #
            autobahn.auth_cra.sign(VALID_SECRET, extra.challenge)

        connection = new autobahn.Connection({
            realm: REALM_URI
            url: 'ws://localhost:3000/wampeter'

            authmethods: ['wampcra']
            authid: VALID_AUTHID
            onchallenge: onchallenge
        })


        connection.onopen = (session)->
            expect(session).to.be.an.instanceof(autobahn.Session)
            expect(session.isOpen).to.be.true

            setTimeout((()->deferred.resolve(session)), CLEANUP_DELAY)

        connection.open()

        deferred.promise


    it('should successfully subscribe when permitted - simple config', (done_func)->
        done = D(done_func)

        config =
            '*':
                call: false
                register: false
                subscribe: true
                publish: false

        subscribeURI = 'com.example.authtest'

        connect(config)
        .then((session)->
            # attempt to subscribe
            #
            f = (args)->

            session.subscribe(subscribeURI, f)
        ).then((result)->
            expect(result.topic).to.equal(subscribeURI)
            done()
        ).catch((err)->
            expect(err.error).to.equal(null)
            done()
        ).done()
    )


    it('should fail to subscribe when disallowed - simple config', (done_func)->
        done = D(done_func)

        config =
            '*':
                call: false
                register: false
                subscribe: false
                publish: false

        subscribeURI = 'com.example.authtest'

        connect(config)
        .then((session)->
            # attempt to subscribe
            #
            f = (args)->

            session.subscribe(subscribeURI, f)
        ).then((result)->
            logger.debug('--------------- result', result)
            expect(result).to.equal(null)
            done()
        ).catch((err)->
            expect(err.error).to.equal('wamp.error.not_authorized')
            done()
        ).done()
    )


    it('should successfully subscribe when permitted - complex config', (done_func)->
        done = D(done_func)

        config =
            '*':
                call: false
                register: false
                subscribe: true
                publish: false
            'com.*':
                call: false
                register: false
                subscribe: true
                publish: false
            'com.example.*':
                call: false
                register: false
                subscribe: true
                publish: false
            'com.example.auth*':
                call: false
                register: false
                subscribe: true
                publish: false

        subscribeURI = 'com.example.authtest'

        connect(config)
        .then((session)->
            # attempt to subscribe
            #
            f = (args)->

            session.subscribe(subscribeURI, f)
        ).then((result)->
            expect(result.topic).to.equal(subscribeURI)
            done()
        ).catch((err)->
            expect(err.error).to.equal(null)
            done()
        ).done()
    )


    it('should fail to subscribe when disallowed - complex config', (done_func)->
        done = D(done_func)

        config =
            '*':
                call: false
                register: false
                subscribe: true
                publish: false
            'com.*':
                call: false
                register: false
                subscribe: true
                publish: false
            'com.example.*':
                call: false
                register: false
                subscribe: true
                publish: false
            'com.example.auth*':
                call: false
                register: false
                subscribe: false    # note that this is false
                publish: false

        subscribeURI = 'com.example.authtest'

        connect(config)
        .then((session)->
            # attempt to subscribe
            #
            f = (args)->

            session.subscribe(subscribeURI, f)
        ).then((result)->
            logger.debug('--------------- result', result)
            expect(result).to.equal(null)
            done()
        ).catch((err)->
            expect(err.error).to.equal('wamp.error.not_authorized')
            done()
        ).done()
    )


    it('should successfully subscribe when permitted - non-matching items in config', (done_func)->
        done = D(done_func)

        config =
            'com.*':
                call: false
                register: false
                subscribe: true
                publish: false
            'com.example.*':
                call: false
                register: false
                subscribe: true
                publish: false
            'com.something.*':
                call: false
                register: false
                subscribe: false
                publish: false

        subscribeURI = 'com.example.authtest'

        connect(config)
        .then((session)->
            # attempt to subscribe
            #
            f = (args)->

            session.subscribe(subscribeURI, f)
        ).then((result)->
            expect(result.topic).to.equal(subscribeURI)
            done()
        ).catch((err)->
            expect(err.error).to.equal(null)
            done()
        ).done()
    )


    it('should fail to subscribe when disallowed - non-matching items in config', (done_func)->
        done = D(done_func)

        config =
            'com.*':
                call: false
                register: false
                subscribe: true
                publish: false
            'com.example.*':
                call: false
                register: false
                subscribe: false
                publish: false
            'com.something.*':
                call: false
                register: false
                subscribe: true
                publish: false

        subscribeURI = 'com.example.authtest'

        connect(config)
        .then((session)->
            # attempt to subscribe
            #
            f = (args)->

            session.subscribe(subscribeURI, f)
        ).then((result)->
            logger.debug('--------------- result', result)
            expect(result).to.equal(null)
            done()
        ).catch((err)->
            expect(err.error).to.equal('wamp.error.not_authorized')
            done()
        ).done()
    )


    it('should fail to subscribe when disallowed - no matching rule', (done_func)->
        done = D(done_func)

        config =
            'com.something.*':
                call: false
                register: false
                subscribe: true
                publish: false

        subscribeURI = 'com.example.authtest'

        connect(config)
        .then((session)->
            # attempt to subscribe
            #
            f = (args)->

            session.subscribe(subscribeURI, f)
        ).then((result)->
            logger.debug('--------------- result', result)
            expect(result).to.equal(null)
            done()
        ).catch((err)->
            expect(err.error).to.equal('wamp.error.not_authorized')
            done()
        ).done()
    )
)
