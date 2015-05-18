vec2 = require('gl-matrix').vec2

module.exports = class TrainCar
  constructor: (@_timerStream, @_physicsWorld) ->
    @_riderList = []

    @_physicsWorld.extrudeLR @_physicsWorld.originCell, 1, 3
    @_physicsWorld.extrudeUD @_physicsWorld.originCell, 4, 5 + 6 * 2 - 1
    @_physicsWorld.extrudeUD @_physicsWorld.originCell, 4, -5

    firstDoorLeftCell = @_physicsWorld.originCell._down._down
    @_physicsWorld.extrudeLR firstDoorLeftCell, 4, -1
    @_physicsWorld.extrudeLR firstDoorLeftCell._right._right._right, 4, 1

    secondDoorLeftCell = firstDoorLeftCell._up._up._up._up._up._up._up._up._up._up._up._up
    @_physicsWorld.extrudeLR secondDoorLeftCell, 4, -1
    @_physicsWorld.extrudeLR secondDoorLeftCell._right._right._right, 4, 1

    @_joltTimer = 0

    @_timerStream.on 'elapsed', (elapsedSeconds) => @_update elapsedSeconds

  addRider: (rider) ->
    if @_riderList.indexOf(rider) isnt -1
      console.log @_riderList, @_riderList.indexOf rider
      throw new Error 'already added'

    @_riderList.push rider

  _update: (elapsed) ->
    @_joltTimer += elapsed
    if @_joltTimer > 1
      @_joltTimer -= 1

      dx = (Math.random() - 0.5) * 0.7
      dy = (Math.random() - 0.5) * 0.05
      dz = (Math.random() - 0.5) * 0.1

      for r in @_riderList
        r.riderSwayVelocity[0] += dx
        r.riderSwayVelocity[1] += dy
        r.riderSwayVelocity[2] += dz
