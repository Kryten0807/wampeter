# dependencies
#
EventEmitter  = require('events').EventEmitter

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
class TestManager extends EventEmitter
    constructor: ()->
        # initialize the counter
        #
        @count = 0

    ###*
     * Record a test start
     *
     * @return {undefined}
    ###
    start: ()=> @count++

    ###*
     * Record a test end, signalling complete when all tests have finished
     *
     * @return {undefined}
    ###
    end: ()=>
        @count--

        if @count==0
            @emit('complete')

# export the class
#
module.exports = TestManager
