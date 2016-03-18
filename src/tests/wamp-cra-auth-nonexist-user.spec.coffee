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

    VALID_AUTHID = 'j.smith'
    VALID_KEY = 'abc123'

    INVALID_AUTHID = 'd.hasselhoff'
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

        setTimeout((()-> done()), 500)
    )

    after((done)->
        setTimeout(()-> router.close().then(done).catch(done).done())
    )

    it('should fail to establish a new session via static wamp-cra authentication', (done)->
        router.createRealm('com.to.inge.world')


        onchallenge = (session, method, extra)->

            expect(method).to.equal('wampcra')

            # respond to the challenge - CORRECT KEY, BUT WRONG USER!
            #
            autobahn.auth_cra.sign(VALID_KEY, extra.challenge)

        connection = new autobahn.Connection({
            realm: 'com.to.inge.world'
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
