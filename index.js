var requestAnimationFrame = require('raf');

var Timer = require('./src/Timer.coffee');
var PhysicsWorld = require('./src/PhysicsWorld.coffee');
var Train = require('./src/Train.coffee');
var TrainPlatform = require('./src/TrainPlatform.coffee');
var Person = require('./src/Person.coffee');
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
var train = new Train(timer.stream, world);
var personList = [ new Person(timer.stream, input, world, world.originCell) ]
var view = new View(timer.stream, personList, train, platform);

requestAnimationFrame(function (time) {
    var renderer = arguments.callee;

    timer.processTime(time);
    view.draw();

    requestAnimationFrame(renderer);
});
