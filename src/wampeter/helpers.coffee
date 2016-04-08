_ = require('lodash')

validateConfiguration = (config)->
    if not config?.port? or not _.isNumber(config.port) or config.port<1 or config.port>65535 or Math.floor(config.port)!=config.port
        throw new TypeError('Invalid port number')

    if config.path?
        if not /^(\/[a-z0-9\._-]+)*(\/)?$/i.test(config.path)
            throw new TypeError('Invalid path')

    true

module.exports.validateConfiguration = validateConfiguration
