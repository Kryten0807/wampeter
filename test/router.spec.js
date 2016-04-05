(function() {
  var CLEANUP_DELAY, CLogger, D, autobahn, chai, expect, logger, promised, spies, wampeter;

  global.AUTOBAHN_DEBUG = true;

  wampeter = require('../lib/router');

  CLogger = require('node-clogger');

  autobahn = require('autobahn');

  chai = require('chai');

  expect = chai.expect;

  promised = require('chai-as-promised');

  spies = require('chai-spies');

  D = require('./done');

  logger = new CLogger({
    name: 'router-tests'
  });

  chai.use(spies).use(promised);

  CLEANUP_DELAY = 500;

  describe('Router#constructor', function() {
    return it('should instantiate', function(done_func) {
      var done, router;
      done = D(done_func);
      router = wampeter.createRouter({
        port: 3000
      });
      expect(router).to.be.an["instanceof"](wampeter.Router);
      expect(router.roles).to.have.property('broker');
      expect(router.roles).to.have.property('dealer');
      return router.close().then(done)["catch"](done).done();
    });
  });

  describe('Router:Session', function() {
    var connection, router, session;
    router = null;
    connection = null;
    session = null;
    before(function(done_func) {
      var done;
      done = D(done_func);
      router = wampeter.createRouter({
        port: 3000
      });
      return setTimeout((function() {
        return done();
      }), CLEANUP_DELAY);
    });
    after(function(done_func) {
      var done;
      done = D(done_func);
      return setTimeout((function() {
        return router.close().then(done)["catch"](done).done();
      }), CLEANUP_DELAY);
    });
    it('should establish a new session', function(done_func) {
      var done;
      done = D(done_func);
      router.createRealm('com.to.inge.world');
      connection = new autobahn.Connection({
        realm: 'com.to.inge.world',
        url: 'ws://localhost:3000/wampeter'
      });
      connection.onopen = function(s) {
        expect(s).to.be.an["instanceof"](autobahn.Session);
        expect(s.isOpen).to.be["true"];
        session = s;
        return done();
      };
      return connection.open();
    });
    return it('should close a session', function(done_func) {
      var done;
      done = D(done_func);
      expect(connection).to.be.an["instanceof"](autobahn.Connection);
      connection.onclose = function(reason) {
        expect(reason).to.be.equal('closed');
        return done();
      };
      return connection.close();
    });
  });

  describe('Router:Publish/Subscribe', function() {
    var connection, onevent, router, session, spyEvent, subscription;
    router = null;
    connection = null;
    session = null;
    subscription = null;
    before(function(done_func) {
      var done;
      done = D(done_func);
      router = wampeter.createRouter({
        port: 3000
      });
      return setTimeout((function() {
        connection = new autobahn.Connection({
          realm: 'com.to.inge.world',
          url: 'ws://localhost:3000/wampeter'
        });
        connection.onopen = function(s) {
          logger.info('router up and session connected');
          session = s;
          return done();
        };
        return connection.open();
      }), CLEANUP_DELAY);
    });
    after(function(done_func) {
      var done;
      done = D(done_func);
      connection.close();
      return setTimeout((function() {
        return router.close().then(done)["catch"](done).done();
      }), CLEANUP_DELAY);
    });
    onevent = function(args, kwargs, details) {
      logger.info('on event');
      expect(args).to.be.ok;
      expect(kwargs).to.be.ok;
      return expect(details).to.be.ok;
    };
    spyEvent = chai.spy(onevent);
    it('should subscribe to a topic', function(done_func) {
      var done;
      done = D(done_func);
      logger.info('try to subscribe');
      expect(session.isOpen).to.be["true"];
      return session.subscribe('com.example.inge', spyEvent).then(function(s) {
        logger.info('subscribed to topic');
        subscription = s;
        return done();
      })["catch"](function(err) {
        return done(new TypeError(err.stack));
      }).done();
    });
    it('should publish to a topic', function(done_func) {
      var done;
      done = D(done_func);
      expect(session.isOpen).to.be["true"];
      session.publish('com.example.inge', ['hello inge!'], {
        to: 'inge'
      }, {
        acknowledge: true
      }).then(function(published) {
        return expect(published).to.have.property('id');
      })["catch"](function(err) {
        return done(new Error(err.stack));
      }).done();
      return setTimeout((function() {
        expect(spyEvent).to.have.been.called.once;
        return done();
      }), 500);
    });
    return it('should unsubscribe from a topic', function(done_func) {
      var done;
      done = D(done_func);
      expect(session.isOpen).to.be["true"];
      return session.unsubscribe(subscription).then(function() {
        return done();
      })["catch"](function(err) {
        return done(new Error(err.stack));
      }).done();
    });
  });

  describe('Router:Remote Procedures', function() {
    var connection, onCall, registration, router, session, spyCall;
    router = null;
    connection = null;
    session = null;
    registration = null;
    before(function(done_func) {
      var done;
      done = D(done_func);
      router = wampeter.createRouter({
        port: 3000
      });
      return setTimeout((function() {
        connection = new autobahn.Connection({
          realm: 'com.to.inge.world',
          url: 'ws://localhost:3000/wampeter'
        });
        connection.onopen = function(s) {
          session = s;
          return done();
        };
        return connection.open();
      }), CLEANUP_DELAY);
    });
    after(function(done_func) {
      var done;
      done = D(done_func);
      connection.close();
      return setTimeout((function() {
        return router.close().then(done)["catch"](done).done();
      }), CLEANUP_DELAY);
    });
    onCall = function(args, kwargs, details) {
      expect(args).to.be.deep.equal(['hello inge!']);
      expect(kwargs).to.have.property('to');
      expect(details).to.be.ok;
      if (kwargs.to === 'world') {
        throw new autobahn.Error('com.example.inge.error', args, kwargs);
      } else {
        return 'inge';
      }
    };
    spyCall = chai.spy(onCall);
    it('should register a remote procedure', function(done_func) {
      var done;
      done = D(done_func);
      expect(session.isOpen).to.be["true"];
      return session.register('com.example.inge', spyCall).then(function(r) {
        expect(r).to.have.property('id');
        registration = r;
        return done();
      })["catch"](function(err) {
        return console.log(err.stack);
      }).done();
    });
    it('should call a remote procedure', function(done_func) {
      var done;
      done = D(done_func);
      expect(session.isOpen).to.be["true"];
      return session.call('com.example.inge', ['hello inge!'], {
        to: 'inge'
      }).then(function(result) {
        expect(result).to.be.equal('inge');
        expect(spyCall).to.have.been.called.once;
        return done();
      })["catch"](function(err) {
        return done(new Error(err));
      }).done();
    });
    it('should return an error, if remote procedure throws', function(done_func) {
      var done;
      done = D(done_func);
      expect(session.isOpen).to.be["true"];
      return session.call('com.example.inge', ['hello inge!'], {
        to: 'world'
      })["catch"](function(err) {
        expect(err).to.be.an["instanceof"](autobahn.Error);
        expect(err.error).to.be.equal('com.example.inge.error');
        expect(err.args).to.be.deep.equal(['hello inge!']);
        expect(err.kwargs).to.have.property('to', 'world');
        expect(spyCall).to.have.been.called.twice;
        return done();
      });
    });
    return it('should unregister a remote procedure', function(done_func) {
      var done;
      done = D(done_func);
      expect(session.isOpen).to.be["true"];
      return session.unregister(registration).then(function() {
        return done();
      })["catch"](function(err) {
        return done(new Error(err.stack));
      }).done();
    });
  });

}).call(this);
