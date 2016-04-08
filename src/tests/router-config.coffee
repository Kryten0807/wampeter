_ = require('lodash')

PORT = 3000
URL = "ws://localhost:#{PORT}"

BASE_URI = 'com.to.inge'
REALM_URI = BASE_URI + '.world'

VALID_AUTHID = 'nicolas.cage'
VALID_SECRET = 'abc123'

ROLE = 'role_1'

authenticator = (realm, authid, details)-> { secret: VALID_SECRET, role: ROLE }



ROUTER_CONFIG =
    port: PORT

    # path: '/wampeter'
    # autoCreateRealms: true
    # logger: new CLogger({name: 'nightlife-router'})


    realms:
        "#{REALM_URI}":
            roles:
                "#{ROLE}": {
                    # permissions go here
                    call: false
                    register: false
                    subscribe: true
                    publish: false
                }



STATIC_CONFIG = _.assign({}, ROUTER_CONFIG)
DYNAMIC_CONFIG = _.assign({}, ROUTER_CONFIG)

STATIC_CONFIG.auth =
    wampcra:
        type: 'static'
        users:
            "#{VALID_AUTHID}":
                secret: VALID_SECRET
                role: ROLE


DYNAMIC_CONFIG.auth =
    wampcra:
        type: 'dynamic'
        authenticator: authenticator







module.exports.realm =        REALM_URI
module.exports.valid_authid = VALID_AUTHID
module.exports.valid_secret = VALID_SECRET
module.exports.role =         ROLE

module.exports.static =  STATIC_CONFIG
module.exports.dynamic = DYNAMIC_CONFIG
