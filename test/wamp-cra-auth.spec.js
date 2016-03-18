(function() {
  var CLogger, autobahn, chai, expect, logger, promised, spies, wampeter;

  global.AUTOBAHN_DEBUG = true;

  wampeter = require('../lib/router');

  CLogger = require('node-clogger');

  autobahn = require('autobahn');

  chai = require('chai');

  expect = chai.expect;

  promised = require('chai-as-promised');

  spies = require('chai-spies');

  logger = new CLogger({
    name: 'router-tests'
  });

  chai.use(spies).use(promised);

  describe('Router:Session', function() {
    var INVALID_KEY, VALID_KEY, connection, router, session;
    router = null;
    connection = null;
    session = null;
    VALID_KEY = 'abc123';
    INVALID_KEY = 'xyz789';
    before(function(done) {
      router = wampeter.createRouter({
        port: 3000,
        auth: {
          wampcra: {
            type: 'static',
            users: {
              'alpha': {
                secret: VALID_KEY,
                role: 'frontend'
              }
            }
          }
        }
      });
      return setTimeout((function() {
        return done();
      }), 500);
    });
    after(function(done) {
      if ((connection != null) && connection.isOpen) {
        connection.close();
      }
      return setTimeout(function() {
        return router.close().then(done)["catch"](done).done();
      });
    });
    it('should establish a new session via static wamp-cra authentication', function(done) {
      router.createRealm('com.to.inge.world');
      connection = new autobahn.Connection({
        realm: 'com.to.inge.world',
        url: 'ws://localhost:3000/wampeter',
        authmethods: ['wampcra']
      });
      connection.onchallenge = function(session, method, extra) {
        expect(method).to.be('wampcra');
        autobahn.auth_cra.sign(VALID_KEY, extra.challenge);
        return done();
      };
      connection.onopen = function(s) {
        expect(s).to.be.an["instanceof"](autobahn.Session);
        expect(s.isOpen).to.be["true"];
        return session = s;
      };
      return connection.open();
    });
    it('should fail to establish a new session via static wamp-cra authentication', function(done) {
      router.createRealm('com.to.inge.world');
      connection = new autobahn.Connection({
        realm: 'com.to.inge.world',
        url: 'ws://localhost:3000/wampeter',
        authmethods: ['wampcra']
      });
      connection.onchallenge = function(session, method, extra) {
        expect(method).to.be('wampcra');
        return autobahn.auth_cra.sign(INVALID_KEY, extra.challenge);
      };
      connection.onopen = function(s) {
        expect(s).to.be.an["instanceof"](autobahn.Session);
        expect(s.isOpen).to.be["true"];
        return session = s;
      };
      connection.onerror = function(err) {
        expect(err.type).to.be('wamp.error.not_not_authorized');
        return done();
      };
      return connection.open();
    });
    return it('should close a session', function(done) {
      expect(connection).to.be.an["instanceof"](autobahn.Connection);
      connection.onclose = function(reason) {
        expect(reason).to.be.equal('closed');
        return done();
      };
      return connection.close();
    });
  });

}).call(this);
