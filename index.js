var requestAnimationFrame = require('raf');

requestAnimationFrame(function (time) {
    var renderer = arguments.callee;
    var lastTime = renderer.lastTime || time;

    var elapsedSeconds = Math.min(100, time - lastTime) / 1000; // limit to 100ms jitter

    renderer.lastTime = time;

    // console.log(elapsedSeconds);

    requestAnimationFrame(renderer);
});
