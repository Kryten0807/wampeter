(function() {
  var Authenticator, _, crypto, logger, q, util,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  _ = require('lodash');

  util = require('./util');

  logger = util.logger();

  crypto = require('crypto-js');

  q = require('q');


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

    function Authenticator(session1, config) {
      var err, error;
      this.session = session1;
      this._wampcra_challenge = bind(this._wampcra_challenge, this);
      this.authenticate = bind(this.authenticate, this);
      logger.debug('instantiating authenticator', config);
      if (config === null) {
        this.authenticate = function() {
          return true;
        };
        return;
      }
      this.challenge = this._wampcra_challenge;
      try {
        if (config == null) {
          throw 'missing config';
        }
        if (config.wampcra == null) {
          throw 'no wampcra config';
        }
        if (config.wampcra.type === 'static') {
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
          this.generateChallenge = (function(_this) {
            return function(message) {
              var authid, challenge, ref, user;
              authid = message != null ? (ref = message.details) != null ? ref.authid : void 0 : void 0;
              if (authid != null) {
                user = _this.users[authid];
                if (user != null) {
                  user.authid = authid;
                  challenge = JSON.stringify({
                    authid: user.authid,
                    authrole: user.role,
                    authmethod: 'wampcra',
                    authprovider: 'static',
                    session: _this.session.id,
                    nonce: util.randomid(),
                    timestamp: Math.floor(Date.now() / 1000)
                  });
                  return [challenge, user];
                }
              }
              throw new Error('wamp.error.not_authorized');
            };
          })(this);
        } else if (config.wampcra.type === 'dynamic') {
          if ((config.wampcra.authenticator == null) || !_.isFunction(config.wampcra.authenticator)) {
            throw 'missing/invalid wamp-cra authenticator function';
          }
          this.generateChallenge = (function(_this) {
            return function(message) {
              var authid, challenge, credentials, details, realm, ref;
              realm = message != null ? message.realm : void 0;
              authid = message != null ? (ref = message.details) != null ? ref.authid : void 0 : void 0;
              details = message != null ? message.details : void 0;
              credentials = config.wampcra.authenticator(realm, authid, details);
              if (credentials != null) {
                credentials.authid = authid;
                challenge = JSON.stringify({
                  authid: authid,
                  authrole: credentials.role,
                  authmethod: 'wampcra',
                  authprovider: 'dynamic',
                  session: _this.session.id,
                  nonce: util.randomid(),
                  timestamp: Math.floor(Date.now() / 1000)
                });
                return [challenge, credentials];
              }
              throw new Error('wamp.error.not_authorized');
            };
          })(this);
        } else {
          throw 'unrecognized wamp-cra type';
        }
      } catch (error) {
        err = error;
        logger.error("unable to define authenticator: " + err + " - falling back to impossible authentication");
        this.authenticate = function() {
          return false;
        };
      }
    }

    Authenticator.prototype.authenticate = function(message) {
      return q.fcall((function(_this) {
        return function() {
          var ref;
          if ((message.signature != null) && message.signature === _this.signature) {
            return (ref = _this.user.role) != null ? ref : null;
          } else {
            _this.user = null;
            throw new Error('wamp.error.not_authorized');
          }
        };
      })(this));
    };

    Authenticator.prototype._wampcra_challenge = function(message) {
      var derive_key, sign;
      this.user = null;
      derive_key = function(secret, salt, iterations, keylen) {
        var config, key;
        if (salt == null) {
          return secret;
        }
        logger.debug('deriving key');
        if (iterations == null) {
          iterations = 1000;
        }
        if (keylen == null) {
          keylen = 32;
        }
        config = {
          keySize: keylen / 4,
          iterations: iterations,
          hasher: crypto.algo.SHA256
        };
        logger.debug('key config', config);
        key = crypto.PBKDF2(secret, salt, config);
        return key.toString(crypto.enc.Base64);
      };
      sign = function(key, challenge) {
        return crypto.HmacSHA256(challenge, key).toString(crypto.enc.Base64);
      };
      return q.fcall((function(_this) {
        return function() {
          var authid, challenge, extra, key, ref, ref1, ref2;
          authid = message.details.authid;
          if (authid == null) {
            throw new Error('no user provided');
          }
          ref = _this.generateChallenge(message), challenge = ref[0], _this.user = ref[1];
          extra = {
            challenge: challenge
          };
          if (_this.user.salt != null) {
            extra.salt = _this.user.salt;
            extra.iterations = (ref1 = _this.user.iterations) != null ? ref1 : 1000;
            extra.keylen = (ref2 = _this.user.keylen) != null ? ref2 : 32;
          }
          logger.debug('getting key');
          key = derive_key(_this.user.secret, _this.user.salt, _this.user.iterations, _this.user.keylen);
          logger.debug('key', key);
          _this.signature = sign(key, challenge);
          logger.debug('signature', _this.signature, _this.user);
          return {
            authmethod: 'wampcra',
            extra: extra
          };
        };
      })(this));
    };

    return Authenticator;

  })();

  module.exports = function(session, authConfig) {
    logger.debug('in authenticator factory', authConfig);
    if (authConfig === null) {
      return null;
    } else {
      return new Authenticator(session, authConfig);
    }
  };

}).call(this);
