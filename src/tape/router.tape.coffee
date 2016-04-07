test = require('tape')

TestManager = require('./test-manager')
wampeter  = require('../lib/router')

config = require('../test/router-config')
ROUTER_CONFIG = config.static

# still trying to track down the failure to close after testing
# see https://github.com/substack/tape/issues/216

# instantiate a test manager
#
mgr = new TestManager()

# when the manager signals "tests complete", wait 1/2 secound & exit
#
mgr.on('complete', ()->
    console.log('---------- tests complete')
    setTimeout((()-> process.exit()), 500)
)

test('Router#constructor - should instantiate a router', (assert)->
    # signal the start of the test to the manager
    #
    mgr.start()

    router = wampeter.createRouter(ROUTER_CONFIG)

    assert.true(router instanceof wampeter.Router, 'instance of Router class')
    assert.true(router.roles?, 'roles property exists')
    assert.true(router.roles.broker?, 'roles.broker property exists')
    assert.true(router.roles.dealer?, 'roles.dealer property exists')

    router.close().fin(()->
        # signal the end of the test to the manager
        #
        mgr.end()

        # end the test
        #
        assert.end()
    ).done()
)
