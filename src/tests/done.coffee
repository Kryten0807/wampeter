
module.exports = (func)->
    self = this
    called = false

    this.trigger = (params)->
        if called
            console.warn('XXXXX done has already been called')
            console.trace()

            return

        func.apply(self, arguments)
        called = true
