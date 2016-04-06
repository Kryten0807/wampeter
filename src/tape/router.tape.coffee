test = require('tape')

wampeter  = require('../lib/router')


config = require('../test/router-config')
ROUTER_CONFIG = config.static



router = null

test('Router#constructor - should instantiate a router', (assert)->

    router = wampeter.createRouter(ROUTER_CONFIG)

    assert.true(router instanceof wampeter.Router)
    assert.true(router.roles?)
    assert.true(router.roles.broker?)
    assert.true(router.roles.dealer?)

    router.close().fin(()->
        router = null
        console.log('fin!')
        process.exit()
    ).done()

    assert.end()
)
