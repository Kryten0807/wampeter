Q = require('q')
autobahn = require('autobahn')
wampeter  = require('../lib/router')

###*
 * The TestManager class
 *
 * For whatever reason, the tests in my Tape test suites don't exit when
 * finished. It probably has something to do with an unclosed handle of some
 * sort in the Router code (maybe the web socket?). I found some information at
 * https://github.com/substack/tape/issues/216.
 *
 * In any event, it was easier to write a kludge to shut down the tests when
 * they're done than to spend a lot of time tracing the problem. That's what
 * this class does. Call `start()` at the beginning of a test and `end()` at the
 * end. This class maintains a counter which is incremented on test starts and
 * decremented on test ends. When the test ends, it emits the `complete` event -
 * watch for this event and shut down with `process.exit()` when it happens.
###
class TestManager
    constructor: ()->
        # initialize the counter
        #
        @count = 0

        @timer = null

    ###*
     * Record a test start
     *
     * @return {undefined}
    ###
    start: ()=>
        @count++
        console.log("+++ test start #{@count}")

    ###*
     * Record a test end, signalling complete when all tests have finished
     *
     * @return {undefined}
    ###
    end: ()=>
        @count--
        console.log("+++ test end #{@count}")

        if @count==0
            # start a timer to exit
            #
            setTimeout(@_complete, 1000)

    _complete: ()=>
        if @count>0
            console.log('+++ not ready to call onComplete')
            return

        console.log('+++ calling onComplete')
        @onComplete?()




createRouter = (config)->
    Q.fcall(
        ()->
            wampeter.createRouter(config)
    )

openConnection = (config)->
    deferred = Q.defer()

    connection = new autobahn.Connection(config)

    connection.onopen = (session)-> deferred.resolve([connection, session])

    connection.open()

    deferred.promise


closeConnection = (connection)->
    deferred = Q.defer()

    connection.onclose = (reason)-> deferred.resolve(reason)

    connection.close()

    deferred.promise

pause = (timeout = 500)-> Q.delay(timeout)










module.exports.TestManager = TestManager

module.exports.createRouter = createRouter
module.exports.openConnection = openConnection
module.exports.closeConnection = closeConnection
module.exports.pause = pause
