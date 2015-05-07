var requestAnimationFrame = require('raf');

var PhysicsWorld = require('./src/PhysicsWorld.coffee');
var View = require('./src/View.coffee');
var Input = require('./src/Input')

var input = new Input({
    38: 'FORWARD',
    40: 'BACKWARD'
});

var world = new PhysicsWorld(input);
var view = new View(world);

requestAnimationFrame(function (time) {
    var renderer = arguments.callee;
    var lastTime = renderer.lastTime || time;

    var elapsedSeconds = Math.min(100, time - lastTime) / 1000; // limit to 100ms jitter

    renderer.lastTime = time;

    world.update(elapsedSeconds);
    view.render();

    requestAnimationFrame(renderer);
});
