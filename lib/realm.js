(function() {
  var Procedure, Realm, Session, Topic, _, logger, parser, q, randomid, util,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  util = require('./util');

  logger = util.logger();

  parser = util.parser();

  randomid = util.randomid;

  Session = require('./session');

  q = require('q');

  _ = require('lodash');

  Realm = (function() {
    function Realm() {
      this["yield"] = bind(this["yield"], this);
      this.invoke = bind(this.invoke, this);
      this.unregister = bind(this.unregister, this);
      this.register = bind(this.register, this);
      this.procedure = bind(this.procedure, this);
      this.topic = bind(this.topic, this);
      this.unsubscribe = bind(this.unsubscribe, this);
      this.subscribe = bind(this.subscribe, this);
      this.removeSession = bind(this.removeSession, this);
      this.cleanup = bind(this.cleanup, this);
      this.addSession = bind(this.addSession, this);
      this.session = bind(this.session, this);
      this.close = bind(this.close, this);
      this.sessions = [];
      this.topics = {};
      this.procedures = {};
    }

    Realm.prototype.close = function(code, reason, wasClean) {
      return q.fcall((function(_this) {
        return function() {
          var promises;
          promises = [];
          _.forEach(_this.sessions, function(session) {
            return promises.push(session.close(code, reason, true));
          });
          return promises;
        };
      })(this)).then(q.all);
    };

    Realm.prototype.session = function(session) {
      if ((session != null) && (session instanceof Session)) {
        return _.find(this.sessions, function(s) {
          return s === session;
        });
      } else {
        throw new Error('wamp.error.invalid_argument');
      }
    };

    Realm.prototype.addSession = function(session) {
      if (this.session(session) == null) {
        return this.sessions.push(session);
      } else {
        throw new Error('wamp.error.session_already_exists');
      }
    };

    Realm.prototype.cleanup = function(session) {
      _.forEach(this.procedures, (function(_this) {
        return function(procedure) {
          return _this.unregister(procedure.id, session);
        };
      })(this));
      _.forEach(this.topics, function(topic, key) {
        topic.removeSession(session);
        if (topic.sessions.length === 0) {
          return delete this.topics[key];
        }
      });
      return this;
    };

    Realm.prototype.removeSession = function(session) {
      if (this.session(session)) {
        return this.sessions = _.filter(this.sessions, function(s) {
          return s !== session;
        });
      } else {
        throw new Error('wamp.error.no_such_session');
      }
    };

    Realm.prototype.subscribe = function(uri, session) {
      if (parser.isUri(uri) && (this.session(session) != null)) {
        if (this.topics[uri] == null) {
          this.topics[uri] = new Topic();
        }
        this.topics[uri].addSession(session);
        return this.topics[uri].id;
      } else {
        throw new TypeError('wamp.error.invalid_argument');
      }
    };

    Realm.prototype.unsubscribe = function(id, session) {
      var key, topic;
      if (_.isNumber(id) && (this.session(session) != null)) {
        key = null;
        topic = _.find(this.topics, function(t, k) {
          if (t.id === id) {
            key = k;
            return true;
          }
        });
        if (topic != null) {
          topic.removeSession(session);
          if (topic.sessions.length === 0) {
            return delete this.topics[key];
          }
        } else {
          throw new TypeError('wamp.error.no_such_topic');
        }
      }
    };

    Realm.prototype.topic = function(uri) {
      if (parser.isUri(uri)) {
        if (this.topics[uri] != null) {
          return this.topics[uri];
        } else {
          throw new Error('wamp.error.no_such_subscription');
        }
      } else {
        throw new TypeError('wamp.error.invalid_uri');
      }
    };

    Realm.prototype.procedure = function(uri) {
      if (parser.isUri(uri)) {
        if (this.procedures[uri] != null) {
          return this.procedures[uri];
        } else {
          throw new Error('wamp.error.no_such_registration');
        }
      } else {
        throw new TypeError('wamp.error.invalid_uri');
      }
    };

    Realm.prototype.register = function(uri, callee) {
      var procedure;
      if (parser.isUri(uri) && this.session(callee)) {
        if (this.procedures[uri] == null) {
          procedure = new Procedure(callee);
          this.procedures[uri] = procedure;
          return procedure.id;
        } else {
          throw new Error('wamp.error.procedure_already_exists');
        }
      } else {
        throw new TypeError('wamp.error.invalid_argument');
      }
    };

    Realm.prototype.unregister = function(id, callee) {
      var uri;
      if (_.isNumber(id) && this.session(callee)) {
        uri = _.findKey(this.procedures, function(p) {
          return p.id === id && p.callee === callee;
        });
        if (uri != null) {
          return delete this.procedures[uri];
        } else {
          throw new Error('wamp.error.no_such_registration');
        }
      } else {
        throw new TypeError('wamp.error.invalid_argument');
      }
    };

    Realm.prototype.invoke = function(uri, session, requestId) {
      var procedure;
      if (parser.isUri(uri) && (this.session(session) != null) && _.isNumber(requestId)) {
        procedure = this.procedures[uri];
        if ((procedure != null) && (procedure instanceof Procedure)) {
          return procedure.invoke(session, requestId);
        } else {
          throw new Error('wamp.error.no_such_procedure');
        }
      } else {
        throw new TypeError('wamp.error.invalid_argument');
      }
    };

    Realm.prototype["yield"] = function(id) {
      if (_.isNumber(id)) {
        return _.find(this.procedures, function(procedure) {
          return procedure.caller[id];
        })["yield"](id);
      } else {
        throw new TypeError('wamp.error.invalid_argument');
      }
    };

    module.exports = Realm;

    return Realm;

  })();

  Topic = (function() {
    function Topic() {
      this.removeSession = bind(this.removeSession, this);
      this.addSession = bind(this.addSession, this);
      this.id = randomid();
      this.sessions = [];
    }

    Topic.prototype.addSession = function(session) {
      if ((session != null) && (session instanceof Session)) {
        if (_.indexOf(this.sessions, session) === -1) {
          return this.sessions.push(session);
        } else {
          throw new Error('wamp.error.topic_already_subscribed');
        }
      } else {
        throw new TypeError('wamp.error.invalid_arguments');
      }
    };

    Topic.prototype.removeSession = function(session) {
      if ((session != null) && (session instanceof Session)) {
        return this.sessions = _.filter(this.sessions, function(s) {
          return s !== session;
        });
      } else {
        throw new TypeError('wamp.error.invalid_argument');
      }
    };

    return Topic;

  })();

  Procedure = (function() {
    function Procedure(callee) {
      this["yield"] = bind(this["yield"], this);
      this.invoke = bind(this.invoke, this);
      if ((callee != null) && (callee instanceof Session)) {
        this.callee = callee;
      } else {
        throw new TypeError('wamp.error.invalid_argument');
      }
      this.id = randomid();
      this.caller = {};
    }

    Procedure.prototype.invoke = function(requestId, session) {
      var id;
      if ((session != null) && (session instanceof Session) && (this.callee instanceof Session)) {
        id = randomid();
        this.caller[id] = {
          requestId: requestId,
          session: session
        };
        return id;
      } else {
        throw new TypeError('wamp.error.invalid_argument');
      }
    };

    Procedure.prototype["yield"] = function(id) {
      var invocation;
      if (_.isNumber(id)) {
        invocation = this.caller[id];
        delete this.caller[id];
        return invocation;
      } else {
        throw new TypeError('wamp.error.invalid_argument');
      }
    };

    return Procedure;

  })();

}).call(this);
