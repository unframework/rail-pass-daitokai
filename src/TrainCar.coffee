vec2 = require('gl-matrix').vec2

module.exports = class TrainCar
  constructor: (@_timerStream, @_physicsWorld) ->
    @_riderList = []

    @_physicsWorld.extrudeLR @_physicsWorld.originCell, 1, 3
    cell = @_physicsWorld.extrudeUD @_physicsWorld.originCell, 4, 6 * 2 - 1

    @_joltTimer = 0

    @_timerStream.on 'elapsed', (elapsedSeconds) => @_update elapsedSeconds

  addRider: (rider) ->
    if @_riderList.indexOf(rider) isnt -1
      console.log @_riderList, @_riderList.indexOf rider
      throw new Error 'already added'

    @_riderList.push rider

  _update: (elapsed) ->
    @_joltTimer += elapsed
    if @_joltTimer > 2
      @_joltTimer -= 2

      dx = (Math.random() - 0.5) * 1
      dy = (Math.random() - 0.5) * 1
      dz = (Math.random() - 0.5) * 0.5

      for r in @_riderList
        r.riderSwayVelocity[0] += dx
        r.riderSwayVelocity[1] += dy
        r.riderSwayVelocity[2] += dz
