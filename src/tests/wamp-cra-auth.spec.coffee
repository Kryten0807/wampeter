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

describe('Router:Session', ()->

    router = null
    connection = null
    session = null

    VALID_KEY = 'abc123'
    INVALID_KEY = 'xyz789'

    before((done)->
        router = wampeter.createRouter({
            port: 3000
            auth:
                wampcra:
                    type: 'static'
                    users:
                        'alpha':
                            secret: VALID_KEY
                            role: 'frontend'
        })

        setTimeout((()-> done()), 500)
    )

    # after((done)->
    #     setTimeout(()-> router.close().then(done).catch(done).done())
    # )

    after((done)->
        if connection? and connection.isOpen
            connection.close()

        setTimeout(()-> router.close().then(done).catch(done).done())
    )


    it('should establish a new session via static wamp-cra authentication', (done)->
        router.createRealm('com.to.inge.world')

        connection = new autobahn.Connection({
            realm: 'com.to.inge.world'
            url: 'ws://localhost:3000/wampeter'
            authmethods: ['wampcra']
        })


        connection.onchallenge = (session, method, extra)->
            expect(method).to.be('wampcra')

            # respond to the challenge
            #
            autobahn.auth_cra.sign(VALID_KEY, extra.challenge)

            # this is here temporarily (I think). Ideally, if WAMPCRA were
            # implemented, then the call sequence ought to be:
            #
            #       open -> onChallenge -> onOpen -> done
            #
            # But since I'm just sketching out the steps here, I want it to fail
            # at this point.
            #
            done()

        connection.onopen = (s)->
            expect(s).to.be.an.instanceof(autobahn.Session)
            expect(s.isOpen).to.be.true
            session = s
            # done()

        connection.open()
    )

    it('should fail to establish a new session via static wamp-cra authentication', (done)->
        router.createRealm('com.to.inge.world')

        connection = new autobahn.Connection({
            realm: 'com.to.inge.world'
            url: 'ws://localhost:3000/wampeter'
            authmethods: ['wampcra']
        })


        connection.onchallenge = (session, method, extra)->
            expect(method).to.be('wampcra')

            # respond to the challenge
            #
            autobahn.auth_cra.sign(INVALID_KEY, extra.challenge)


        connection.onopen = (s)->
            expect(s).to.be.an.instanceof(autobahn.Session)
            expect(s.isOpen).to.be.true
            session = s
            # done()

        connection.onerror = (err)->
            expect(err.type).to.be('wamp.error.not_not_authorized')

            done()







        connection.open()
    )

    it('should close a session', (done)->
        expect(connection).to.be.an.instanceof(autobahn.Connection)

        connection.onclose = (reason)->
            expect(reason).to.be.equal('closed')
            done()

        connection.close()
    )
)
