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
VALID_KEY =     Cfg.valid_key

INVALID_AUTHID = 'david.hasselhoff'
INVALID_KEY = 'xyz789'


describe('Router:Static Authorization REGISTER', ()->

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
            autobahn.auth_cra.sign(VALID_KEY, extra.challenge)

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


    it('should successfully register when permitted - simple config', (done_func)->
        logger.debug('------------- in test method')
        done = D(done_func)

        config =
            '*':
                call: false
                register: true
                subscribe: false
                publish: false

        registerURI = 'com.example.authtest'

        connect(config)
        .then((session)->

            # attempt to register a function
            #
            f = (a, b)-> a+b

            session.register(registerURI, f)

        ).then((result)->
            expect(result.procedure).to.equal(registerURI)

            done()
        ).catch((err)->
            expect(err).to.equal(null)
            done()
        ).done()
    )


    it('should fail to register when disallowed - simple config', (done_func)->
        logger.debug('------------- in test method')
        done = D(done_func)

        config =
            '*':
                call: false
                register: false
                subscribe: false
                publish: false

        registerURI = 'com.example.authtest'

        connect(config)
        .then((session)->

            logger.debug('------------- connected')
            # attempt to register a function
            #
            f = (a, b)-> a+b

            session.register(registerURI, f)

        ).then((result)->
            expect(result).to.equal(null)

            done()
        ).catch((err)->
            expect(err.error).to.equal('wamp.error.not_authorized')
            done()
        ).done()
    )


    it('should successfully register when permitted - complex config', (done_func)->
        logger.debug('------------- in test method')
        done = D(done_func)

        config =
            '*':
                call: false
                register: true
                subscribe: false
                publish: false
            'com.*':
                call: false
                register: true
                subscribe: false
                publish: false
            'com.example.*':
                call: false
                register: true
                subscribe: false
                publish: false
            'com.example.auth*':
                call: false
                register: true
                subscribe: false
                publish: false

        registerURI = 'com.example.authtest'

        connect(config)
        .then((session)->

            # attempt to register a function
            #
            f = (a, b)-> a+b

            session.register(registerURI, f)

        ).then((result)->
            expect(result.procedure).to.equal(registerURI)

            done()
        ).catch((err)->
            expect(err).to.equal(null)
            done()
        ).done()
    )


    it('should fail to register when disallowed - complex config', (done_func)->
        logger.debug('------------- in test method')
        done = D(done_func)

        config =
            '*':
                call: false
                register: true
                subscribe: false
                publish: false
            'com.*':
                call: false
                register: false     # note that this is false
                subscribe: false
                publish: false
            'com.example.*':
                call: false
                register: true
                subscribe: false
                publish: false
            'com.example.auth*':
                call: false
                register: true
                subscribe: false
                publish: false

        registerURI = 'com.example.authtest'

        connect(config)
        .then((session)->

            logger.debug('------------- connected')
            # attempt to register a function
            #
            f = (a, b)-> a+b

            session.register(registerURI, f)

        ).then((result)->
            expect(result).to.equal(null)

            done()
        ).catch((err)->
            expect(err.error).to.equal('wamp.error.not_authorized')
            done()
        ).done()
    )


    it('should successfully register when permitted - non-matching items in config', (done_func)->
        logger.debug('------------- in test method')
        done = D(done_func)

        config =
            'com.*':
                call: false
                register: true
                subscribe: false
                publish: false
            'com.example.*':
                call: false
                register: true
                subscribe: false
                publish: false
            'com.something.*':
                call: false
                register: false
                subscribe: false
                publish: false

        registerURI = 'com.example.authtest'

        connect(config)
        .then((session)->

            # attempt to register a function
            #
            f = (a, b)-> a+b

            session.register(registerURI, f)

        ).then((result)->
            expect(result.procedure).to.equal(registerURI)

            done()
        ).catch((err)->
            expect(err).to.equal(null)
            done()
        ).done()
    )


    it('should fail to register when disallowed - non-matching items in config', (done_func)->
        logger.debug('------------- in test method')
        done = D(done_func)

        config =
            'com.*':
                call: false
                register: true
                subscribe: false
                publish: false
            'com.example.*':
                call: false
                register: false
                subscribe: false
                publish: false
            'com.something.*':
                call: false
                register: true
                subscribe: false
                publish: false

        registerURI = 'com.example.authtest'

        connect(config)
        .then((session)->

            logger.debug('------------- connected')
            # attempt to register a function
            #
            f = (a, b)-> a+b

            session.register(registerURI, f)

        ).then((result)->
            expect(result).to.equal(null)

            done()
        ).catch((err)->
            expect(err.error).to.equal('wamp.error.not_authorized')
            done()
        ).done()
    )


    it('should fail to register when disallowed - no matching rule', (done_func)->
        logger.debug('------------- in test method')
        done = D(done_func)

        config =
            'com.something.*':
                call: false
                register: true
                subscribe: false
                publish: false

        registerURI = 'com.example.authtest'

        connect(config)
        .then((session)->

            logger.debug('------------- connected')
            # attempt to register a function
            #
            f = (a, b)-> a+b

            session.register(registerURI, f)

        ).then((result)->
            expect(result).to.equal(null)

            done()
        ).catch((err)->
            expect(err.error).to.equal('wamp.error.not_authorized')
            done()
        ).done()
    )
)
