_ = require('lodash')

PORT = 3000
URL = "ws://localhost:#{PORT}"

BASE_URI = 'com.to.inge'
REALM_URI = BASE_URI + '.world'

VALID_AUTHID = 'nicolas.cage'
VALID_KEY = 'abc123'

ROLE = 'role_1'

authenticator = (realm, authid, details)-> { secret: VALID_KEY, role: 'frontend' }



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
                }



STATIC_CONFIG = _.assign({}, ROUTER_CONFIG)
DYNAMIC_CONFIG = _.assign({}, ROUTER_CONFIG)

STATIC_CONFIG.auth =
    wampcra:
        type: 'static'
        users:
            "#{VALID_AUTHID}":
                secret: VALID_KEY
                role: 'frontend'


DYNAMIC_CONFIG.auth =
    wampcra:
        type: 'dynamic'
        authenticator: authenticator







module.exports.realm =        REALM_URI
module.exports.valid_authid = VALID_AUTHID
module.exports.valid_key =    VALID_KEY
module.exports.role =         ROLE

module.exports.static =  STATIC_CONFIG
module.exports.dynamic = DYNAMIC_CONFIG
