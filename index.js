var requestAnimationFrame = require('raf');

var Timer = require('./src/Timer.coffee');
var TrainPlatform = require('./src/TrainPlatform.coffee');
var View = require('./src/View.coffee');
var Input = require('./src/Input')

var input = new Input({
    37: 'LEFT',
    38: 'UP',
    39: 'RIGHT',
    40: 'DOWN'
});

var timer = new Timer();
var world = new TrainPlatform(timer.stream, input);
var view = new View(timer.stream, world);

requestAnimationFrame(function (time) {
    var renderer = arguments.callee;

    timer.processTime(time);

    requestAnimationFrame(renderer);
});
