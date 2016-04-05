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

describe('Router:Static WAMP-CRA', ()->

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

        setTimeout((()-> done()), CLEANUP_DELAY)
    )

    after((done)->
        setTimeout((()-> router.close().then(done).catch(done).done()), CLEANUP_DELAY)
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
