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

authenticator = (realm, authid, details)->
    expect(realm).to.be.equal(REALM_URI)

    { secret: VALID_KEY, role: 'frontend' }




ROUTER_CONFIG =
    port: PORT

    # path: '/wampeter'
    # autoCreateRealms: true
    # logger: new CLogger({name: 'nightlife-router'})

    realm: REALM_URI

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




describe('Router:Static WAMP-CRA Successes', ()->

    router = null
    connection = null
    session = null

    before((done_func)->
        done = D(done_func)

        router = wampeter.createRouter(ROUTER_CONFIG)

        setTimeout(done, CLEANUP_DELAY)
    )

    after((done_func)->
        done = D(done_func)

        cleanup = ()-> router.close().then(done).catch(done).done()
        setTimeout(cleanup, CLEANUP_DELAY)
    )

    it('should establish a new session via static wamp-cra authentication', (done_func)->
        done = D(done_func)

        onchallenge = (session, method, extra)->

            expect(method).to.equal('wampcra')

            # respond to the challenge
            #
            autobahn.auth_cra.sign(VALID_KEY, extra.challenge)

        connection = new autobahn.Connection({
            realm: 'com.to.inge.world'
            url: 'ws://localhost:3000/wampeter'

            authmethods: ['wampcra']
            authid: VALID_AUTHID
            onchallenge: onchallenge
        })


        connection.onopen = (s)->
            expect(s).to.be.an.instanceof(autobahn.Session)
            expect(s.isOpen).to.be.true
            session = s
            done()

        connection.open()
    )
)



describe('Router:Static WAMP-CRA Failures', ()->

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

    it('should fail to establish a new session - invalid key', (done_func)->
        done = D(done_func)

        onchallenge = (session, method, extra)->

            expect(method).to.equal('wampcra')

            # respond to the challenge - SIGN WITH THE INVALID KEY!
            #
            autobahn.auth_cra.sign(INVALID_KEY, extra.challenge)

        connection = new autobahn.Connection({
            realm: REALM_URI
            url: 'ws://localhost:3000/wampeter'

            authmethods: ['wampcra']
            authid: VALID_AUTHID
            onchallenge: onchallenge
        })

        connection.onclose = (reason, message)->
            console.log('------------------------ onclose', message)

            expect(message).to.have.property('reason')
            expect(message.reason).to.equal('wamp.error.not_authorized')

            done()

        connection.open()
    )




    it('should fail to establish a new session - invalid auth ID & secret', (done_func)->
        done = D(done_func)

        onchallenge = (session, method, extra)->

            expect(method).to.equal('wampcra')

            # respond to the challenge - SIGN WITH THE INVALID KEY!
            #
            autobahn.auth_cra.sign(INVALID_KEY, extra.challenge)

        connection = new autobahn.Connection({
            realm: REALM_URI
            url: 'ws://localhost:3000/wampeter'

            authmethods: ['wampcra']
            # use the INVALID authid
            #
            authid: INVALID_AUTHID
            onchallenge: onchallenge
        })

        connection.onclose = (reason, message)->
            console.log('------------------------ onclose', message)

            expect(message).to.have.property('reason')
            expect(message.reason).to.equal('wamp.error.not_authorized')

            done()

        connection.open()
    )





    it('should fail to establish a new session - invalid challenge', (done_func)->
        done = D(done_func)

        onchallenge = (session, method, extra)->

            expect(method).to.equal('wampcra')

            # respond to the challenge - SIGN THE WRONG CHALLENGE!
            #
            autobahn.auth_cra.sign(VALID_KEY, {a:1, b:2})

        connection = new autobahn.Connection({
            realm: REALM_URI
            url: 'ws://localhost:3000/wampeter'

            authmethods: ['wampcra']
            authid: VALID_AUTHID
            onchallenge: onchallenge
        })

        connection.onclose = (reason, message)->
            console.log('------------------------ onclose', message)

            expect(message).to.have.property('reason')
            expect(message.reason).to.equal('wamp.error.not_authorized')

            done()


        connection.open()
    )




    it('should fail to establish a new session - invalid auth ID', (done_func)->
        done = D(done_func)

        onchallenge = (session, method, extra)->

            expect(method).to.equal('wampcra')

            # respond to the challenge - CORRECT KEY, BUT WRONG USER!
            #
            autobahn.auth_cra.sign(VALID_KEY, extra.challenge)

        connection = new autobahn.Connection({
            realm: REALM_URI
            url: 'ws://localhost:3000/wampeter'

            authmethods: ['wampcra']
            # respond to the challenge - CORRECT KEY, BUT WRONG USER!
            #
            authid: INVALID_AUTHID
            onchallenge: onchallenge
        })

        connection.onclose = (reason, message)->
            console.log('------------------------ onclose', message)

            expect(message).to.have.property('reason')
            expect(message.reason).to.equal('wamp.error.not_authorized')

            done()

        connection.open()
    )

)
