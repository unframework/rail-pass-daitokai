
PhysicsWorld = require('./PhysicsWorld.coffee')

module.exports = class TrainPlatform
    constructor: (@_timerStream, input) ->
        @_physicsWorld = new PhysicsWorld(@_timerStream, input)
