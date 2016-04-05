(function() {
  var CLEANUP_DELAY, CLogger, autobahn, chai, expect, logger, promised, spies, wampeter;

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

  CLEANUP_DELAY = 500;

  describe('Router:Session', function() {
    var INVALID_AUTHID, INVALID_KEY, VALID_AUTHID, VALID_KEY, connection, router, session;
    router = null;
    connection = null;
    session = null;
    VALID_AUTHID = 'nicolas.cage';
    VALID_KEY = 'abc123';
    INVALID_AUTHID = 'david.hasselhoff';
    INVALID_KEY = 'xyz789';
    beforeEach(function(done) {
      var obj;
      router = wampeter.createRouter({
        port: 3000,
        auth: {
          wampcra: {
            type: 'static',
            users: (
              obj = {},
              obj["" + VALID_AUTHID] = {
                secret: VALID_KEY,
                role: 'frontend'
              },
              obj
            )
          }
        }
      });
      return setTimeout((function() {
        return done();
      }), CLEANUP_DELAY);
    });
    afterEach(function(done) {
      return setTimeout((function() {
        return router.close().then(done)["catch"](done).done();
      }), CLEANUP_DELAY);
    });
    it('should fail to establish a new session - invalid key', function(done) {
      var onchallenge;
      router.createRealm('com.to.inge.world');
      onchallenge = function(session, method, extra) {
        expect(method).to.equal('wampcra');
        return autobahn.auth_cra.sign(INVALID_KEY, extra.challenge);
      };
      connection = new autobahn.Connection({
        realm: 'com.to.inge.world',
        url: 'ws://localhost:3000/wampeter',
        authmethods: ['wampcra'],
        authid: VALID_AUTHID,
        onchallenge: onchallenge
      });
      connection.onclose = function(e) {
        logger.error('closing', e);
        return done();
      };
      return connection.open();
    });
    it('should fail to establish a new session - invalid auth ID & secret', function(done) {
      var onchallenge;
      router.createRealm('com.to.inge.world');
      onchallenge = function(session, method, extra) {
        expect(method).to.equal('wampcra');
        return autobahn.auth_cra.sign(INVALID_KEY, extra.challenge);
      };
      connection = new autobahn.Connection({
        realm: 'com.to.inge.world',
        url: 'ws://localhost:3000/wampeter',
        authmethods: ['wampcra'],
        authid: INVALID_AUTHID,
        onchallenge: onchallenge
      });
      connection.onclose = function(e) {
        logger.error('closing', e);
        return done();
      };
      return connection.open();
    });
    it('should fail to establish a new session - invalid challenge', function(done) {
      var onchallenge;
      router.createRealm('com.to.inge.world');
      onchallenge = function(session, method, extra) {
        expect(method).to.equal('wampcra');
        return autobahn.auth_cra.sign(VALID_KEY, {
          a: 1,
          b: 2
        });
      };
      connection = new autobahn.Connection({
        realm: 'com.to.inge.world',
        url: 'ws://localhost:3000/wampeter',
        authmethods: ['wampcra'],
        authid: VALID_AUTHID,
        onchallenge: onchallenge
      });
      connection.onclose = function(e) {
        logger.error('closing', e);
        return done();
      };
      return connection.open();
    });
    return it('should fail to establish a new session - invalid auth ID', function(done) {
      var onchallenge;
      router.createRealm('com.to.inge.world');
      onchallenge = function(session, method, extra) {
        expect(method).to.equal('wampcra');
        return autobahn.auth_cra.sign(VALID_KEY, extra.challenge);
      };
      connection = new autobahn.Connection({
        realm: 'com.to.inge.world',
        url: 'ws://localhost:3000/wampeter',
        authmethods: ['wampcra'],
        authid: INVALID_AUTHID,
        onchallenge: onchallenge
      });
      connection.onclose = function(e) {
        logger.error('closing', e);
        return done();
      };
      return connection.open();
    });
  });

}).call(this);
