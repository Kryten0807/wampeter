(function() {
  module.exports = function(func) {
    var called, self;
    self = this;
    called = false;
    return this.trigger = function(params) {
      if (called) {
        console.warn('XXXXX done has already been called');
        console.trace();
        return;
      }
      func.apply(self, arguments);
      return called = true;
    };
  };

}).call(this);
