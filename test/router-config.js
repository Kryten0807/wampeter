(function() {
  var BASE_URI, DYNAMIC_CONFIG, PORT, REALM_URI, ROLE, ROUTER_CONFIG, STATIC_CONFIG, URL, VALID_AUTHID, VALID_KEY, _, authenticator, obj, obj1, obj2;

  _ = require('lodash');

  PORT = 3000;

  URL = "ws://localhost:" + PORT;

  BASE_URI = 'com.to.inge';

  REALM_URI = BASE_URI + '.world';

  VALID_AUTHID = 'nicolas.cage';

  VALID_KEY = 'abc123';

  ROLE = 'role_1';

  authenticator = function(realm, authid, details) {
    return {
      secret: VALID_KEY,
      role: 'frontend'
    };
  };

  ROUTER_CONFIG = {
    port: PORT,
    realms: (
      obj = {},
      obj["" + REALM_URI] = {
        roles: (
          obj1 = {},
          obj1["" + ROLE] = {},
          obj1
        )
      },
      obj
    )
  };

  STATIC_CONFIG = _.assign({}, ROUTER_CONFIG);

  DYNAMIC_CONFIG = _.assign({}, ROUTER_CONFIG);

  STATIC_CONFIG.auth = {
    wampcra: {
      type: 'static',
      users: (
        obj2 = {},
        obj2["" + VALID_AUTHID] = {
          secret: VALID_KEY,
          role: 'frontend'
        },
        obj2
      )
    }
  };

  DYNAMIC_CONFIG.auth = {
    wampcra: {
      type: 'dynamic',
      authenticator: authenticator
    }
  };

  module.exports.realm = REALM_URI;

  module.exports.valid_authid = VALID_AUTHID;

  module.exports.valid_key = VALID_KEY;

  module.exports.role = ROLE;

  module.exports["static"] = STATIC_CONFIG;

  module.exports.dynamic = DYNAMIC_CONFIG;

}).call(this);
