test = require('tape')

helper  = require('../lib/helper')
check = helper.validateConfiguration

# ------------------------------------------------------------------------------
# Ensure that the configuration includes a port value
# ------------------------------------------------------------------------------
test('Minimal config - passes', (assert)->
    config =
        port: 3000

    assert.true(check(config))
    assert.end()
)

test('Minimal config - missing port', (assert)->
    config = {}

    assert.throws((()-> check(config)), /Invalid port number/)
    assert.end()
)

test('Minimal config - invalid port (string)', (assert)->
    config =
        port: 'not a port #'

    assert.throws((()-> check(config)), /Invalid port number/)
    assert.end()
)

test('Minimal config - invalid port (float)', (assert)->
    config =
        port: 1.25

    assert.throws((()-> check(config)), /Invalid port number/)
    assert.end()
)

test('Minimal config - invalid port (negative)', (assert)->
    config =
        port: -3

    assert.throws((()-> check(config)), /Invalid port number/)
    assert.end()
)

test('Minimal config - invalid port (zero)', (assert)->
    config =
        port: 0

    assert.throws((()-> check(config)), /Invalid port number/)
    assert.end()
)

test('Minimal config - invalid port (too big)', (assert)->
    config =
        port: 65536

    assert.throws((()-> check(config)), /Invalid port number/)
    assert.end()
)

# ------------------------------------------------------------------------------
