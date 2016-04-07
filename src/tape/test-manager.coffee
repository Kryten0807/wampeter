EventEmitter  = require('events').EventEmitter

class TestManager extends EventEmitter
    constructor: ()->
        @count = 0

        @on(
            'start',
            ()=>
                @count++
                console.log("+++ test count incremented #{@count}")
        )

        @on('end', ()=>
            @count--
            console.log("+++ test count decremented #{@count}")

            if @count==0
                @emit('complete')
        )

    start: ()=>
        @emit('start')

    end: ()=>
        @emit('end')


module.exports = TestManager
