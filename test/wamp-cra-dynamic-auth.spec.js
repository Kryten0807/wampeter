(function() {
  var CLEANUP_DELAY, CLogger, Cfg, D, INVALID_AUTHID, INVALID_KEY, REALM_URI, ROUTER_CONFIG, VALID_AUTHID, VALID_KEY, autobahn, chai, expect, logger, promised, spies, wampeter;

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

  Cfg = require('./router-config');

  ROUTER_CONFIG = Cfg.dynamic;

  REALM_URI = Cfg.realm;

  VALID_AUTHID = Cfg.valid_authid;

  VALID_KEY = Cfg.valid_key;

  INVALID_AUTHID = 'david.hasselhoff';

  INVALID_KEY = 'xyz789';

  describe('Router:Dynamic WAMP-CRA Successes', function() {
    var connection, router, session;
    router = null;
    connection = null;
    session = null;
    before(function(done_func) {
      var done;
      done = D(done_func);
      router = wampeter.createRouter(ROUTER_CONFIG);
      return setTimeout(done, CLEANUP_DELAY);
    });
    after(function(done_func) {
      var cleanup, done;
      done = D(done_func);
      cleanup = function() {
        return router.close().then(done)["catch"](done).done();
      };
      return setTimeout(cleanup, CLEANUP_DELAY);
    });
    return it('should establish a new session via static wamp-cra authentication', function(done_func) {
      var done, onchallenge;
      done = D(done_func);
      onchallenge = function(session, method, extra) {
        expect(method).to.equal('wampcra');
        return autobahn.auth_cra.sign(VALID_KEY, extra.challenge);
      };
      connection = new autobahn.Connection({
        realm: REALM_URI,
        url: 'ws://localhost:3000/wampeter',
        authmethods: ['wampcra'],
        authid: VALID_AUTHID,
        onchallenge: onchallenge
      });
      connection.onopen = function(s) {
        expect(s).to.be.an["instanceof"](autobahn.Session);
        expect(s.isOpen).to.be["true"];
        session = s;
        return done();
      };
      return connection.open();
    });
  });

  describe('Router:Dynamic WAMP-CRA Failures', function() {
    var connection, router, session;
    router = null;
    connection = null;
    session = null;
    before(function(done_func) {
      var done;
      done = D(done_func);
      router = wampeter.createRouter(ROUTER_CONFIG);
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
    it('should fail to establish a new session - invalid key', function(done_func) {
      var done, onchallenge;
      done = D(done_func);
      onchallenge = function(session, method, extra) {
        expect(method).to.equal('wampcra');
        return autobahn.auth_cra.sign(INVALID_KEY, extra.challenge);
      };
      connection = new autobahn.Connection({
        realm: REALM_URI,
        url: 'ws://localhost:3000/wampeter',
        authmethods: ['wampcra'],
        authid: VALID_AUTHID,
        onchallenge: onchallenge
      });
      connection.onclose = function(reason, message) {
        console.log('------------------------ onclose', message);
        expect(message).to.have.property('reason');
        expect(message.reason).to.equal('wamp.error.not_authorized');
        return done();
      };
      return connection.open();
    });
    it('should fail to establish a new session - invalid auth ID & secret', function(done_func) {
      var done, onchallenge;
      done = D(done_func);
      onchallenge = function(session, method, extra) {
        var err, error;
        expect(method).to.equal('wampcra');
        try {
          return autobahn.auth_cra.sign(INVALID_KEY, extra.challenge);
        } catch (error) {
          err = error;
          console.log('signing failed', err);
          throw err;
        }
      };
      connection = new autobahn.Connection({
        realm: REALM_URI,
        url: 'ws://localhost:3000/wampeter',
        authmethods: ['wampcra'],
        authid: INVALID_AUTHID,
        onchallenge: onchallenge
      });
      connection.onclose = function(reason, message) {
        console.log('------------------------ onclose', message);
        expect(message).to.have.property('reason');
        expect(message.reason).to.equal('wamp.error.not_authorized');
        return done();
      };
      return connection.open();
    });
    it('should fail to establish a new session - invalid challenge', function(done_func) {
      var done, onchallenge;
      done = D(done_func);
      onchallenge = function(session, method, extra) {
        expect(method).to.equal('wampcra');
        return autobahn.auth_cra.sign(VALID_KEY, {
          a: 1,
          b: 2
        });
      };
      connection = new autobahn.Connection({
        realm: REALM_URI,
        url: 'ws://localhost:3000/wampeter',
        authmethods: ['wampcra'],
        authid: VALID_AUTHID,
        onchallenge: onchallenge
      });
      connection.onclose = function(reason, message) {
        console.log('------------------------ onclose', message);
        expect(message).to.have.property('reason');
        expect(message.reason).to.equal('wamp.error.not_authorized');
        return done();
      };
      return connection.open();
    });
    return it('should fail to establish a new session - invalid auth ID', function(done_func) {
      var done, onchallenge;
      done = D(done_func);
      onchallenge = function(session, method, extra) {
        expect(method).to.equal('wampcra');
        return autobahn.auth_cra.sign(VALID_KEY, {
          a: 1,
          b: 2
        });
      };
      connection = new autobahn.Connection({
        realm: REALM_URI,
        url: 'ws://localhost:3000/wampeter',
        authmethods: ['wampcra'],
        authid: INVALID_AUTHID,
        onchallenge: onchallenge
      });
      connection.onclose = function(reason, message) {
        console.log('------------------------ onclose', message);
        expect(message).to.have.property('reason');
        expect(message.reason).to.equal('wamp.error.not_authorized');
        return done();
      };
      return connection.open();
    });
  });

}).call(this);
