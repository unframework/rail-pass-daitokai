var requestAnimationFrame = require('raf');
var vec2 = require('gl-matrix').vec2;

var Timer = require('./src/Timer.coffee');
var PhysicsWorld = require('./src/PhysicsWorld.coffee');
var Person = require('./src/Person.coffee');
var TrainCar = require('./src/TrainCar.coffee');
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
var car = new TrainCar(timer.stream, world);
var personList = [ new Person(timer.stream, input, world, world.originCell, personList) ];
var view = new TrainView(timer.stream, personList);

while(personList.length < 30) {
    personList.push(new Person(timer.stream, null, world, world.originCell, personList));
    personList[personList.length - 1].orientation = (Math.random() - 0.5) * Math.PI * 2;
    world.updateMovablePosition(personList[personList.length - 1]._movable, vec2.fromValues(Math.random() * 1.5, Math.random() * 9.5 - 2.5))
}

personList.forEach(function (p) {
    car.addRider(p);
});

requestAnimationFrame(function (time) {
    timer.processTime(time);
    if (view.isReady) {
        view.draw();
    }

    requestAnimationFrame(arguments.callee);
});
