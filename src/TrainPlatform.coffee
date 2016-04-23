
module.exports = class TrainPlatform
  constructor: (@_timerStream, @_physicsWorld) ->
    @_physicsWorld.extrudeLR @_physicsWorld.originCell, 1, 16 - 1
    cell = @_physicsWorld.extrudeUD @_physicsWorld.originCell, 16, 16 - 1

    cell = @_physicsWorld.extrudeLR cell, -2, 4
    cell = @_physicsWorld.extrudeUD cell._down, -2, -4
    @_physicsWorld.extrudeLR cell._left, 2, -3
