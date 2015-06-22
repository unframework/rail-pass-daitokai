
module.exports = class TrainPlatform
  constructor: (@_timerStream, @_physicsWorld) ->
    @_physicsWorld.extrudeLR @_physicsWorld.originCell, 1, 16 - 1
    cell = @_physicsWorld.extrudeUD @_physicsWorld.originCell, 16, 16 - 1
