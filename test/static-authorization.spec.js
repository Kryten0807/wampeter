(function() {
  var BASE_URI, CLEANUP_DELAY, CLogger, D, PORT, Q, REALM_URI, ROLE, ROUTER_CONFIG, URL, VALID_AUTHID, VALID_KEY, authenticator, autobahn, chai, expect, logger, obj, obj1, obj2, promised, spies, wampeter;

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

  PORT = 3000;

  URL = "ws://localhost:" + PORT;

  BASE_URI = 'com.to.inge';

  REALM_URI = BASE_URI + '.world';

  VALID_AUTHID = 'nicolas.cage';

  VALID_KEY = 'abc123';

  ROLE = 'role_1';

  authenticator = function(realm, authid, details) {
    expect(realm).to.be.equal(REALM_URI);
    return {
      secret: VALID_KEY,
      role: 'frontend'
    };
  };

  ROUTER_CONFIG = {
    port: PORT,
    realms: (
      obj = {},
      obj["" + REALM_URI] = {
        roles: (
          obj1 = {},
          obj1["" + ROLE] = {},
          obj1
        )
      },
      obj
    ),
    auth: {
      wampcra: {
        type: 'static',
        users: (
          obj2 = {},
          obj2["" + VALID_AUTHID] = {
            secret: VALID_KEY,
            role: 'frontend'
          },
          obj2
        )
      }
    }
  };

  describe('Router:Static Authorization', function() {
    var connect, connection, router, session;
    router = null;
    connection = null;
    session = null;

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
    after(function(done_func) {
      var cleanup, done;
      done = D(done_func);
      cleanup = function() {
        return router.close().then(done)["catch"](done).done();
      };
      return setTimeout(cleanup, CLEANUP_DELAY);
    });
    connect = function(authConfig) {
      var cfg, deferred, onchallenge;
      logger.debug('------------- setting up deferred');
      deferred = Q.defer();
      cfg = ROUTER_CONFIG;
      cfg.realms[REALM_URI].roles[ROLE_NAME] = authConfig;
      logger.debug('------------- setting up router', cfg.realms);
      router = wampeter.createRouter(cfg);
      logger.debug('------------- setting up realm', REALM_URI);
      router.createRealm(REALM_URI);
      onchallenge = function(session, method, extra) {
        logger.debug('------------- onchallenge');
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
        logger.debug('------------- onopen');
        expect(s).to.be.an["instanceof"](autobahn.Session);
        expect(s.isOpen).to.be["true"];
        session = s;
        logger.debug('------------- onopen - resolving deferred');
        return deferred.resolve('here i am');
      };
      logger.debug('------------- opening connection');
      connection.open();
      logger.debug('------------- returning deferred');
      return deferred.promise;
    };
    return it('should successfully call when call permitted', function(done_func) {
      var config, done;
      logger.debug('------------- in test method');
      done = D(done_func);
      config = [
        {
          uri: '*',
          allow: {
            call: true,
            register: false,
            subscribe: false,
            publish: false
          }
        }
      ];
      return connect(config).then(function() {
        logger.debug('------------- in connect deferred');
        return session.call('com.example.authtest', ['hello inge!'], {
          to: 'inge'
        }).then(function(result) {
          console.log('------------------ RPC', result);
          return done();
        })["catch"](function(err) {
          return done(new Error(err));
        }).done();
      });
    });
  });

}).call(this);
