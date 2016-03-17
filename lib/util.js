(function() {
  var CLogger, MessageParser, logger, parser;

  CLogger = require('node-clogger');

  MessageParser = require('./message-parser');

  logger = null;


  /**
   * Get the global logger instance, instantiating it if necessary
   *
   * @return {CLogger} The global logger instance
   */

  module.exports.logger = function() {
    if ((logger == null) || !logger instanceof CLogger) {
      logger = new CLogger({
        name: 'wampeter-router'
      });
    }
    return logger;
  };

  parser = null;


  /**
   * Get the global parser instance, instantiating it if necessary
   *
   * @param  {Object} opts The options for the parser
   *
   * @return {MessageParser} The global parser instance
   */

  module.exports.parser = function(opts) {
    if ((parser == null) || !parser instanceof MessageParser) {
      parser = new MessageParser(opts);
    }
    return parser;
  };


  /**
   * Generate a random ID value
   *
   * @return {Number} A random integer between 0 and 2^53
   */

  module.exports.randomid = function() {
    return Math.floor(Math.random() * Math.pow(2, 53));
  };

}).call(this);
