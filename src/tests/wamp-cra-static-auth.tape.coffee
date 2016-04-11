global.AUTOBAHN_DEBUG = true;

CLogger  = require('node-clogger')
logger = new CLogger({name: 'router-tests'})

test = require('tape')
sinon = require('sinon')

wampeter  = require('../lib/router')
autobahn = require('autobahn')

Cfg = require('./router-config')

ROUTER_CONFIG = Cfg.static
REALM_URI =     Cfg.realm
VALID_AUTHID =  Cfg.valid_authid
VALID_SECRET =  Cfg.valid_secret

INVALID_AUTHID = 'david.hasselhoff'
INVALID_SECRET = 'xyz789'

Manager = require('./test-manager')
TestManager = Manager.TestManager

mgr = new TestManager()

# when the manager signals "tests complete", wait 1/2 secound & exit
#
mgr.onComplete = ()-> Manager.pause().then(()-> process.exit())

# ------------------------------------------------------------------------------
# Successfully establish a new session with authentication
# ------------------------------------------------------------------------------
test('Static WAMP-CRA : establish a new session', (assert)->

    # signal the start of the test to the manager
    #
    mgr.start()

    router = null


    onChallenge = (session, method, extra)->
        assert.true(method=='wampcra')

        # respond to the challenge
        #
        autobahn.auth_cra.sign(VALID_SECRET, extra.challenge)


    Manager.createRouter(ROUTER_CONFIG).then((rtr)->

        # save the router object
        #
        router = rtr

        # open the connection & return the promise to complete the connection
        #
        Manager.openConnection({
            realm: REALM_URI
            url: 'ws://localhost:3000/wampeter'

            authmethods: ['wampcra']
            authid: VALID_AUTHID
            onchallenge: onChallenge
        })

    ).then((values)->

        # extract the connection & session values
        #
        [connection, session] = values

        # connection is open - test some stuff
        #
        assert.true(session instanceof autobahn.Session, 'instance of autobahn.Session')
        assert.true(session.isOpen, 'session is open')

        # close the connection
        #
        Manager.closeConnection(connection)

    ).then((closeReason)->

        # connection is closed - test the reason
        #
        assert.true(closeReason=='closed', 'correct close reason')

        # pause, then close the router
        #
        Manager.pause()

    ).then(()->

        # close the router
        #
        router.close()

    ).catch((err)->

        # something went wrong - report the error
        #
        console.log('*************** ERROR', err)
        console.log(err.trace)

    ).finally(()->

        # all done, stop testing
        #
        assert.end()

        # signal the manager that we're done
        #
        mgr.end()

    ).done()
)


# ------------------------------------------------------------------------------
# Fail to establish a new session - invalid authid
# ------------------------------------------------------------------------------
test('Static WAMP-CRA : fail to establish a new session - invalid authid', (assert)->

    # signal the start of the test to the manager
    #
    mgr.start()

    router = null

    onChallenge = (session, method, extra)->
        assert.true(method=='wampcra')

        # respond to the challenge
        #
        autobahn.auth_cra.sign(VALID_SECRET, extra.challenge)

    Manager.createRouter(ROUTER_CONFIG).then((rtr)->

        # save the router object
        #
        router = rtr

        # open the connection & return the promise to complete the connection
        #
        Manager.openConnection({
            realm: REALM_URI
            url: 'ws://localhost:3000/wampeter'

            authmethods: ['wampcra']
            authid: INVALID_AUTHID
            onchallenge: onChallenge
        })

    ).then((values)->

        # extract the connection & session values
        #
        [connection, session] = values

        # connection is open - test some stuff
        #
        assert.false(session instanceof autobahn.Session, 'session should not be instance of autobahn.Session')
        assert.false(session.isOpen, 'session is not open')

        # close the connection
        #
        Manager.closeConnection(connection)

    ).then((closeReason)->
        # connection is closed - test the reason
        #
        assert.true(closeReason[0]=='closed', 'correct close reason')

        # pause, then close the router
        #
        Manager.pause()

    ).then(()->

        # close the router
        #
        router.close()

    ).catch((err)->
        # we SHOULD get here - the connection closed as soon as it opened due to
        # authentication failure
        #
        assert.true(err[1].reason=='wamp.error.not_authorized', 'got not authorized message')
    ).finally(()->
        # all done, stop testing
        #
        assert.end()

        # signal the manager that we're done
        #
        mgr.end()

    ).done()
)


# ------------------------------------------------------------------------------
# Fail to establish a new session - invalid secret
# ------------------------------------------------------------------------------
test('Static WAMP-CRA : fail to establish a new session - invalid secret', (assert)->

    # signal the start of the test to the manager
    #
    mgr.start()

    router = null

    onChallenge = (session, method, extra)->
        assert.true(method=='wampcra')

        # respond to the challenge
        #
        autobahn.auth_cra.sign(INVALID_SECRET, extra.challenge)

    Manager.createRouter(ROUTER_CONFIG).then((rtr)->

        # save the router object
        #
        router = rtr

        # open the connection & return the promise to complete the connection
        #
        Manager.openConnection({
            realm: REALM_URI
            url: 'ws://localhost:3000/wampeter'

            authmethods: ['wampcra']
            authid: VALID_AUTHID
            onchallenge: onChallenge
        })

    ).then((values)->

        # extract the connection & session values
        #
        [connection, session] = values

        # connection is open - test some stuff
        #
        assert.false(session instanceof autobahn.Session, 'session should not be instance of autobahn.Session')
        assert.false(session.isOpen, 'session is not open')

        # close the connection
        #
        Manager.closeConnection(connection)

    ).then((closeReason)->
        # connection is closed - test the reason
        #
        assert.true(closeReason[0]=='closed', 'correct close reason')

        # pause, then close the router
        #
        Manager.pause()

    ).then(()->

        # close the router
        #
        router.close()

    ).catch((err)->
        # we SHOULD get here - the connection closed as soon as it opened due to
        # authentication failure
        #
        assert.true(err[1].reason=='wamp.error.not_authorized', 'got not authorized message')
    ).finally(()->
        # all done, stop testing
        #
        assert.end()

        # signal the manager that we're done
        #
        mgr.end()

    ).done()
)


# ------------------------------------------------------------------------------
# Fail to establish a new session - invalid authid & secret
# ------------------------------------------------------------------------------
test('Static WAMP-CRA : fail to establish a new session - invalid authid & secret', (assert)->

    # signal the start of the test to the manager
    #
    mgr.start()

    router = null

    onChallenge = (session, method, extra)->
        assert.true(method=='wampcra')

        # respond to the challenge
        #
        autobahn.auth_cra.sign(INVALID_SECRET, extra.challenge)

    Manager.createRouter(ROUTER_CONFIG).then((rtr)->

        # save the router object
        #
        router = rtr

        # open the connection & return the promise to complete the connection
        #
        Manager.openConnection({
            realm: REALM_URI
            url: 'ws://localhost:3000/wampeter'

            authmethods: ['wampcra']
            authid: INVALID_AUTHID
            onchallenge: onChallenge
        })

    ).then((values)->

        # extract the connection & session values
        #
        [connection, session] = values

        # connection is open - test some stuff
        #
        assert.false(session instanceof autobahn.Session, 'session should not be instance of autobahn.Session')
        assert.false(session.isOpen, 'session is not open')

        # close the connection
        #
        Manager.closeConnection(connection)

    ).then((closeReason)->
        # connection is closed - test the reason
        #
        assert.true(closeReason[0]=='closed', 'correct close reason')

        # pause, then close the router
        #
        Manager.pause()

    ).then(()->

        # close the router
        #
        router.close()

    ).catch((err)->
        # we SHOULD get here - the connection closed as soon as it opened due to
        # authentication failure
        #
        assert.true(err[1].reason=='wamp.error.not_authorized', 'got not authorized message')
    ).finally(()->
        # all done, stop testing
        #
        assert.end()

        # signal the manager that we're done
        #
        mgr.end()

    ).done()
)


# ------------------------------------------------------------------------------
# Fail to establish a new session - onChallenge fails to sign correctly
# ------------------------------------------------------------------------------
test('Static WAMP-CRA : fail to establish a new session - onChallenge failure', (assert)->

    # signal the start of the test to the manager
    #
    mgr.start()

    router = null

    onChallenge = (session, method, extra)->
        assert.true(method=='wampcra')

        # respond to the challenge
        #
        autobahn.auth_cra.sign(VALID_SECRET, {msg: 'this is not the challenge object!'})

    Manager.createRouter(ROUTER_CONFIG).then((rtr)->

        # save the router object
        #
        router = rtr

        # open the connection & return the promise to complete the connection
        #
        Manager.openConnection({
            realm: REALM_URI
            url: 'ws://localhost:3000/wampeter'

            authmethods: ['wampcra']
            authid: VALID_AUTHID
            onchallenge: onChallenge
        })

    ).then((values)->

        # extract the connection & session values
        #
        [connection, session] = values

        # connection is open - test some stuff
        #
        assert.false(session instanceof autobahn.Session, 'session should not be instance of autobahn.Session')
        assert.false(session.isOpen, 'session is not open')

        # close the connection
        #
        Manager.closeConnection(connection)

    ).then((closeReason)->
        # connection is closed - test the reason
        #
        assert.true(closeReason[0]=='closed', 'correct close reason')

        # pause, then close the router
        #
        Manager.pause()

    ).then(()->

        # close the router
        #
        router.close()

    ).catch((err)->
        # we SHOULD get here - the connection closed as soon as it opened due to
        # authentication failure
        #
        assert.true(err[1].reason=='wamp.error.not_authorized', 'got not authorized message')
    ).finally(()->
        # all done, stop testing
        #
        assert.end()

        # signal the manager that we're done
        #
        mgr.end()

    ).done()
)
