(function() {
  var CLEANUP_DELAY, CLogger, Cfg, D, INVALID_AUTHID, INVALID_KEY, Q, REALM_URI, ROLE, ROUTER_CONFIG, VALID_AUTHID, VALID_KEY, autobahn, chai, expect, logger, promised, spies, wampeter;

  global.AUTOBAHN_DEBUG = true;

  wampeter = require('../lib/router');

  CLogger = require('node-clogger');

  autobahn = require('autobahn');

  chai = require('chai');

  expect = chai.expect;

  promised = require('chai-as-promised');

  spies = require('chai-spies');

  Q = require('q');

  D = require('./done');

  logger = new CLogger({
    name: 'router-tests'
  });

  chai.use(spies).use(promised);

  CLEANUP_DELAY = 500;

  Cfg = require('./router-config');

  ROUTER_CONFIG = Cfg["static"];

  REALM_URI = Cfg.realm;

  ROLE = Cfg.role;

  VALID_AUTHID = Cfg.valid_authid;

  VALID_KEY = Cfg.valid_key;

  INVALID_AUTHID = 'david.hasselhoff';

  INVALID_KEY = 'xyz789';

  describe('Router:Static Authorization', function() {
    var connect, connection, router;
    router = null;
    connection = null;

    /*
    before((done_func)->
        done = D(done_func)
    
        router = wampeter.createRouter(ROUTER_CONFIG)
    
        router.createRealm(REALM_URI)
    
        onchallenge = (session, method, extra)->
    
            expect(method).to.equal('wampcra')
    
             * respond to the challenge
             *
            autobahn.auth_cra.sign(VALID_KEY, extra.challenge)
    
        connection = new autobahn.Connection({
            realm: REALM_URI
            url: 'ws://localhost:3000/wampeter'
    
            authmethods: ['wampcra']
            authid: VALID_AUTHID
            onchallenge: onchallenge
        })
    
    
        connection.onopen = (s)->
            expect(s).to.be.an.instanceof(autobahn.Session)
            expect(s.isOpen).to.be.true
            session = s
            setTimeout(done, CLEANUP_DELAY)
    
        connection.open()
    )
     */
    afterEach(function(done_func) {
      var cleanup, done;
      done = D(done_func);
      cleanup = function() {
        return router.close().then(done)["catch"](done).done();
      };
      return setTimeout(cleanup, CLEANUP_DELAY);
    });
    connect = function(authConfig) {
      var cfg, deferred, onchallenge;
      deferred = Q.defer();
      cfg = ROUTER_CONFIG;
      cfg.realms[REALM_URI].roles[ROLE] = authConfig;
      router = wampeter.createRouter(cfg);
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
      connection.onopen = function(session) {
        expect(session).to.be.an["instanceof"](autobahn.Session);
        expect(session.isOpen).to.be["true"];
        return setTimeout((function() {
          return deferred.resolve(session);
        }), CLEANUP_DELAY);
      };
      connection.open();
      return deferred.promise;
    };
    it('should successfully call when call permitted', function(done_func) {
      var config, done;
      logger.debug('------------- in test method');
      done = D(done_func);
      config = {
        '*': {
          call: true,
          register: false,
          subscribe: false,
          publish: false
        }
      };
      return connect(config).then(function(session) {
        return session.call('com.example.authtest', ['hello inge!'], {
          to: 'inge'
        }).then(function(result) {
          console.log('------------------ RPC', result);
          return done();
        })["catch"](function(err) {
          expect(err.error).to.equal('wamp.error.no_such_registration');
          return done();
        }).done();
      });
    });
    return it('should fail to call when call disallowed', function(done_func) {
      var config, done;
      logger.debug('------------- in test method');
      done = D(done_func);
      config = {
        '*': {
          call: false,
          register: false,
          subscribe: false,
          publish: false
        }
      };
      return connect(config).then(function(session) {
        return session.call('com.example.authtest', ['hello inge!'], {
          to: 'inge'
        }).then(function(result) {
          console.log('------------------ RPC', result);
          return done();
        })["catch"](function(err) {
          expect(err.error).to.equal('wamp.error.not_authorized');
          return done();
        }).done();
      });
    });
  });

}).call(this);
