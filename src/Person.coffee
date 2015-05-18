vec2 = require('gl-matrix').vec2
vec3 = require('gl-matrix').vec3
color = require('onecolor')

module.exports = class Person
  constructor: (@_timerStream, @_input, @_physicsWorld, cell) ->
    @_movable = @_physicsWorld.createMovable cell

    @color = new color.HSL(Math.random(), 0.8, 0.8).rgb()
    @color2 = @color.hue(0.08, true).lightness(0.7)

    @orientation = 0

    @lastKnownPosition = vec2.create()
    @walkCycle = 0

    @riderSway = vec3.create()
    @riderSwayVelocity = vec3.create()
    @_riderSwayBalanceForce = 1.0 + Math.random() * 2

    @_nd = vec3.create()

    @_timerStream.on 'elapsed', (elapsedSeconds) =>
      @walkCycle = (@walkCycle + vec2.distance(@lastKnownPosition, @_movable.position) * 2) % 1
      vec2.copy @lastKnownPosition, @_movable.position

      @_processRiderPhysics(elapsedSeconds)

      vec2.set @_movable.walk, 0, 0

      if @_input
        walkAccel = 0.1

        if @_input.status.LEFT
          @_movable.walk[0] -= walkAccel
        if @_input.status.RIGHT
          @_movable.walk[0] += walkAccel
        if @_input.status.UP
          @_movable.walk[1] += walkAccel
        if @_input.status.DOWN
          @_movable.walk[1] -= walkAccel

        if @_movable.walk[0] isnt 0 or @_movable.walk[1] isnt 0
          @orientation = Math.atan2 @_movable.walk[1], @_movable.walk[0]

  _processRiderPhysics: (elapsedSeconds) ->
    # apply rider sway velocity
    vec3.scale @_nd, @riderSwayVelocity, elapsedSeconds
    vec3.add @riderSway, @riderSway, @_nd

    # dampen velocity
    delta = vec3.length @riderSwayVelocity

    if delta > 0
      vec3.scale @_nd, @riderSwayVelocity, -Math.min(delta, 0.3 * elapsedSeconds) / delta
      vec3.add @riderSwayVelocity, @riderSwayVelocity, @_nd

    # apply spring-back to velocity (after dampening)
    delta = vec3.length @riderSway

    if delta > 0
      vec3.scale @_nd, @riderSway, -Math.min(delta, @_riderSwayBalanceForce * elapsedSeconds) / delta
      vec3.add @riderSwayVelocity, @riderSwayVelocity, @_nd
