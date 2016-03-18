# dependencies
#
CConf  = require('node-cconf')
engine = require('dna').createDNA()
q      = require('q')
_      = require('lodash')

class MessageParser
    constructor: (opts, @logger = null)->
        @config = new CConf(
            'message-parser',
            [
                'uriMatching:rules',
                'uriMatching:activeRule',
                'dictKeyMatchingRules'
            ],
            {
                'uriMatching': {
                    'rules': {
                        'simple': /^([0-9a-z_]*\.)*[0-9a-z_]*$/g
                    },
                    'activeRule': 'uriMatching:rules:simple'
                },
                'dictKeyMatchingRules': [
                    /[a-z][0-9a-z_]{2,}/,
                    /_[0-9a-z_]{3,}/
                ]
            }
        ).load(opts || {})

        engine.use('typekey', (value)=> @getTypeKey(value))

        engine.use('uri', (value)=>
            if @isUri(value)
                value
            else
                throw new Error('wamp.error.invalid_uri')
        )

        engine.use('dict', (value)=>
            if _.isPlainObject(value)
                rules = _.map(
                    @config.getValue('dictKeyMatchingRules'), (rule)-> new RegExp(rule)
                )

                valid = true
                _.forOwn(value, (value, key)->
                    valid = _.reduce(rules, ((prev, rule)-> prev or rule.test(key))
                    , valid)
                )

                if valid
                    return value
                else
                    throw new Error('wamp.error.invalid_dict_key')
            else
                throw new TypeError('wamp.error.invalid_argument')
        )

        engine.use('list', (value)->
            if _.isArray(value)
                return value
            else
                throw new TypeError('wamp.error.invalid_argument')
        )

        engine.use('id', (value)->
            if _.isNumber(value)
                return value
            else
                throw new TypeError('wamp.error.invalid_argument')
        )

        engine.use('optional', (value)->
            if _.isEqual(value, []) or _.isEqual(value, {})
                return undefined
            else
                return value
        )

        engine.use('string', (value)=>
            if _.isString(value)
                value
            else
                throw new Error('wamp.error.invalid_argument')
        )


        engine.onexpression = (value)->
            try
                return JSON.stringify(value)
            catch err
                throw new TypeError('wamp.error.invalid_argument')

        engine.oncomplete = (value)-> value.replace(/,\ undefined/g, '')

        @template = engine


    TYPES: require('./message-types').TYPES


    getTypeKey: (type)=>
        if _.isString(type)
            key = _.findKey(@TYPES, (t)-> t.type==type.toUpperCase())

            if key?
                return parseInt(key)
            else
                throw new Error('wamp.error.no_such_message_type')
        else
            throw new TypeError('wamp.error.invalid_argument')

    isUri: (uri)=>
        activeRule = @config.getValue('uriMatching:activeRule')
        pattern = @config.getValue(activeRule)

        if _.isString(uri)
            return new RegExp(pattern).test(uri)
        else
            throw new TypeError('wamp.error.invalid_argument')

    encode: (type, opts)=>
        q.fcall(()=>
            key = @getTypeKey(type)

            if _.isNumber(key) and _.isPlainObject(opts)
                opts.type = key
                @template.render(@TYPES[key].encode, opts)
            else
                throw new TypeError('wamp.error.invalid_message_type')
        )

    decode: (data)=>
        q.fcall(()=>
            try
                data = JSON.parse(data);

                if _.isArray(data)
                    fn = @TYPES[data[0]].decode

                    if _.isFunction(fn)
                        return fn.call(@, data)
                    else
                        throw new Error('wamp.error.invalid_message_type')

                else
                    throw new TypeError('wamp.error.invalid_message')

            catch err
                throw new TypeError('wamp.error.invalid_json')
        )


module.exports = MessageParser
