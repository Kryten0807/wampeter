test = require('tape')

autobahn = require('autobahn')

TestManager = require('./test-manager')
wampeter  = require('../lib/router')

config = require('./router-config')
ROUTER_CONFIG = config.static

# delete the authentication config - we're not testing that in this suite
#
delete(ROUTER_CONFIG.auth)

# still trying to track down the failure to close after testing
# see https://github.com/substack/tape/issues/216

# instantiate a test manager
#
mgr = new TestManager()

# when the manager signals "tests complete", wait 1/2 secound & exit
#
mgr.onComplete = ()->
    console.log('---------- tests complete')
    setTimeout((()-> process.exit()), 500)

router = null




test('Router#constructor - should instantiate a router', (assert)->
    # signal the start of the test to the manager
    #
    mgr.start()

    router = wampeter.createRouter(ROUTER_CONFIG)

    assert.true(router instanceof wampeter.Router, 'instance of Router class')
    assert.true(router.roles?, 'roles property exists')
    assert.true(router.roles.broker?, 'roles.broker property exists')
    assert.true(router.roles.dealer?, 'roles.dealer property exists')

    router.close().finally(()->
        # signal the end of the test to the manager
        #
        mgr.end()

        # end the test
        #
        assert.end()
    ).done()
)



test('Router:Session - should establish a new session and close it', (assert)->
    # signal the start of the test to the manager
    #
    mgr.start()

    router = wampeter.createRouter(ROUTER_CONFIG)

    connection = new autobahn.Connection({
        realm: config.realm
        url: 'ws://localhost:3000/wampeter'
    })

    connection.onopen = (session)->
        # test the session
        #
        assert.true(session instanceof autobahn.Session, 'instance of autobahn.Session')
        assert.true(session.isOpen, 'session is open')

        # close the connection
        #
        connection.close()

    connection.onclose = (reason)->
        assert.true(reason=='closed', 'correct close reason')

        # pause, then close the router & clean up the test
        #
        setTimeout((()->
            # close the router
            #
            router.close().finally(()->
                assert.end()
                mgr.end()
            ).done()
        ), 500)

    connection.open()
)
