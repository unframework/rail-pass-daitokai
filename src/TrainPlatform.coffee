
module.exports = class TrainPlatform
  constructor: (@_timerStream, @_physicsWorld) ->
    @_physicsWorld.extrudeLR @_physicsWorld.originCell, 1, 3
    cell = @_physicsWorld.extrudeUD @_physicsWorld.originCell, 4, 12 - 1
