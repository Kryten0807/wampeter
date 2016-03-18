(function() {
  var CConf, Realm, Router, Session, WebSocketServer, _, http, inherits, logger, parser, q, randomid, util,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  CConf = require('node-cconf');

  util = require('./util');

  logger = util.logger();

  parser = util.parser();

  randomid = util.randomid;

  Realm = require('./realm');

  Session = require('./session');

  WebSocketServer = require('ws').Server;

  q = require('q');

  inherits = require('util').inherits;

  http = require('http');

  _ = require('lodash');

  Router = (function(superClass) {
    extend(Router, superClass);

    function Router(opts) {
      this.createRealm = bind(this.createRealm, this);
      this.realm = bind(this.realm, this);
      this.close = bind(this.close, this);
      var port;
      this.config = new CConf('router', [], {
        'path': '/wampeter',
        'autoCreateRealms': true
      }).load(opts || {});
      this.realms = {};
      logger.info("router option for auto-creating realms is " + (this.config.getValue('autoCreateRealms') ? 'set' : 'not set'));
      this.server = this.config.getValue('httpServer');
      if (this.server == null) {
        this.server = http.createServer(function(req, res) {
          res.writeHead(200);
          return res.end('This is the Wampeter WAMP transport. Please connect over WebSocket!');
        });
      }
      this.server.on('error', function(err) {
        return logger.error('httpServer error:', err.stack);
      });
      port = this.config.getValue('port');
      if (port != null) {
        this.server.listen(port, function() {
          return logger.info("bound and listening at: " + port);
        });
      }
      WebSocketServer.call(this, {
        'server': this.server,
        'path': this.config.getValue('path')
      });
      this.on('error', function(err) {
        return logger.error('webSocketServer error:', err.stack);
      });
      this.on('connection', (function(_this) {
        return function(socket) {
          var a, ref, session;
          logger.info('incoming socket connection');
          a = _this.config.getValue('auth');
          logger.debug('incoming connection - check auth config', a);
          session = new Session(socket, _this.roles, (ref = _this.config.getValue('auth')) != null ? ref : null);
          session.on('attach', function(realm, defer) {
            var err, error;
            try {
              logger.debug("attaching session to realm " + realm);
              _this.realm(realm).addSession(session);
              return defer.resolve();
            } catch (error) {
              err = error;
              return defer.reject(err);
            }
          });
          session.on('close', function(defer) {
            var err, error;
            try {
              logger.debug("removing & cleaning session from realm " + session.realm);
              _this.realm(session.realm).cleanup(session).removeSession(session);
              return defer.resolve();
            } catch (error) {
              err = error;
              return defer.reject(err);
            }
          });
          session.on('subscribe', function(uri, defer) {
            var err, error;
            try {
              return defer.resolve(_this.realm(session.realm).subscribe(uri, session));
            } catch (error) {
              err = error;
              return defer.reject(err);
            }
          });
          session.on('unsubscribe', function(id, defer) {
            var err, error;
            try {
              _this.realm(session.realm).unsubscribe(id, session);
              return defer.resolve();
            } catch (error) {
              err = error;
              return defer.reject(err);
            }
          });
          session.on('publish', function(uri, defer) {
            var err, error;
            try {
              return defer.resolve(_this.realm(session.realm).topic(uri));
            } catch (error) {
              err = error;
              return defer.reject(err);
            }
          });
          session.on('register', function(uri, defer) {
            var err, error;
            try {
              return defer.resolve(_this.realm(session.realm).register(uri, session));
            } catch (error) {
              err = error;
              return defer.reject(err);
            }
          });
          session.on('unregister', function(id, defer) {
            var err, error;
            try {
              _this.realm(session.realm).unregister(id, session);
              return defer.resolve();
            } catch (error) {
              err = error;
              return defer.reject(err);
            }
          });
          session.on('call', function(uri, defer) {
            var err, error;
            try {
              return defer.resolve(_this.realm(session.realm).procedure(uri));
            } catch (error) {
              err = error;
              return defer.reject(err);
            }
          });
          return session.on('yield', function(id, defer) {
            var err, error;
            try {
              return defer.resolve(_this.realm(session.realm)["yield"](id));
            } catch (error) {
              err = error;
              return defer.reject(err);
            }
          });
        };
      })(this));
    }

    Router.prototype.roles = {
      broker: {},
      dealer: {}
    };


    /*
    Router.prototype.__defineGetter__('roles', function () {
        return {
            broker: {},
            dealer: {}
        };
    });
     */

    Router.prototype.close = function() {
      return q.fcall((function(_this) {
        return function() {
          return _.forOwn(_this.realms, function(realm) {
            return realm.close(1008, 'wamp.error.system_shutdown');
          });
        };
      })(this)).then((function(_this) {
        return function() {
          _this.server.close();
          return Router.__super__.close.apply(_this, arguments);
        };
      })(this)).timeout(500, 'wamp.error.system_shutdown_timeout');
    };

    Router.prototype.realm = function(uri) {
      var autoCreateRealms;
      logger.debug('router.realm', uri);
      if (parser.isUri(uri)) {
        autoCreateRealms = this.config.getValue('autoCreateRealms');
        if (this.realms[uri] == null) {
          if (autoCreateRealms) {
            this.realms[uri] = new Realm();
            logger.info("new realm created " + uri);
          } else {
            throw new Error('wamp.error.no_such_realm');
          }
        }
        return this.realms[uri];
      } else {
        throw new TypeError('wamp.error.invalid_uri');
      }
    };

    Router.prototype.createRealm = function(uri) {
      if (parser.isUri(uri)) {
        if (!this.realms[uri]) {
          this.realms[uri] = new Realm();
          return logger.info("new realm created " + uri);
        } else {
          throw new Error('wamp.error.realm_already_exists');
        }
      } else {
        throw new TypeError('wamp.error.invalid_uri');
      }
    };

    return Router;

  })(WebSocketServer);

  module.exports.Router = Router;

  module.exports.createRouter = function(opts) {
    return new Router(opts);
  };

}).call(this);
