# dependencies
#
CLogger         = require('node-clogger')
MessageParser = require('./message-parser')

# the global logger instance
#
logger = null

###*
 * Get the global logger instance, instantiating it if necessary
 *
 * @return {CLogger} The global logger instance
###
module.exports.logger = ()->
    if not logger? or not logger instanceof CLogger
        logger = new CLogger({name: 'wampeter-router'})
    logger

# the global parser instance
#
parser = null

###*
 * Get the global parser instance, instantiating it if necessary
 *
 * @param  {Object} opts The options for the parser
 *
 * @return {MessageParser} The global parser instance
###
module.exports.parser = (opts)->
    if not parser? or not parser instanceof MessageParser
        parser = new MessageParser(opts)

    parser

###*
 * Generate a random ID value
 *
 * @return {Number} A random integer between 0 and 2^53
###
module.exports.randomid = ()-> Math.floor(Math.random() * Math.pow(2, 53))
