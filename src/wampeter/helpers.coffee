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


validateConfiguration = (config)->
    if not isValidPort(config.port)
        throw new TypeError('Invalid port number')

    if config.path?
        if not /^(\/[a-z0-9\._-]+)*(\/)?$/i.test(config.path)
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







    true

module.exports.validateConfiguration = validateConfiguration
module.exports.isUri = isUri
