(function() {
  var Authenticator, _, logger, util,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  _ = require('lodash');

  util = require('./util');

  logger = util.logger();


  /**
   * An authenticator for auth requests to the router
   *
   * Currently, the only authentication method supported is static WAMP-CRA.
   *
   * What's going to happen if we have invalid `authConfig`? There is no specific
   * `wamp.error.*`` code to return for an invalid router configuration, and we
   * don't want to leave the application in a state where just anyone can
   * authenticate. so, in the case of an invalid configuration, the `authenticate`
   * method will be one that always fails.
   */

  Authenticator = (function() {
    var users;

    users = {};

    function Authenticator(config) {
      this._wampcra_authenticate = bind(this._wampcra_authenticate, this);
      var err, error;
      logger.debug('instantiating authenticator', config);
      if (config === null) {
        this.authenticate = function() {
          return true;
        };
        return;
      }
      try {
        if (config == null) {
          throw 'missing config';
        }
        if (config.wampcra == null) {
          throw 'no wampcra config';
        }
        if (config.wampcra.type !== 'static') {
          throw 'non-static wampcra config';
        }
        if (config.wampcra.users == null) {
          throw 'no users defined';
        }
        this.users = config.wampcra.users;
        _.forEach(this.users, function(v, k) {
          if (!_.isPlainObject(v)) {
            throw "invalid details for user '" + k + "'";
          }
          if (v.secret == null) {
            throw "missing secret for user '" + k + "'";
          }
          if (!_.isString(v.secret)) {
            throw "invalid secret for user '" + k + "'";
          }
          if (v.role == null) {
            throw "missing role for user '" + k + "'";
          }
          if (!_.isString(v.role)) {
            throw "invalid role for user '" + k + "'";
          }
        });
        this.authenticate = this._wampcra_authenticate;
      } catch (error) {
        err = error;
        logger.error("unable to define authenticator: " + err + " - falling back to impossible authentication");
        this.authenticate = function() {
          return false;
        };
      }

      /*
      wampcra:
          type: 'static'
          users:
              'alpha':
                  secret: VALID_KEY
                  role: 'frontend'
       */
    }

    Authenticator.prototype._wampcra_authenticate = function(user, secret) {};

    return Authenticator;

  })();

  module.exports = function(config) {
    if (config === null) {
      return null;
    } else {
      return new Authenticator(config);
    }
  };

}).call(this);
