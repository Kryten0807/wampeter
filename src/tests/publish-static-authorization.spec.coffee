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














describe('Router:Static Authorization PUBLISH', ()->

    router = null
    connection = null
    # session = null

    ###
    before((done_func)->
        done = D(done_func)

        router = wampeter.createRouter(ROUTER_CONFIG)

        router.createRealm(REALM_URI)

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


        connection.onopen = (s)->
            expect(s).to.be.an.instanceof(autobahn.Session)
            expect(s.isOpen).to.be.true
            session = s
            setTimeout(done, CLEANUP_DELAY)

        connection.open()
    )
    ###

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







    it('should successfully publish when permitted - simple config', (done_func)->
        done = D(done_func)

        config =
            '*':
                call: false
                register: false
                subscribe: false
                publish: true

        publishURI = 'com.example.authtest'

        connect(config)
        .then((session)->
            # attempt to subscribe
            #
            session.publish(publishURI, [])
        ).then((result)->
            expect(result).to.be.undefined
            done()
        ).catch((err)->
            expect(err.error).to.equal(null)
            done()
        ).done()
    )



    it('should fail to publish when disallowed (no acknowledgement) - simple config', (done_func)->
        done = D(done_func)

        config =
            '*':
                call: false
                register: false
                subscribe: false
                publish: false

        publishURI = 'com.example.authtest'

        connect(config)
        .then((session)->
            # attempt to subscribe
            #
            session.publish(publishURI, [])
        ).then((result)->
            expect(result).to.equal(null)
            done()
        ).catch((err)->
            # note that, for this test, the "acknowlege" flag is false, so there
            # will be no response
            #
            expect(err.error).to.be.undefined
            done()
        ).done()
    )

    it('should fail to publish when disallowed (with acknowledgement) - simple config', (done_func)->
        done = D(done_func)

        config =
            '*':
                call: false
                register: false
                subscribe: false
                publish: false

        publishURI = 'com.example.authtest'

        connect(config)
        .then((session)->
            # attempt to subscribe
            #
            session.publish(publishURI, [], {}, {acknowledge: true})
        ).then((result)->
            expect(result).to.equal(null)
            done()
        ).catch((err)->
            # note that, for this test, the "acknowlege" flag is false, so there
            # will be no response
            #
            expect(err.error).to.equal('wamp.error.not_authorized')
            done()
        ).done()
    )










    it('should successfully publish when permitted - complex config', (done_func)->
        done = D(done_func)

        config =
            '*':
                call: false
                register: false
                subscribe: false
                publish: true
            'com.*':
                call: false
                register: false
                subscribe: false
                publish: true
            'com.example.*':
                call: false
                register: false
                subscribe: false
                publish: true
            'com.example.auth*':
                call: false
                register: false
                subscribe: false
                publish: true

        publishURI = 'com.example.authtest'

        connect(config)
        .then((session)->
            # attempt to subscribe
            #
            session.publish(publishURI, [])
        ).then((result)->
            expect(result).to.be.undefined
            done()
        ).catch((err)->
            expect(err.error).to.equal(null)
            done()
        ).done()
    )


    it('should fail to publish when disallowed (no acknowledgement) - complex config', (done_func)->
        done = D(done_func)

        config =
            '*':
                call: false
                register: false
                subscribe: false
                publish: true
            'com.*':
                call: false
                register: false
                subscribe: false
                publish: true
            'com.example.*':
                call: false
                register: false
                subscribe: false
                publish: false       # note that this is false
            'com.example.auth*':
                call: false
                register: false
                subscribe: false
                publish: true

        publishURI = 'com.example.authtest'

        connect(config)
        .then((session)->
            # attempt to subscribe
            #
            session.publish(publishURI, [])
        ).then((result)->
            expect(result).to.equal(null)
            done()
        ).catch((err)->
            # note that, for this test, the "acknowlege" flag is false, so there
            # will be no response
            #
            expect(err.error).to.be.undefined
            done()
        ).done()
    )

    it('should fail to publish when disallowed (with acknowledgement) - complex config', (done_func)->
        done = D(done_func)

        config =
            '*':
                call: false
                register: false
                subscribe: false
                publish: true
            'com.*':
                call: false
                register: false
                subscribe: false
                publish: true
            'com.example.*':
                call: false
                register: false
                subscribe: false
                publish: false       # note that this is false
            'com.example.auth*':
                call: false
                register: false
                subscribe: false
                publish: true

        publishURI = 'com.example.authtest'

        connect(config)
        .then((session)->
            # attempt to subscribe
            #
            session.publish(publishURI, [], {}, {acknowledge: true})
        ).then((result)->
            expect(result).to.equal(null)
            done()
        ).catch((err)->
            # note that, for this test, the "acknowlege" flag is false, so there
            # will be no response
            #
            expect(err.error).to.equal('wamp.error.not_authorized')
            done()
        ).done()
    )






    it('should successfully publish when permitted - non-matching items in config', (done_func)->
        done = D(done_func)

        config =
            'com.*':
                call: false
                register: false
                subscribe: false
                publish: false
            'com.example.*':
                call: false
                register: false
                subscribe: false
                publish: true
            'com.something.*':
                call: false
                register: false
                subscribe: false
                publish: false

        publishURI = 'com.example.authtest'

        connect(config)
        .then((session)->
            # attempt to subscribe
            #
            session.publish(publishURI, [])
        ).then((result)->
            expect(result).to.be.undefined
            done()
        ).catch((err)->
            expect(err.error).to.equal(null)
            done()
        ).done()
    )


    it('should fail to publish when disallowed (no acknowledgement) - non-matching items in config', (done_func)->
        done = D(done_func)

        config =
            'com.*':
                call: false
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
                publish: true

        publishURI = 'com.example.authtest'

        connect(config)
        .then((session)->
            # attempt to subscribe
            #
            session.publish(publishURI, [])
        ).then((result)->
            expect(result).to.equal(null)
            done()
        ).catch((err)->
            # note that, for this test, the "acknowlege" flag is false, so there
            # will be no response
            #
            expect(err.error).to.be.undefined
            done()
        ).done()
    )

    it('should fail to publish when disallowed (with acknowledgement) - non-matching items in config', (done_func)->
        done = D(done_func)

        config =
            'com.*':
                call: false
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
                publish: true

        publishURI = 'com.example.authtest'

        connect(config)
        .then((session)->
            # attempt to subscribe
            #
            session.publish(publishURI, [], {}, {acknowledge: true})
        ).then((result)->
            expect(result).to.equal(null)
            done()
        ).catch((err)->
            # note that, for this test, the "acknowlege" flag is false, so there
            # will be no response
            #
            expect(err.error).to.equal('wamp.error.not_authorized')
            done()
        ).done()
    )






    it('should fail to publish when disallowed (no acknowledgement) - no matching rule', (done_func)->
        done = D(done_func)

        config =
            'com.something.*':
                call: false
                register: false
                subscribe: false
                publish: true

        publishURI = 'com.example.authtest'

        connect(config)
        .then((session)->
            # attempt to subscribe
            #
            session.publish(publishURI, [])
        ).then((result)->
            expect(result).to.equal(null)
            done()
        ).catch((err)->
            # note that, for this test, the "acknowlege" flag is false, so there
            # will be no response
            #
            expect(err.error).to.be.undefined
            done()
        ).done()
    )

    it('should fail to publish when disallowed (with acknowledgement) - no matching rule', (done_func)->
        done = D(done_func)

        config =
            'com.something.*':
                call: false
                register: false
                subscribe: false
                publish: true

        publishURI = 'com.example.authtest'

        connect(config)
        .then((session)->
            # attempt to subscribe
            #
            session.publish(publishURI, [], {}, {acknowledge: true})
        ).then((result)->
            expect(result).to.equal(null)
            done()
        ).catch((err)->
            # note that, for this test, the "acknowlege" flag is false, so there
            # will be no response
            #
            expect(err.error).to.equal('wamp.error.not_authorized')
            done()
        ).done()
    )
)
