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

        # make sure that all the object keys are URIs
        #
        _.forEach(config.realms, (value, key)->
            if not isUri(key)
                throw new TypeError('Invalid realm identifier')
        )







    true

module.exports.validateConfiguration = validateConfiguration
module.exports.isUri = isUri
