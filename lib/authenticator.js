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
      this.getUser = bind(this.getUser, this);
      this._wampcra_authenticate = bind(this._wampcra_authenticate, this);
      this._wampcra_challenge = bind(this._wampcra_challenge, this);
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
    }

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
          var challenge, extra, key, ref, ref1, userID;
          userID = message.details.authid;
          if (userID == null) {
            throw new Error('no user provided');
          }
          _this.user = _this.users[userID];
          if (_this.user == null) {
            _this.user = null;
            throw new Error('wamp.error.not_not_authorized');
          }
          _this.user.authid = userID;
          challenge = JSON.stringify({
            authid: _this.user.authid,
            authrole: _this.user.role,
            authmethod: 'wampcra',
            authprovider: 'static',
            session: _this.session.id,
            nonce: util.randomid(),
            timestamp: Math.floor(Date.now() / 1000)
          });
          extra = {
            challenge: challenge
          };
          if (_this.user.salt != null) {
            extra.salt = _this.user.salt;
            extra.iterations = (ref = _this.user.iterations) != null ? ref : 1000;
            extra.keylen = (ref1 = _this.user.keylen) != null ? ref1 : 32;
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

    Authenticator.prototype._wampcra_authenticate = function(message) {
      return q.fcall((function(_this) {
        return function() {
          logger.debug('authenticating', message);
          logger.debug('----- auth sig', message.signature);
          logger.debug('----- auth should be', _this.signature);
          if ((message.signature != null) && message.signature === _this.signature) {
            return _this.user.authid;
          } else {
            _this.user = null;
            throw new Error('wamp.error.not_not_authorized');
          }
        };
      })(this));
    };

    Authenticator.prototype.getUser = function() {
      return this.user;
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
