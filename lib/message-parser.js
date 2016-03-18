(function() {
  var CConf, MessageParser, _, engine, q,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  CConf = require('node-cconf');

  engine = require('dna').createDNA();

  q = require('q');

  _ = require('lodash');

  MessageParser = (function() {
    function MessageParser(opts, logger) {
      this.logger = logger != null ? logger : null;
      this.decode = bind(this.decode, this);
      this.encode = bind(this.encode, this);
      this.isUri = bind(this.isUri, this);
      this.getTypeKey = bind(this.getTypeKey, this);
      this.config = new CConf('message-parser', ['uriMatching:rules', 'uriMatching:activeRule', 'dictKeyMatchingRules'], {
        'uriMatching': {
          'rules': {
            'simple': /^([0-9a-z_]*\.)*[0-9a-z_]*$/g
          },
          'activeRule': 'uriMatching:rules:simple'
        },
        'dictKeyMatchingRules': [/[a-z][0-9a-z_]{2,}/, /_[0-9a-z_]{3,}/]
      }).load(opts || {});
      engine.use('typekey', (function(_this) {
        return function(value) {
          return _this.getTypeKey(value);
        };
      })(this));
      engine.use('uri', (function(_this) {
        return function(value) {
          if (_this.isUri(value)) {
            return value;
          } else {
            _this.logger.error('invalid URI', value);
            throw new Error('wamp.error.invalid_uri');
          }
        };
      })(this));
      engine.use('dict', (function(_this) {
        return function(value) {
          var rules, valid;
          if (_.isPlainObject(value)) {
            rules = _.map(_this.config.getValue('dictKeyMatchingRules'), function(rule) {
              return new RegExp(rule);
            });
            valid = true;
            _.forOwn(value, function(value, key) {
              return valid = _.reduce(rules, (function(prev, rule) {
                return prev || rule.test(key);
              }), valid);
            });
            if (valid) {
              return value;
            } else {
              throw new Error('wamp.error.invalid_dict_key');
            }
          } else {
            throw new TypeError('wamp.error.invalid_argument');
          }
        };
      })(this));
      engine.use('list', function(value) {
        if (_.isArray(value)) {
          return value;
        } else {
          throw new TypeError('wamp.error.invalid_argument');
        }
      });
      engine.use('id', function(value) {
        if (_.isNumber(value)) {
          return value;
        } else {
          throw new TypeError('wamp.error.invalid_argument');
        }
      });
      engine.use('optional', function(value) {
        if (_.isEqual(value, []) || _.isEqual(value, {})) {
          return void 0;
        } else {
          return value;
        }
      });
      engine.use('string', (function(_this) {
        return function(value) {
          if (_.isString(value)) {
            return value;
          } else {
            throw new Error('wamp.error.invalid_argument');
          }
        };
      })(this));
      engine.onexpression = function(value) {
        var err, error;
        try {
          return JSON.stringify(value);
        } catch (error) {
          err = error;
          throw new TypeError('wamp.error.invalid_argument');
        }
      };
      engine.oncomplete = function(value) {
        return value.replace(/,\ undefined/g, '');
      };
      this.template = engine;
    }

    MessageParser.prototype.TYPES = require('./message-types').TYPES;

    MessageParser.prototype.getTypeKey = function(type) {
      var key;
      if (_.isString(type)) {
        key = _.findKey(this.TYPES, function(t) {
          return t.type === type.toUpperCase();
        });
        if (key != null) {
          return parseInt(key);
        } else {
          throw new Error('wamp.error.no_such_message_type');
        }
      } else {
        throw new TypeError('wamp.error.invalid_argument');
      }
    };

    MessageParser.prototype.isUri = function(uri) {
      var activeRule, pattern;
      activeRule = this.config.getValue('uriMatching:activeRule');
      pattern = this.config.getValue(activeRule);
      if (_.isString(uri)) {
        return new RegExp(pattern).test(uri);
      } else {
        throw new TypeError('wamp.error.invalid_argument');
      }
    };

    MessageParser.prototype.encode = function(type, opts) {
      return q.fcall((function(_this) {
        return function() {
          var key;
          key = _this.getTypeKey(type);
          if (_.isNumber(key) && _.isPlainObject(opts)) {
            opts.type = key;
            return _this.template.render(_this.TYPES[key].encode, opts);
          } else {
            throw new TypeError('wamp.error.invalid_message_type');
          }
        };
      })(this));
    };

    MessageParser.prototype.decode = function(data) {
      return q.fcall((function(_this) {
        return function() {
          var err, error, fn;
          try {
            data = JSON.parse(data);
            if (_.isArray(data)) {
              fn = _this.TYPES[data[0]].decode;
              if (_.isFunction(fn)) {
                return fn.call(_this, data);
              } else {
                throw new Error('wamp.error.invalid_message_type');
              }
            } else {
              throw new TypeError('wamp.error.invalid_message');
            }
          } catch (error) {
            err = error;
            throw new TypeError('wamp.error.invalid_json');
          }
        };
      })(this));
    };

    return MessageParser;

  })();

  module.exports = MessageParser;

}).call(this);
