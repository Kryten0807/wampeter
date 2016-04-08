_ = require('lodash')


isUri = (value)-> /^([0-9a-z_]*\.)*[0-9a-z_]*$/.test(value)


validateConfiguration = (config)->
    if not config?.port? or not _.isNumber(config.port) or config.port<1 or config.port>65535 or Math.floor(config.port)!=config.port
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
