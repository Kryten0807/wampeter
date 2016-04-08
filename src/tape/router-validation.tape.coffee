test = require('tape')

helpers  = require('../lib/helpers')
check = helpers.validateConfiguration

# ------------------------------------------------------------------------------
# Ensure that the configuration includes a port value
# - must be an integer in the range [1, 65535]
# ------------------------------------------------------------------------------
test('Minimal config', (assert)->

    config =
        port: 3000
    assert.true(check(config), 'valid port')


    config = {}
    assert.throws((()-> check(config)), /Invalid port number/)


    config =
        port: 'not a port #'
    assert.throws((()-> check(config)), /Invalid port number/, 'invalid port (string)')


    config =
        port: 1.25
    assert.throws((()-> check(config)), /Invalid port number/, 'invalid port (float)')


    config =
        port: -3
    assert.throws((()-> check(config)), /Invalid port number/, 'invalid port (negative)')


    config =
        port: 0
    assert.throws((()-> check(config)), /Invalid port number/, 'invalid port (zero)')


    config =
        port: 65536
    assert.throws((()-> check(config)), /Invalid port number/, 'invalid port (too big)')

    assert.end()
)

# ------------------------------------------------------------------------------
# Ensure that the (optional) path value is valid
# - must be a fragment of a path, starting with `/`
# ------------------------------------------------------------------------------
test('Path config - passes', (assert)->
    config =
        port: 3000

    assert.true(check(config), 'missing path')

    config.path = ''
    assert.true(check(config), 'empty path')

    config.path = '/test'
    assert.true(check(config), 'simple path')

    config.path = 'test'
    assert.throws((()-> check(config)), /Invalid path/, 'missing leading slash')

    config.path = '//'
    assert.throws((()-> check(config)), /Invalid path/, 'multiple adjacent slashes')

    config.path = 3.14159
    assert.throws((()-> check(config)), /Invalid path/, 'number')

    config.path = {a: 1}
    assert.throws((()-> check(config)), /Invalid path/, 'object')

    config.path = [1, 2, 3]
    assert.throws((()-> check(config)), /Invalid path/, 'array')

    assert.end()
)
