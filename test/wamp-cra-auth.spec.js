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
    var AUTHID, INVALID_KEY, VALID_KEY, connection, router, session;
    router = null;
    connection = null;
    session = null;
    AUTHID = 'j.smith';
    VALID_KEY = 'abc123';
    INVALID_KEY = 'xyz789';
    before(function(done) {
      var obj;
      router = wampeter.createRouter({
        port: 3000,
        auth: {
          wampcra: {
            type: 'static',
            users: (
              obj = {},
              obj["" + AUTHID] = {
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
      }), 500);
    });
    after(function(done) {
      return setTimeout(function() {
        return router.close().then(done)["catch"](done).done();
      });
    });
    return it('should establish a new session via static wamp-cra authentication', function(done) {
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
        authid: AUTHID,
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

    /*
    it('should fail to establish a new session via static wamp-cra authentication', (done)->
        router.createRealm('com.to.inge.world')
    
    
        onchallenge = (session, method, extra)->
    
            expect(method).to.equal('wampcra')
    
             * respond to the challenge
             *
            autobahn.auth_cra.sign(INVALID_KEY, extra.challenge)
    
        connection = new autobahn.Connection({
            realm: 'com.to.inge.world'
            url: 'ws://localhost:3000/wampeter'
    
            authmethods: ['wampcra']
            authid: AUTHID
            onchallenge: onchallenge
        })
    
    
        connection.onopen = (s)->
            expect(s).to.be.an.instanceof(autobahn.Session)
            expect(s.isOpen).to.be.true
            session = s
             * done()
    
        connection.onerror = (err)->
            expect(err.type).to.be('wamp.error.not_not_authorized')
    
            done()
    
        connection.open()
    )
     */

    /*
    it('should close a session', (done)->
        expect(connection).to.be.an.instanceof(autobahn.Connection)
    
        connection.onclose = (reason)->
            expect(reason).to.be.equal('closed')
            done()
    
        connection.close()
    )
     */
  });

}).call(this);
