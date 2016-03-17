var gulp   = require('gulp');

var coffee = require('gulp-coffee');


gulp.task('build', function () {
    gulp.src('./src/wampeter/**/*.coffee')
        .pipe(coffee({bare: false}))
        .pipe(gulp.dest('./lib'));
});


gulp.task('watch', function () {
    // watch the source files
    //
    gulp.watch('./src/app/**/*.coffee', ['server']);
});


gulp.task('default', ['build']);
