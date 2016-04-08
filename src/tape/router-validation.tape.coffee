test = require('tape')

helpers  = require('../lib/helpers')
check = helpers.validateConfiguration

# ------------------------------------------------------------------------------
# Ensure that the configuration includes a port value
# - must be an integer in the range [1, 65535]
# ------------------------------------------------------------------------------
test('Port configuration', (assert)->

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
test('Path configuration', (assert)->
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




# ------------------------------------------------------------------------------
# Ensure that realms configuration is valid
# ------------------------------------------------------------------------------
test('Realms configuration', (assert)->

    samplePermissions =
        call: true
        register: false
        subscribe: true
        publish: false


    config =
        port: 3000

    assert.true(check(config), 'missing realms')

    config.realms = {}
    assert.true(check(config), 'empty realms')

    config.realms =
        'com.realms.myrealm':
            roles: {}
    assert.true(check(config), 'valid realm, empty roles')

    config.realms =
        'com.realms.myrealm':
            roles: {}
    assert.true(check(config), 'valid realm, empty roles')

    config.realms =
        'com.realms.myrealm':
            roles:
                'role_1': {}
    assert.true(check(config), 'valid realm, single role, no permissions')

    config.realms =
        'com.realms.myrealm':
            roles:
                'role_1': {}
                'role_2': {}
    assert.true(check(config), 'valid realm, multiple roles, no permissions')

    config.realms =
        'com.realms.myrealm':
            roles:
                'role_1': samplePermissions
    assert.true(check(config), 'valid realm, single role, with permissions')

    config.realms =
        'com.realms.myrealm':
            roles:
                'role_1': samplePermissions
                'role_2': samplePermissions
    assert.true(check(config), 'valid realm, multiple roles, with permissions')

    config.realms =
        'com.realms.first':
            roles:
                'role_1': samplePermissions
                'role_2': samplePermissions
        'com.realms.second':
            roles:
                'role_3': samplePermissions
                'role_4': samplePermissions
    assert.true(check(config), 'multiple realms, multiple roles, with permissions')


    config.realms = 42
    assert.throws((()-> check(config)), /Invalid realms/, 'invalid realms - number')

    config.realms = 'this should be an object'
    assert.throws((()-> check(config)), /Invalid realms/, 'invalid realms - string')

    config.realms = ['this should be an object']
    assert.throws((()-> check(config)), /Invalid realms/, 'invalid realms - array')



    config.realms =
        'this_is_+_not_a_uri':
            roles:
                'role_1': samplePermissions
    assert.throws((()-> check(config)), /Invalid realm/, 'invalid realm identifier')

    config.realms =
        'com.realms.first':
            roles:
                'role_1': samplePermissions
        'some other realm that is not valid':
            roles:
                'role_3': samplePermissions
        'com.realms.second':
            roles:
                'role_4': samplePermissions
    assert.throws((()-> check(config)), /Invalid realm/, 'invalid realm identifier with multiple realms')

    config.realms =
        'com.realms.myrealm':
            roles: 42
    assert.throws((()-> check(config)), /Invalid roles/, 'invalid roles - number')

    config.realms =
        'com.realms.myrealm':
            roles: 'this is a string'
    assert.throws((()-> check(config)), /Invalid roles/, 'invalid roles - string')

    config.realms =
        'com.realms.myrealm':
            roles: [1,2,3]
    assert.throws((()-> check(config)), /Invalid roles/, 'invalid roles - array')

    config.realms =
        'com.realms.myrealm':
            roles:
                'this is not a valid role': samplePermissions
    assert.throws((()-> check(config)), /Invalid role/, 'invalid role identifier')

    config.realms =
        'com.realms.myrealm':
            roles:
                'myrole': 42
    assert.throws((()-> check(config)), /Invalid permissions/, 'invalid permissions - number')

    config.realms =
        'com.realms.myrealm':
            roles:
                'myrole': 'a string'
    assert.throws((()-> check(config)), /Invalid permissions/, 'invalid permissions - string')

    config.realms =
        'com.realms.myrealm':
            roles:
                'myrole': ['an', 'array']
    assert.throws((()-> check(config)), /Invalid permissions/, 'invalid permissions - array')

    assert.end()
)
