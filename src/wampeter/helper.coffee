_ = require('lodash')

validateConfiguration = (config)->
    if not config?.port? or not _.isNumber(config.port) or config.port<1 or config.port>65535 or Math.floor(config.port)!=config.port
        throw new TypeError('Invalid port number')

    true

module.exports.validateConfiguration = validateConfiguration
