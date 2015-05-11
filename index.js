var requestAnimationFrame = require('raf');

var Timer = require('./src/Timer.coffee');
var PhysicsWorld = require('./src/PhysicsWorld.coffee');
var TrainPlatform = require('./src/TrainPlatform.coffee');
var Person = require('./src/Person.coffee')
var View = require('./src/View.coffee');
var Input = require('./src/Input')

var input = new Input({
    37: 'LEFT',
    38: 'UP',
    39: 'RIGHT',
    40: 'DOWN'
});

var timer = new Timer();
var world = new PhysicsWorld(timer.stream, input);
var platform = new TrainPlatform(timer.stream, world);
var personList = [ new Person(timer.stream, input, world._movables[0]) ]
var view = new View(timer.stream, personList, platform);

requestAnimationFrame(function (time) {
    var renderer = arguments.callee;

    timer.processTime(time);
    view.draw();

    requestAnimationFrame(renderer);
});
