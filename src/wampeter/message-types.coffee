deep = require('node-cconf').util.deep
_ = require('lodash')



class Message
    constructor: (data)->
        @obj =
            type: TYPES[data[0]].type

        @data = data
        @cursor = 0

    set: (path)=>
        value = @data[++@cursor]

        if path.match(/kwargs/) and not value?
            value = {}
        else if path.match(/args/) and not value?
            value = []

        if value?
            @obj = _.merge(@obj, deep.set(path, value))

        return @

    get: ()-> @.obj

module.exports.Message = Message


TYPES =
    1  :
        type   : 'HELLO',
        encode : '[{{type}}, {{realm|uri}}, {{details|dict}}]',
        decode : (data)->
            return new Message(data).set('realm').set('details').get()

    2  :
        type   : 'WELCOME',
        encode : '[{{type}}, {{session.id|id}}, {{details|dict}}]',
        decode : (data)->
            return new Message(data).set('session.id').set('details').get()

    3  :
        type   : 'ABORT',
        encode : '[{{type}}, {{details|dict}}, {{reason|uri}}]',
        decode : (data)->
            return new Message(data).set('details').set('reason').get()

    4  :
        type   : 'CHALLENGE',
        encode : '[{{type}}, {{authmethod|string}}, {{extra|dict}}]',
        decode : (data)->
            return new Message(data).set('authmethod').set('extra').get()
    # 4  :
    #     type   : 'CHALLENGE',
    #     encode : '[{{type}}, ]',
    #     decode : (data)->
    #         throw new Error('Advanced profile is not implemented yet!')

    5  :
        type   : 'AUTHENTICATE' ,
        encode : '[{{type}}, {{signature|string}}, {{extra|dict}}]',
        decode : (data)->
            return new Message(data).set('signature').set('extra').get()
    # 5  :
    #     type   : 'AUTHENTICATE' ,
    #     encode : '[{{type}}, ]',
    #     decode : (data)->
    #         throw new Error('Advanced profile is not implemented yet!')

    6  :
        type   : 'GOODBYE',
        encode : '[{{type}}, {{details|dict}}, {{reason|uri}}]',
        decode : (data)->
            return new Message(data).set('details').set('reason').get()

    7  :
        type   : 'HEARTBEAT',
        encode : '[{{type}}, ]',
        decode : (data)->
            throw new Error('Advanced profile is not implemented yet!')

    8  :
        type   : 'ERROR',
        encode : '[{{type}}, {{request.type|typekey}}, {{request.id|id}}, {{details|dict}}, {{error|uri}}, {{args|list|optional}}, {{kwargs|dict|optional}}]',
        decode : (data)->
            return new Message(data).set('request.type').set('request.id').set('details').set('error').set('args').set('kwargs').get()


    16 :
        type   : 'PUBLISH',
        encode : '[{{type}}, {{request.id|id}}, {{options|dict}}, {{topic|uri}}, {{args|list|optional}}, {{kwargs|dict|optional}}]',
        decode : (data)->
            return new Message(data).set('request.id').set('options').set('topic').set('args').set('kwargs').get()

    17 :
        type   : 'PUBLISHED',
        encode : '[{{type}}, {{publish.request.id|id}}, {{publication.id|id}}]',
        decode : (data)->
            return new Message(data).set('publish.request.id').set('publication.id').get()


    32 :
        type   : 'SUBSCRIBE',
        encode : '[{{type}}, {{request.id|id}}, {{options|dict}}, {{topic|uri}}]',
        decode : (data)->
            return new Message(data).set('request.id').set('options').set('topic').get()

    33 :
        type   : 'SUBSCRIBED',
        encode : '[{{type}}, {{subscribe.request.id|id}}, {{subscription.id|id}}]',
        decode : (data)->
            return new Message(data).set('subscribe.request.id').set('subscription.id').get()

    34 :
        type   : 'UNSUBSCRIBE',
        encode : '[{{type}}, {{request.id|id}}, {{subscribed.subscription.id|id}}]',
        decode : (data)->
            return new Message(data).set('request.id').set('subscribed.subscription.id').get()

    35 :
        type: 'UNSUBSCRIBED' ,
        encode: '[{{type}}, {{unsubscribe.request.id|id}}]',
        decode: (data)->
            return new Message(data).set('unsubscribe.request.id').get()

    36 :
        type: 'EVENT',
        encode: '[{{type}}, {{subscribed.subscription.id|id}}, {{published.publication.id|id}}, {{details|dict}}, {{publish.args|list|optional}}, {{publish.kwargs|dict|optional}}]',
        decode: (data)->
            return new Message(data).set('subscribed.subscription.id').set('published.publication.id')
            .set('details').set('publish.args').set('publish.kwargs').get()


    48 :
        type: 'CALL',
        encode: '[{{type}}, {{request.id|id}}, {{options|dict}}, {{procedure|uri}}, {{args|list|optional}}, {{kwargs|dict|optional}}]',
        decode: (data)->
            return new Message(data).set('request.id').set('options').set('procedure').set('args').set('kwargs').get()

    49 :
        type: 'CANCEL',
        encode: '[{{type}}, ]',
        decode: (data)->
            throw new Error('Advanced profile is not implemented yet!')

    50 :
        type: 'RESULT',
        encode: '[{{type}}, {{call.request.id|id}}, {{options|dict}}, {{yield.args|list|optional}}, {{yield.kwargs|dict|optional}}]',
        decode: (data)->
            return new Message(data).set('call.request.id').set('options').set('yield.args').set('yield.kwargs').get()


    64 :
        type: 'REGISTER',
        encode: '[{{type}}, {{request.id|id}}, {{options|dict}}, {{procedure|uri}}]',
        decode: (data)->
            return new Message(data).set('request.id').set('options').set('procedure').get()

    65 :
        type: 'REGISTERED',
        encode: '[{{type}}, {{register.request.id|id}}, {{registration.id|id}}]',
        decode: (data)->
            return new Message(data).set('register.request.id').set('registration.id').get()

    66 :
        type: 'UNREGISTER',
        encode: '[{{type}}, {{request.id|id}}, {{registered.registration.id|id}}]',
        decode: (data)->
            return new Message(data).set('request.id').set('registered.registration.id').get()

    67 :
        type: 'UNREGISTERED' ,
        encode: '[{{type}}, {{unregister.request.id|id}}]',
        decode: (data)->
            return new Message(data).set('unregister.request.id').get()

    68 :
        type: 'INVOCATION',
        encode: '[{{type}}, {{request.id|id}}, {{registered.registration.id|id}}, {{details|dict}}, {{call.args|list|optional}}, {{call.kwargs|dict|optional}}]',
        decode: (data)->
            return new Message(data).set('request.id').set('registered.registration.id').set('details').set('call.args').set('call.kwargs').get()

    69 :
        type: 'INTERRUPT',
        encode: '[{{type}}, ]',
        decode: (data)->
            throw new Error('Advanced profile is not implemented yet!')

    70 :
        type: 'YIELD',
        encode: '[{{type}}, {{invocation.request.id|id}}, {{options|dict}}, {{args|list|optional}}, {{kwargs|dict|optional}}]',
        decode: (data)->
            return new Message(data).set('invocation.request.id').set('options').set('args').set('kwargs').get()


module.exports.TYPES = TYPES;
