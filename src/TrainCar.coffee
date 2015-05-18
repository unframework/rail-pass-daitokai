vec2 = require('gl-matrix').vec2

module.exports = class TrainCar
  constructor: (@_timerStream, @_physicsWorld) ->
    @_physicsWorld.extrudeLR @_physicsWorld.originCell, 1, 3
    cell = @_physicsWorld.extrudeUD @_physicsWorld.originCell, 4, 4 - 1

    @_timerStream.on 'elapsed', (elapsedSeconds) => @_update elapsedSeconds

  _update: (elapsed) ->
