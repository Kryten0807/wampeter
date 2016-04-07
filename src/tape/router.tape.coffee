test = require('tape')

autobahn = require('autobahn')

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
mgr.onComplete = ()->
    console.log('---------- tests complete')
    setTimeout((()-> process.exit()), 500)

router = null




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
        console.log('--- closing router')
        router.close()
    ).catch((err)->
        console.log('*************** ERROR', err)
        console.log(err.trace)
    ).finally(()->
        console.log('--- cleaning up tests')
        # all done, stop testing
        #
        assert.end()

        # signal the manager that we're done
        #
        mgr.end()
    ).done()
)



test('Router:Session - should establish a new session and close it', (assert)->

    # signal the start of the test to the manager
    #
    mgr.start()

    router = null

    Manager.createRouter(ROUTER_CONFIG).then((r)->
        router = r

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
        console.log('--- connection closed', closeReason)
        # connection is closed - test the reason
        #
        assert.true(closeReason=='closed', 'correct close reason')

        # pause, then close the router
        #
        Manager.pause()
    ).then(()->
        console.log('--- closing router')
        router.close()
    ).catch((err)->
        console.log('*************** ERROR', err)
        console.log(err.trace)
    ).finally(()->
        console.log('--- cleaning up tests')
        # all done, stop testing
        #
        assert.end()

        # signal the manager that we're done
        #
        mgr.end()
    ).done()

)





test('Router:PubSub - should subscribe to a topic', (assert)->
    # signal the start of the test to the manager
    #
    mgr.start()

    router = wampeter.createRouter(ROUTER_CONFIG)

    connection = new autobahn.Connection({
        realm: config.realm
        url: 'ws://localhost:3000/wampeter'
    })

    connection.onopen = (session)->
        # test the session
        #
        assert.true(session.isOpen, 'session is open')





        ###
        it('should subscribe to a topic', (done_func)->
            done = D(done_func)

            logger.info('try to subscribe')
            expect(session.isOpen).to.be.true
            session.subscribe('com.example.inge', spyEvent)
            .then((s)->
                logger.info('subscribed to topic')
                subscription = s
                done()
            ).catch((err)->
                done(new TypeError(err.stack))
            ).done()
        )
        ###



        # close the connection
        #
        connection.close()

    connection.onclose = (reason)->
        assert.true(reason=='closed', 'correct close reason')

        # pause, then close the router & clean up the test
        #
        setTimeout((()->
            # close the router
            #
            router.close().finally(()->
                assert.end()
                mgr.end()
            ).done()
        ), 500)

    connection.open()

)









###

describe('Router:Publish/Subscribe', ()->

    router = null
    connection = null
    session = null
    subscription = null

    before((done_func)->
        done = D(done_func)

        router = wampeter.createRouter(ROUTER_CONFIG)

        setTimeout((()->
            connection = new autobahn.Connection({
                realm: 'com.to.inge.world'
                url: 'ws://localhost:3000/wampeter'
            })

            connection.onopen = (s)->
                logger.info('router up and session connected');
                session = s
                done()

            connection.open()
        ), CLEANUP_DELAY)
    )

    after((done_func)->
        done = D(done_func)

        connection.close()

        setTimeout((()-> router.close().then(done).catch(done).done()), CLEANUP_DELAY)
    )

    onevent = (args, kwargs, details)->
        logger.info('on event')
        expect(args).to.be.ok
        expect(kwargs).to.be.ok
        expect(details).to.be.ok

    spyEvent = chai.spy(onevent)

    it('should subscribe to a topic', (done_func)->
        done = D(done_func)

        logger.info('try to subscribe')
        expect(session.isOpen).to.be.true
        session.subscribe('com.example.inge', spyEvent)
        .then((s)->
            logger.info('subscribed to topic')
            subscription = s
            done()
        ).catch((err)->
            done(new TypeError(err.stack))
        ).done()
    )

    it('should publish to a topic', (done_func)->
        done = D(done_func)

        expect(session.isOpen).to.be.true
        session.publish(
            'com.example.inge',
            ['hello inge!'],
            {to: 'inge'},
            {acknowledge: true}
        ).then((published)->
            expect(published).to.have.property('id')
        ).catch((err)->
            done(new Error(err.stack))
        ).done()

        setTimeout((()->
            expect(spyEvent).to.have.been.called.once;
            done();
        ), 500)
    )

    it('should unsubscribe from a topic', (done_func)->
        done = D(done_func)

        expect(session.isOpen).to.be.true
        session.unsubscribe(subscription).then(()->
            done()
        ).catch((err)->
            done(new Error(err.stack))
        ).done()
    )
)
###
