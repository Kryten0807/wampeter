test = require('tape')

autobahn = require('autobahn')

TestManager = require('./test-manager')
wampeter  = require('../lib/router')

config = require('../test/router-config')
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
mgr.on('complete', ()->
    console.log('---------- tests complete')
    setTimeout((()-> process.exit()), 500)
)

test('Router#constructor - should instantiate a router', (assert)->
    # signal the start of the test to the manager
    #
    mgr.start()

    router = wampeter.createRouter(ROUTER_CONFIG)

    assert.true(router instanceof wampeter.Router, 'instance of Router class')
    assert.true(router.roles?, 'roles property exists')
    assert.true(router.roles.broker?, 'roles.broker property exists')
    assert.true(router.roles.dealer?, 'roles.dealer property exists')

    router.close().finally(()->
        # signal the end of the test to the manager
        #
        mgr.end()

        # end the test
        #
        assert.end()
    ).done()
)



test('Router:Session - should establish a new session', (assert)->
    # signal the start of the test to the manager
    #
    mgr.start()

    router = wampeter.createRouter(ROUTER_CONFIG)

    connection = new autobahn.Connection({
        realm: config.realm
        url: 'ws://localhost:3000/wampeter'
    })

    connection.onopen = (session)->
        assert.true(session instanceof autobahn.Session, 'isntance of autobahn.Session')
        assert.true(session.isOpen, 'session is open')

        # close the router
        #
        router.close().finally(()->
            mgr.end()
            assert.end()
        ).done()

    connection.open()
)

###

describe('Router:Session', ()->

    router = null
    connection = null
    session = null

    before((done_func)->
        done = D(done_func)

        router = wampeter.createRouter(ROUTER_CONFIG)

        setTimeout((()-> done()), CLEANUP_DELAY)
    )

    after((done_func)->
        done = D(done_func)

        setTimeout((()-> router.close().then(done).catch(done).done()), CLEANUP_DELAY)
    )

    it('should establish a new session', (done_func)->
        done = D(done_func)

        connection = new autobahn.Connection({
            realm: 'com.to.inge.world'
            url: 'ws://localhost:3000/wampeter'
        })

        connection.onopen = (s)->
            expect(s).to.be.an.instanceof(autobahn.Session)
            expect(s.isOpen).to.be.true
            session = s
            done()

        connection.open()
    )

    it('should close a session', (done_func)->
        done = D(done_func)

        expect(connection).to.be.an.instanceof(autobahn.Connection)

        connection.onclose = (reason)->
            expect(reason).to.be.equal('closed')
            done()

        connection.close()
    )
)
###
