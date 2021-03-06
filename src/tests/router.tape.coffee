test = require('tape')
sinon = require('sinon')

autobahn = require('autobahn')
_ = require('lodash')

Manager = require('./test-manager')
TestManager = Manager.TestManager


wampeter  = require('../lib/router')

config = require('./router-config')
ROUTER_CONFIG = config.static

# delete the authentication config - we're not testing that in this suite
#
delete(ROUTER_CONFIG.auth)

# still trying to track down the failure to close after testing
# see https://github.com/substack/tape/issues/216

# instantiate a test manager
#
mgr = new TestManager()

# when the manager signals "tests complete", wait 1/2 secound & exit
#
mgr.onComplete = ()-> Manager.pause().then(()-> process.exit())

router = null



# ------------------------------------------------------------------------------
# Test that the factory method instantiates a router
# ------------------------------------------------------------------------------
test('Router#constructor - should instantiate a router', (assert)->

    # signal the start of the test to the manager
    #
    mgr.start()

    router = null

    Manager.createRouter(ROUTER_CONFIG).then((r)->
        router = r

        assert.true(router instanceof wampeter.Router, 'instance of Router class')
        assert.true(router.roles?, 'roles property exists')
        assert.true(router.roles.broker?, 'roles.broker property exists')
        assert.true(router.roles.dealer?, 'roles.dealer property exists')
    ).then(()->
        router.close()
    ).catch((err)->
        console.log('*************** ERROR', err)
        console.log(err.trace)
    ).finally(()->
        # all done, stop testing
        #
        assert.end()

        # signal the manager that we're done
        #
        mgr.end()
    ).done()
)

# ------------------------------------------------------------------------------
# Test that we can connect to the router and then close the connection
# ------------------------------------------------------------------------------
test('Router:Session - should establish a new session and close it', (assert)->

    # signal the start of the test to the manager
    #
    mgr.start()

    router = null

    Manager.createRouter(ROUTER_CONFIG).then((rtr)->

        # save the router object
        #
        router = rtr

        # open the connection & return the promise to complete the connection
        #
        Manager.openConnection({
            realm: config.realm
            url: 'ws://localhost:3000/wampeter'
        })

    ).then((values)->

        # extract the connection & session values
        #
        [connection, session] = values

        # connection is open - test some stuff
        #
        assert.true(session instanceof autobahn.Session, 'instance of autobahn.Session')
        assert.true(session.isOpen, 'session is open')

        # close the connection
        #
        Manager.closeConnection(connection)

    ).then((closeReason)->

        # connection is closed - test the reason
        #
        assert.true(closeReason=='closed', 'correct close reason')

        # pause, then close the router
        #
        Manager.pause()

    ).then(()->

        # close the router
        #
        router.close()

    ).catch((err)->

        # something went wrong - report the error
        #
        console.log('*************** ERROR', err)
        console.log(err.trace)

    ).finally(()->

        # all done, stop testing
        #
        assert.end()

        # signal the manager that we're done
        #
        mgr.end()

    ).done()
)

# ------------------------------------------------------------------------------
# Test that we can perform all the operations associated with PubSub
# ------------------------------------------------------------------------------
test('Router:PubSub - should subscribe, publish, unsubscribe', (assert)->

    # signal the start of the test to the manager
    #
    mgr.start()

    router = null
    connection = null
    session = null

    subscriptionFunction = null

    topic = 'com.example.inge'
    testValue = _.uniqueId()

    Manager.createRouter(ROUTER_CONFIG).then((rtr)->
        # save the router object
        #
        router = rtr

        Manager.openConnection({
            realm: config.realm
            url: 'ws://localhost:3000/wampeter'
        })

    ).then((values)->

        # extract the connection & session values
        #
        [conn, sess] = values

        # save the connection & session
        #
        connection = conn
        session = sess

        # connection is open - test some stuff
        #
        assert.true(session instanceof autobahn.Session, 'instance of autobahn.Session')
        assert.true(session.isOpen, 'session is open')

        # subscribe to a topic
        #
        subscriptionFunction = sinon.spy()

        session.subscribe(topic, subscriptionFunction)

    ).then((subscription)->

        # test the subscription topic
        #
        assert.true(subscription instanceof autobahn.Subscription, 'the subscription is the correct type')
        assert.true(subscription?, 'the subscription exists')
        assert.true(subscription.topic?, 'the topic exists')
        assert.true(subscription.topic==topic, 'the topic has the correct value')

        # publish the value to the topic
        #
        session.publish(topic, [testValue])

        Manager.pause().then(()->
            # unsubscribe
            #
            session.unsubscribe(subscription)
        ).then(()->
            Manager.pause()
        ).then(()->
            # close the connection
            #
            Manager.closeConnection(connection)
        )

    ).then((closeReason)->

        # connection is closed - test the reason
        #
        assert.true(closeReason=='closed', 'correct close reason')

        # pause, then close the router
        #
        Manager.pause()

    ).then(()->

        # check to ensure the spy event was called exactly once & with the
        # correct arguments
        #
        assert.true(subscriptionFunction.callCount==1, 'the subscription function was called once')
        assert.true(subscriptionFunction.firstCall.args[0][0]=="#{testValue}", 'the correct argument was passed to the subscription')

    ).then(()->
        router.close()
    ).catch((err)->
        console.log('*************** ERROR', err)
        console.log(err.trace)
    ).finally(()->

        # all done, stop testing
        #
        assert.end()

        # signal the manager that we're done
        #
        mgr.end()

    ).done()
)

# ------------------------------------------------------------------------------
# Test that we can perform all the operations associated with remote procedure
# calls
# ------------------------------------------------------------------------------
test('Router:RPC - should register, call, unregister', (assert)->

    # signal the start of the test to the manager
    #
    mgr.start()

    router = null
    connection = null
    session = null

    registeredFunction = null

    registerURI = 'com.example.inge'
    testValue = _.uniqueId()


    Manager.createRouter(ROUTER_CONFIG).then((rtr)->
        # save the router object
        #
        router = rtr

        Manager.openConnection({
            realm: config.realm
            url: 'ws://localhost:3000/wampeter'
        })

    ).then((values)->

        # extract the connection & session values
        #
        [conn, sess] = values

        # save the connection & session
        #
        connection = conn
        session = sess

        # connection is open - test some stuff
        #
        assert.true(session instanceof autobahn.Session, 'instance of autobahn.Session')
        assert.true(session.isOpen, 'session is open')

        # subscribe to a topic
        #
        registeredFunction = sinon.spy()

        session.register(registerURI, registeredFunction)

    ).then((registration)->

        # test the registration
        #
        assert.true(registration instanceof autobahn.Registration, 'the registration is the correct type')
        assert.true(registration?, 'the registration exists')
        assert.true(registration.procedure?, 'the procedure exists')
        assert.true(registration.procedure==registerURI, 'the procedure URI has the correct value')

        # publish the value to the topic
        #
        session.call(registerURI, [testValue])

        Manager.pause().then(()->

            # unsubscribe
            #
            session.unregister(registration)
        ).then(()->
            Manager.pause()
        ).then(()->
            # close the connection
            #
            Manager.closeConnection(connection)
        )

    ).then((closeReason)->

        # connection is closed - test the reason
        #
        assert.true(closeReason=='closed', 'correct close reason')

        # pause, then close the router
        #
        Manager.pause()

    ).then(()->
        # check to ensure the spy event was called exactly once & with the
        # correct arguments
        #
        assert.true(registeredFunction.callCount==1, 'the subscription function was called once')
        assert.true(registeredFunction.firstCall.args[0][0]=="#{testValue}", 'the correct argument was passed to the subscription')
    ).then(()->
        router.close()
    ).catch((err)->
        console.log('*************** ERROR', err)
        console.log(err.trace)
    ).finally(()->

        # all done, stop testing
        #
        assert.end()

        # signal the manager that we're done
        #
        mgr.end()

    ).done()
)
