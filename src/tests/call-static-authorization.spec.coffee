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
VALID_SECRET =     Cfg.valid_secret

INVALID_AUTHID = 'david.hasselhoff'
INVALID_SECRET = 'xyz789'

describe('Router:Static Authorization CALL', ()->

    router = null
    connection = null
    # session = null

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


    it('should successfully call when call permitted - simple config', (done_func)->
        logger.debug('------------- in test method')
        done = D(done_func)

        config =
            '*':
                call: true
                register: false
                subscribe: false
                publish: false


        connect(config)
        .then((session)->
            # attempt to call a function
            #
            session.call('com.example.authtest', ['hello inge!'], {to: 'inge'})
            .then((result)->
                # no result is expected, since the session is not actually
                # registered
                #
                done()
            ).catch((err)->
                expect(err.error).to.equal('wamp.error.no_such_registration')
                done()
            ).done()
        )
    )

    it('should fail to call when call disallowed - simple config', (done_func)->
        logger.debug('------------- in test method')
        done = D(done_func)

        config =
            '*':
                call: false
                register: false
                subscribe: false
                publish: false

        connect(config)
        .then((session)->
            # attempt to call a function
            #
            session.call('com.example.authtest', ['hello inge!'], {to: 'inge'})
            .then((result)->
                # no result is expected, since the session is not actually
                # registered
                #

                done()
            ).catch((err)->
                expect(err.error).to.equal('wamp.error.not_authorized')

                done()
            ).done()
        )
    )


    it('should successfully call when call permitted - complex config', (done_func)->
        logger.debug('------------- in test method')
        done = D(done_func)

        config =
            '*':
                call: true
                register: false
                subscribe: false
                publish: false
            'com.*':
                call: true
                register: false
                subscribe: false
                publish: false
            'com.example.*':
                call: true
                register: false
                subscribe: false
                publish: false
            'com.example.auth*':
                call: true
                register: false
                subscribe: false
                publish: false


        connect(config)
        .then((session)->
            # attempt to call a function
            #
            session.call('com.example.authtest', ['hello inge!'], {to: 'inge'})
            .then((result)->
                # no result is expected, since the session is not actually
                # registered
                #
                done()
            ).catch((err)->
                expect(err.error).to.equal('wamp.error.no_such_registration')
                done()
            ).done()
        )
    )


    it('should fail to call when call disallowed - complex config', (done_func)->
        logger.debug('------------- in test method')
        done = D(done_func)

        # note that the com.example.* rule actually specifies call = false, so
        # the test should pass with a "not authorized" error
        #
        config =
            '*':
                call: true
                register: false
                subscribe: false
                publish: false
            'com.*':
                call: true
                register: false
                subscribe: false
                publish: false
            'com.example.*':
                call: false         # look at this!
                register: false
                subscribe: false
                publish: false
            'com.example.auth*':
                call: true
                register: false
                subscribe: false
                publish: false

        connect(config)
        .then((session)->
            # attempt to call a function
            #
            session.call('com.example.authtest', ['hello inge!'], {to: 'inge'})
            .then((result)->
                # no result is expected, since the session is not actually
                # registered
                #

                done()
            ).catch((err)->
                expect(err.error).to.equal('wamp.error.not_authorized')

                done()
            ).done()
        )
    )


    it('should successfully call when call permitted - non-matching items in config', (done_func)->
        logger.debug('------------- in test method')
        done = D(done_func)

        config =
            'com.*':
                call: true
                register: false
                subscribe: false
                publish: false
            'com.example.*':
                call: true
                register: false
                subscribe: false
                publish: false
            'com.something.*':
                call: false
                register: false
                subscribe: false
                publish: false


        connect(config)
        .then((session)->
            # attempt to call a function
            #
            session.call('com.example.authtest', ['hello inge!'], {to: 'inge'})
            .then((result)->
                # no result is expected, since the session is not actually
                # registered
                #
                done()
            ).catch((err)->
                expect(err.error).to.equal('wamp.error.no_such_registration')
                done()
            ).done()
        )
    )


    it('should fail to call when call disallowed - non-matching items in config', (done_func)->
        logger.debug('------------- in test method')
        done = D(done_func)

        config =
            'com.*':
                call: true
                register: false
                subscribe: false
                publish: false
            'com.example.*':
                call: false
                register: false
                subscribe: false
                publish: false
            'com.something.*':
                call: false
                register: false
                subscribe: false
                publish: false

        connect(config)
        .then((session)->
            # attempt to call a function
            #
            session.call('com.example.authtest', ['hello inge!'], {to: 'inge'})
            .then((result)->
                # no result is expected, since the session is not actually
                # registered
                #

                done()
            ).catch((err)->
                expect(err.error).to.equal('wamp.error.not_authorized')

                done()
            ).done()
        )
    )


    it('should fail to call when call disallowed - no matching rule', (done_func)->
        logger.debug('------------- in test method')
        done = D(done_func)

        config =
            'com.something.*':
                call: true
                register: false
                subscribe: false
                publish: false

        connect(config)
        .then((session)->
            # attempt to call a function
            #
            session.call('com.example.authtest', ['hello inge!'], {to: 'inge'})
            .then((result)->
                # no result is expected, since the session is not actually
                # registered
                #

                done()
            ).catch((err)->
                expect(err.error).to.equal('wamp.error.not_authorized')

                done()
            ).done()
        )
    )
)
