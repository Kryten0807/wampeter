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

ROLE_NAME = 'role_1'

ROUTER_CONFIG =
    port: PORT

    realms:
        "#{REALM_URI}":
            roles:
                "#{ROLE_NAME}": {}

    auth:
        wampcra:
            type: 'static'
            users:
                "#{VALID_AUTHID}":
                    secret: VALID_KEY
                    role: 'frontend'








###
describe('Router:Static Authorization', ()->

    router = null
    connection = null
    session = null

    before((done_func)->
        done = D(done_func)

        router = wampeter.createRouter(ROUTER_CONFIG)

        router.createRealm(REALM_URI)

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
            done()

        connection.open()
    )
)
###
