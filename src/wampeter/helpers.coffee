_ = require('lodash')


isUri = (value)-> /^([0-9a-z_]*\.)*[0-9a-z_]*$/.test(value)

###*
 * Check a number to see if it's a valid port number (ie. an integer in the
 * range [1, 65535])
 *
 * @param  {Mixed} p The value to check
 *
 * @return {Boolean} True if it's a valid port number, false otherwise
###
isValidPort = (p)->
    p? and _.isInteger(p) and 1<=p<=65535

###*
 * Check a string to ensure that it's a valid path
 *
 * @param  {String}  p The string to check
 *
 * @return {Boolean}   True if it's a valid path, false otherwise
###
isValidPath = (p)-> /^(\/[a-z0-9\._-]+)*(\/)?$/i.test(p)

validateConfiguration = (config)->
    if not isValidPort(config.port)
        throw new TypeError('Invalid port number')

    if config.path? and isValidPath(config.path)
        throw new TypeError('Invalid path')

    # validate realms
    #
    if config.realms?
        # must be an object
        #
        if not _.isPlainObject(config.realms)
            throw new TypeError('Invalid realms')

        # make sure that all the realm IDs are URIs and do any validation of
        # details in each realm
        #
        _.forEach(config.realms, (value, key)->
            if not isUri(key)
                throw new TypeError('Invalid realm identifier')

            if value.roles?
                if not _.isPlainObject(value.roles)
                    throw new TypeError('Invalid roles')

                # check the role identifiers & permissions
                #
                _.forEach(value.roles, (v, k)->
                    # check the identifier
                    #
                    if not isUri(k)
                        throw new TypeError('Invalid role')

                    if not _.isPlainObject(v)
                        throw new TypeError('Invalid permissions')
                )
        )

    # validate wampcra config
    #
    if config.wampcra?
        # we must have a type
        #
        if not config.wampcra.type?
            throw new TypeError('Invalid WAMP-CRA configuration - missing type')

        if config.wampcra.type=='static'
            # we must have a list of users
            #
            if not config.wampcra.users?
                throw new TypeError('Invalid WAMP-CRA configuration - missing user list')

            # users must be an object - a hash mapping user ID to parameters
            #
            if not _.isPlainObject(config.wampcra.users)
                throw new TypeError('Invalid WAMP-CRA configuration - invalid user list')

            # validate each user - each one must have a secret and role
            #
            _.forEach(config.wampcra.users, (value, key)->
                # is the value an object? if not, then fail
                #
                if not _.isPlainObject(value)
                    throw new TypeError('Invalid WAMP-CRA configuration - invalid user')

                if not value.secret?
                    throw new TypeError('Invalid WAMP-CRA configuration - missing user secret')

                if not _.isString(value.secret) and not _.isNumber(value.secret)
                    throw new TypeError('Invalid WAMP-CRA configuration - invalid user secret')

                if not value.role?
                    throw new TypeError('Invalid WAMP-CRA configuration - missing user role')

                if not _.isString(value.role) and not _.isNumber(value.role)
                    throw new TypeError('Invalid WAMP-CRA configuration - invalid user role')

            )

        else if config.wampcra.type=='dynamic'
            # we must have an authenticator function
            #
            if not config.wampcra.authenticator?
                throw new TypeError('Invalid WAMP-CRA configuration - missing authenticator')

            if not _.isFunction(config.wampcra.authenticator)
                throw new TypeError('Invalid WAMP-CRA configuration - invalid authenticator')
        else
            throw new TypeError('Invalid WAMP-CRA configuration - invalid type')





    true

module.exports.validateConfiguration = validateConfiguration
module.exports.isUri = isUri
