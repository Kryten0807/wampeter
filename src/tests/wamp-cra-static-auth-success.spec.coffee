global.AUTOBAHN_DEBUG = true;

wampeter  = require('../lib/router')
CLogger  = require('node-clogger')
autobahn = require('autobahn')
chai     = require('chai')
expect   = chai.expect
promised = require('chai-as-promised')
spies    = require('chai-spies')

logger = new CLogger({name: 'router-tests'})

chai.use(spies).use(promised)

CLEANUP_DELAY = 500

describe('Router:Static WAMP-CRA Successes', ()->

    router = null
    connection = null
    session = null

    VALID_AUTHID = 'nicolas.cage'
    VALID_KEY = 'abc123'

    INVALID_AUTHID = 'david.hasselhoff'
    INVALID_KEY = 'xyz789'

    before((done)->
        router = wampeter.createRouter({
            port: 3000
            auth:
                wampcra:
                    type: 'static'
                    users:
                        "#{VALID_AUTHID}":
                            secret: VALID_KEY
                            role: 'frontend'
        })

        router.createRealm('com.to.inge.world')

        setTimeout(done, CLEANUP_DELAY)
    )

    after((done)->
        cleanup = ()-> router.close().then(done).catch(done).done()
        setTimeout(cleanup, CLEANUP_DELAY)
    )

    it('should establish a new session via static wamp-cra authentication', (done)->
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

    VALID_AUTHID = 'nicolas.cage'
    VALID_KEY = 'abc123'

    INVALID_AUTHID = 'david.hasselhoff'
    INVALID_KEY = 'xyz789'

    REALM = 'com.to.inge.world'

    before((done)->
        router = wampeter.createRouter({
            port: 3000
            auth:
                wampcra:
                    type: 'static'
                    users:
                        "#{VALID_AUTHID}":
                            secret: VALID_KEY
                            role: 'frontend'
        })

        router.createRealm(REALM)

        setTimeout((()-> done()), CLEANUP_DELAY)
    )

    after((done)->
        setTimeout((()-> router.close().then(done).catch(done).done()), CLEANUP_DELAY)
    )

    it('should fail to establish a new session - invalid key', (done)->

        onchallenge = (session, method, extra)->

            expect(method).to.equal('wampcra')

            # respond to the challenge - SIGN WITH THE INVALID KEY!
            #
            autobahn.auth_cra.sign(INVALID_KEY, extra.challenge)

        connection = new autobahn.Connection({
            realm: REALM
            url: 'ws://localhost:3000/wampeter'

            authmethods: ['wampcra']
            authid: VALID_AUTHID
            onchallenge: onchallenge
        })

        connection.onclose = (e)->
            logger.error('closing', e)
            done()

        connection.open()
    )




    it('should fail to establish a new session - invalid auth ID & secret', (done)->

        onchallenge = (session, method, extra)->

            expect(method).to.equal('wampcra')

            # respond to the challenge - SIGN WITH THE INVALID KEY!
            #
            autobahn.auth_cra.sign(INVALID_KEY, extra.challenge)

        connection = new autobahn.Connection({
            realm: REALM
            url: 'ws://localhost:3000/wampeter'

            authmethods: ['wampcra']
            # use the INVALID authid
            #
            authid: INVALID_AUTHID
            onchallenge: onchallenge
        })

        connection.onclose = (e)->
            logger.error('closing', e)
            done()

        connection.open()
    )





    it('should fail to establish a new session - invalid challenge', (done)->

        onchallenge = (session, method, extra)->

            expect(method).to.equal('wampcra')

            # respond to the challenge - SIGN THE WRONG CHALLENGE!
            #
            autobahn.auth_cra.sign(VALID_KEY, {a:1, b:2})

        connection = new autobahn.Connection({
            realm: REALM
            url: 'ws://localhost:3000/wampeter'

            authmethods: ['wampcra']
            authid: VALID_AUTHID
            onchallenge: onchallenge
        })

        connection.onclose = (e)->
            logger.error('closing', e)
            done()


        connection.open()
    )




    it('should fail to establish a new session - invalid auth ID', (done)->
        onchallenge = (session, method, extra)->

            expect(method).to.equal('wampcra')

            # respond to the challenge - CORRECT KEY, BUT WRONG USER!
            #
            autobahn.auth_cra.sign(VALID_KEY, extra.challenge)

        connection = new autobahn.Connection({
            realm: REALM
            url: 'ws://localhost:3000/wampeter'

            authmethods: ['wampcra']
            # respond to the challenge - CORRECT KEY, BUT WRONG USER!
            #
            authid: INVALID_AUTHID
            onchallenge: onchallenge
        })

        connection.onclose = (e)->
            logger.error('closing', e)
            done()

        connection.open()
    )

)
