global.AUTOBAHN_DEBUG = true;

CLogger  = require('node-clogger')
logger = new CLogger({name: 'router-tests'})

test = require('tape')
sinon = require('sinon')

_ = require('lodash')

wampeter  = require('../lib/router')
autobahn = require('autobahn')

Cfg = require('./router-config')

ROUTER_CONFIG = Cfg.static
REALM_URI =     Cfg.realm
VALID_AUTHID =  Cfg.valid_authid
VALID_SECRET =  Cfg.valid_secret
ROLE =          Cfg.role

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
test('Static Authorization : register & call a procedure', (assert)->

    # signal the start of the test to the manager
    #
    mgr.start()

    router = null
    connection = null

    PROCEDURE = 'com.example.testprocedure'

    arg1 = Math.floor(Math.random()*100)
    arg2 = Math.floor(Math.random()*100)
    expected = arg1 + arg2

    ROUTER_CONFIG.realms[REALM_URI].roles[ROLE] =
        '*':
            call:      true
            register:  true
            subscribe: false
            publish:   false


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

        # attempt to register a function
        #
        f1 = (args)->
            args[0] + args[1]

        f2 = ()->

        session.register(PROCEDURE, f1).then(()->
            session.register(PROCEDURE+'x', f2)
        ).then(()->
            session.call(PROCEDURE, [arg1, arg2])
        )

    ).then((result)->

        assert.true(expected==result, 'got correct result')

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


configuration = []


configuration[0] =
    '*':
        call:      false
        register:  false
        subscribe: false
        publish:   false

configuration[1] =
    '*':
        call:      false
        register:  true
        subscribe: false
        publish:   false
    'com.example.testprocedure':
        call:      false
        register:  false
        subscribe: false
        publish:   false

configuration[2] =
    '*':
        call:      false
        register:  true
        subscribe: false
        publish:   false
    'com.*':
        call:      false
        register:  false
        subscribe: false
        publish:   false

configuration[3] =
    '*':
        call:      false
        register:  true
        subscribe: false
        publish:   false
    'com.*':
        call:      false
        register:  true
        subscribe: false
        publish:   false
    'com.example.*':
        call:      false
        register:  false
        subscribe: false
        publish:   false

configuration[4] =
    '*':
        call:      false
        register:  false
        subscribe: false
        publish:   false
    'com.*':
        call:      false
        register:  false
        subscribe: false
        publish:   false
    'com.example.*':
        call:      false
        register:  false
        subscribe: false
        publish:   false
    'com.example.testprocedure':
        call:      false
        register:  true
        subscribe: false
        publish:   false

configuration[5] =
    '*':
        call:      false
        register:  false
        subscribe: false
        publish:   false
    'com.*':
        call:      false
        register:  true
        subscribe: false
        publish:   false
    'com.example.*':
        call:      false
        register:  false
        subscribe: false
        publish:   false
    'com.example.testprocedure':
        call:      false
        register:  false
        subscribe: false
        publish:   false


((config, idx)->

    # ------------------------------------------------------------------------------
    # Fail
    # ------------------------------------------------------------------------------
    test("Static Authorization : fail to register a procedure #{i}", (assert)->

        # signal the start of the test to the manager
        #
        mgr.start()

        router = null
        connection = null

        PROCEDURE = 'com.example.testprocedure'

        ROUTER_CONFIG.realms[REALM_URI].roles[ROLE] = config

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
            assert.true(session instanceof autobahn.Session, 'session should be instance of autobahn.Session')
            assert.true(session.isOpen, 'session should be open')

            f1 = (args)->
                args[0] + args[1]

            session.register(PROCEDURE, f1)
            .catch((err)->
                # we SHOULD get a "not authorized" error here
                #
                assert.true(err.error == 'wamp.error.not_authorized', 'got not authorized')
            )

        ).then((result)->

            assert.true(_.isUndefined(result), 'no result received')
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

)(c, i) for c, i in configuration
