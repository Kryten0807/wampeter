(function() {
  var Authenticator, EventEmitter, Session, WebSocket, _, inherits, logger, parser, q, randomid, util,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  util = require('./util');

  logger = util.logger();

  parser = util.parser();

  randomid = util.randomid;

  inherits = require('util').inherits;

  EventEmitter = require('events').EventEmitter;

  WebSocket = require('ws');

  q = require('q');

  _ = require('lodash');

  Authenticator = require('./authenticator');

  Session = (function(superClass) {
    extend(Session, superClass);

    function Session(socket, supportedRoles, authenticationConfig, realms) {
      if (authenticationConfig == null) {
        authenticationConfig = null;
      }
      if (realms == null) {
        realms = null;
      }
      this.parse = bind(this.parse, this);
      this.close = bind(this.close, this);
      this.error = bind(this.error, this);
      this.send = bind(this.send, this);
      this.isAuthorized = bind(this.isAuthorized, this);
      if (!(socket instanceof WebSocket)) {
        throw new TypeError('wamp.error.invalid_socket');
      }
      if (!(_.isPlainObject(supportedRoles))) {
        throw new TypeError('wamp.error.invalid_roles');
      }
      this.realms = realms;
      this.authenticator = Authenticator(this, authenticationConfig);
      EventEmitter.call(this);
      socket.on('open', function() {
        return logger.debug('socket open');
      });
      socket.on('message', (function(_this) {
        return function(data) {
          logger.debug('socket message', data);
          return _this.parse(data);
        };
      })(this));
      socket.on('error', (function(_this) {
        return function(err) {
          logger.error('socket error', err.stack);
          return _this.close(null, null, false);
        };
      })(this));
      socket.on('close', (function(_this) {
        return function(code, reason) {
          logger.debug('socket close', code, reason != null ? reason : '');
          return _this.close(code, reason, code === 1000);
        };
      })(this));
      this.socket = socket;
      this.roles = supportedRoles;
      this.clientRole = null;
    }

    Session.prototype.isWildcardMatch = function(pattern, string) {
      var newPattern, regex;
      newPattern = pattern.replace('.', '\.');
      regex = new RegExp("^" + (newPattern.split('*').join('.*')) + "$");
      logger.debug("---- regex conversion " + pattern, regex);
      return regex.test(string);
    };

    Session.prototype.isAuthorized = function(uri) {
      var details, matches, ref, roles;
      if (this.authenticator == null) {
        return true;
      }
      roles = (ref = this.realms[this.realm]) != null ? ref.roles : void 0;
      details = roles != null ? roles[this.clientRole] : void 0;
      if (details == null) {
        throw new TypeError('wamp.error.no_such_role');
      }
      matches = [];
      _.forEach(details, (function(_this) {
        return function(value, pattern) {
          var ref1;
          if (_this.isWildcardMatch(pattern, uri)) {
            logger.debug("---- pattern match found", value);
            return matches.push((ref1 = value.call) != null ? ref1 : false);
          }
        };
      })(this));
      return _.reduce(matches, (function(result, m) {
        return result && m;
      }), true);
    };

    Session.prototype.send = function(type, opts) {
      return parser.encode(type, opts).then((function(_this) {
        return function(message) {
          logger.debug('trying to send message', message);
          return WebSocket.prototype.send.call(_this.socket, message, function() {
            return logger.debug('%s message sent', type, message);
          });
        };
      })(this))["catch"](function(err) {
        return logger.error('cannot send %s message!', type, opts, err.stack);
      }).done();
    };

    Session.prototype.error = function(type, id, err) {
      if (_.isString(type) && _.isNumber(id) && (err instanceof Error)) {
        return this.send('ERROR', {
          request: {
            type: type,
            id: id
          },
          details: {
            stack: err.stack
          },
          error: err.message,
          args: [],
          kwargs: {}
        });
      } else {
        throw new TypeError('wamp.error.invalid_argument');
      }
    };

    Session.prototype.close = function(code, reason, wasClean) {
      var defer;
      if (code > 1006) {
        this.send('GOODBYE', {
          details: {
            message: 'Close connection'
          },
          reason: reason
        });
      }
      defer = q.defer();
      this.emit('close', defer);
      return defer.promise;
    };

    Session.prototype.parse = function(data) {
      return parser.decode(data).then((function(_this) {
        return function(message) {
          var ref;
          logger.debug('parsing message', message);
          switch (message.type) {
            case 'HELLO':
              _this.id = randomid();
              return q.fcall(function() {
                var defer;
                _this.realm = message.realm;
                defer = q.defer();
                _this.emit('attach', message.realm, defer);
                return defer.promise;
              }).then(function() {
                if (_this.authenticator == null) {
                  return _this.send('WELCOME', {
                    session: {
                      id: _this.id
                    },
                    details: {
                      roles: _this.roles
                    }
                  });
                } else {
                  return _this.authenticator.challenge(message).then(function(challengeMessage) {
                    logger.debug("------------------ challenge message", challengeMessage);
                    return _this.send('CHALLENGE', challengeMessage);
                  })["catch"](function(err) {
                    logger.error('cannot send CHALLENGE message', err);
                    return _this.send('ABORT', {
                      details: {
                        message: 'Cannot establish session!'
                      },
                      reason: err.message
                    });
                  }).done();
                }
              })["catch"](function(err) {
                logger.error('cannot establish session', err.stack);
                return _this.send('ABORT', {
                  details: {
                    message: 'Cannot establish session!'
                  },
                  reason: err.message
                });
              }).done();
            case 'AUTHENTICATE':
              return (ref = _this.authenticator) != null ? ref.authenticate(message).then(function(clientRole) {
                _this.clientRole = clientRole;
                return _this.send('WELCOME', {
                  session: {
                    id: _this.id
                  },
                  details: {
                    roles: _this.roles
                  }
                });
              })["catch"](function(err) {
                logger.error('cannot authenticate', err);
                return _this.send('ABORT', {
                  details: {
                    message: 'Cannot authenticate'
                  },
                  reason: err.message
                });
              }).done() : void 0;
            case 'GOODBYE':
              return _this.close(1009, 'wamp.error.close_normal');
            case 'SUBSCRIBE':
              return q.fcall(function() {
                var defer;
                logger.debug('try to subscribe to topic:', message.topic);
                defer = q.defer();
                _this.emit('subscribe', message.topic, defer);
                return defer.promise;
              }).then(function(subscriptionId) {
                return _this.send('SUBSCRIBED', {
                  subscribe: {
                    request: {
                      id: message.request.id
                    }
                  },
                  subscription: {
                    id: subscriptionId
                  }
                });
              })["catch"](function(err) {
                logger.error('cannot subscribe to topic', _this.realm, message.topic, err.stack);
                return _this.error('SUBSCRIBE', message.request.id, err);
              }).done();
            case 'UNSUBSCRIBE':
              return q.fcall(function() {
                var defer;
                defer = q.defer();
                _this.emit('unsubscribe', message.subscribed.subscription.id, defer);
                return defer.promise;
              }).then(function() {
                return _this.send('UNSUBSCRIBED', {
                  unsubscribe: {
                    request: {
                      id: message.request.id
                    }
                  }
                });
              })["catch"](function(err) {
                logger.error('cannot unsubscribe from topic', message.subscribed.subscription.id, err.stack);
                return _this.error('UNSUBSCRIBE', message.request.id, err);
              }).done();
            case 'PUBLISH':
              return q.fcall(function() {
                var defer;
                defer = q.defer();
                _this.emit('publish', message.topic, defer);
                return defer.promise;
              }).then(function(topic) {
                var publicationId, queue;
                publicationId = randomid();
                if (message.options && message.options.acknowledge) {
                  _this.send('PUBLISHED', {
                    publish: {
                      request: {
                        id: message.request.id
                      }
                    },
                    publication: {
                      id: publicationId
                    }
                  });
                }
                queue = [];
                _.forEach(topic.sessions, function(session) {
                  var event;
                  event = session.send('EVENT', {
                    subscribed: {
                      subscription: {
                        id: topic.id
                      }
                    },
                    published: {
                      publication: {
                        id: publicationId
                      }
                    },
                    details: {},
                    publish: {
                      args: message.args,
                      kwargs: message.kwargs
                    }
                  });
                  return queue.push(event);
                });
                return q.all(queue);
              }).then(function() {
                return logger.info('published event to topic', message.topic);
              })["catch"](function(err) {
                logger.error('cannot publish event to topic', message.topic, err.stack);
                return _this.error('PUBLISH', message.request.id, err);
              }).done();
            case 'REGISTER':
              return q.fcall(function() {
                var defer;
                defer = q.defer();
                _this.emit('register', message.procedure, defer);
                return defer.promise;
              }).then(function(registrationId) {
                return _this.send('REGISTERED', {
                  register: {
                    request: {
                      id: message.request.id
                    }
                  },
                  registration: {
                    id: registrationId
                  }
                });
              })["catch"](function(err) {
                logger.error('cannot register remote procedure', message.procedure, err.stack);
                return _this.error('REGISTER', message.request.id, err);
              }).done();
            case 'UNREGISTER':
              return q.fcall(function() {
                var defer;
                defer = q.defer();
                _this.emit('unregister', message.registered.registration.id, defer);
                return defer.promise;
              }).then(function() {
                return _this.send('UNREGISTERED', {
                  unregister: {
                    request: {
                      id: message.request.id
                    }
                  }
                });
              })["catch"](function(err) {
                logger.error('cannot unregister remote procedure', message.registered.registration.id, err.stack);
                return _this.error('UNREGISTER', message.request.id, err);
              }).done();
            case 'CALL':
              if (_this.isAuthorized(message.procedure)) {
                return q.fcall(function() {
                  var defer;
                  defer = q.defer();
                  _this.emit('call', message.procedure, defer);
                  return defer.promise;
                }).then(function(procedure) {
                  var invocationId;
                  invocationId = procedure.invoke(message.request.id, _this);
                  return procedure.callee.send('INVOCATION', {
                    request: {
                      id: invocationId
                    },
                    registered: {
                      registration: {
                        id: procedure.id
                      }
                    },
                    details: {},
                    call: {
                      args: message.args,
                      kwargs: message.kwargs
                    }
                  });
                })["catch"](function(err) {
                  logger.error('cannot call remote procedure', message.procedure, err.stack);
                  return _this.error('CALL', message.request.id, err);
                }).done();
              } else {
                logger.error('not authorized to call remote procedure', _this.clientRole, message.procedure);
                return _this.error('CALL', message.request.id, new TypeError('wamp.error.not_authorized'));
              }
              break;
            case 'YIELD':
              return q.fcall(function() {
                var defer;
                defer = q.defer();
                _this.emit('yield', message.invocation.request.id, defer);
                return defer.promise;
              }).then(function(invocation) {
                return invocation.session.send('RESULT', {
                  call: {
                    request: {
                      id: invocation.requestId
                    }
                  },
                  options: {},
                  "yield": {
                    args: message.args,
                    kwargs: message.kwargs
                  }
                });
              })["catch"](function(err) {
                return logger.error('cannot yield remote procedure', message.request.id, err.stack);
              }).done();
            case 'ERROR':
              switch (parser.TYPES[message.request.type].type) {
                case 'INVOCATION':
                  return q.fcall(function() {
                    var defer;
                    defer = q.defer();
                    _this.emit('yield', message.request.id, defer);
                    return defer.promise;
                  }).then(function(invocation) {
                    logger.error('trying to send error message for:', message);
                    return invocation.session.send('ERROR', {
                      request: {
                        type: 'CALL',
                        id: invocation.requestId
                      },
                      details: message.details,
                      error: message.error,
                      args: message.args,
                      kwargs: message.kwargs
                    });
                  })["catch"](function(err) {
                    return logger.error('cannot respond to invocation error!', message.request.id, err.stack);
                  }).done();
                default:
                  return logger.error('error response for message type %s is not implemented yet!', message.request.type);
              }
              break;
            default:
              return logger.error('wamp.error.not_implemented');
          }
        };
      })(this))["catch"]((function(_this) {
        return function(err) {
          logger.error('session parse error!', err.stack);
          return _this.close(1011, 'wamp.error.internal_server_error');
        };
      })(this)).done();
    };

    return Session;

  })(EventEmitter);

  module.exports = Session;

}).call(this);
