var requestAnimationFrame = require('raf');

var Timer = require('./src/Timer.coffee');
var PhysicsWorld = require('./src/PhysicsWorld.coffee');
var Person = require('./src/Person.coffee');
var TrainView = require('./src/TrainView.coffee');
var Input = require('./src/Input')

var input = new Input({
    37: 'LEFT',
    38: 'UP',
    39: 'RIGHT',
    40: 'DOWN'
});

var timer = new Timer();
var world = new PhysicsWorld(timer.stream, input);
var personList = [ new Person(timer.stream, input, world, world.originCell) ]
var view = new TrainView(timer.stream, personList);

requestAnimationFrame(function (time) {
    timer.processTime(time);
    view.draw();

    requestAnimationFrame(arguments.callee);
});
