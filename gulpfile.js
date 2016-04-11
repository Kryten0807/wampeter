var gulp   = require('gulp');

var coffee = require('gulp-coffee');


gulp.task('build', function () {

    // build the library code
    //
    gulp.src('./src/wampeter/**/*.coffee')
        .pipe(coffee({bare: false}))
        .pipe(gulp.dest('./lib'));

    // build the test code
    //
    gulp.src('./src/tests/**/*.coffee')
        .pipe(coffee({bare: false}))
        .pipe(gulp.dest('./test'));

});


gulp.task('watch', function () {
    // watch the source files
    //
    gulp.watch('./src/app/**/*.coffee', ['server']);
});


gulp.task('default', ['build']);
