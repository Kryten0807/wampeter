
# Wampeter

This is a rewrite of the [Nightlife-Rabbit](https://github.com/christian-raedel/nightlife-rabbit)
project with two goals: first, to translate it into Coffeescript (because I
prefer CS to plain old Javascript), and second, to implement some of the
advanced WAMP features (specifically authentication, which I need for a project
I'm working on).

## What's with the name?

The term *wampeter* comes from
[Kurt Vonnegut](https://en.wikipedia.org/wiki/Kurt_Vonnegut)'s novel
[*Cat's Cradle*](https://en.wikipedia.org/wiki/Cat%27s_Cradle). It is defined by
the author as "an object around which the lives of many otherwise unrelated
people may revolve."


# Nightlife-Rabbit

A [WAMP](http://wamp.ws)-Router implementation for [node.js](http://nodejs.org).
At the moment, WAMP basic profile in the roles of dealer and broker are supported.
For client connections: publish/subscribe and remote procedure register/call,
[AutobahnJS](http://autobahn.ws/js) can be used.

## Install

```
npm install --save git+https://github.com/christian-raedel/nightlife-rabbit
```

## Basic Usage

``` Javascript
var http       = require('http')
    , CLogger  = require('node-clogger');

var nightlife  = require('nightlife')
    , autobahn = require('autobahn');

// Create a new router with given options. In this example, the options are the
// default values.
var router = nightlife.createRouter({
    httpServer: http.createServer(),                    // Nodes http or https server can be used.
                                                        // httpServer.listen() will be called from
                                                        // within router constructor.

    port: 3000,                                         // The url for client connections will be:
    path: '/nightlife',                                 // ws://localhost:3000/nightlife.

    autoCreateRealms: true,                             // If set to false, an exception will be thrown
                                                        // on connecting to a non-existent realm.

    logger: new CLogger({name: 'nightlife-router'})     // Must be an instance of 'node-clogger'.
                                                        // See http://github.com/christian-raedel/node-clogger
                                                        // for reference...
});

var client = new autobahn.Connection({
    url: 'ws://localhost:3000/nightlife',
    realm: 'com.example.myapp'
});

client.onopen = function (session) {
    // do pub/sub or some procedure calls...
};

client.open();
```

## Advanced Usage

Please see the examples directory of this repository.
