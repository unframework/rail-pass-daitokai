vec2 = require('gl-matrix').vec2
vec3 = require('gl-matrix').vec3
color = require('onecolor')

module.exports = class Person
  constructor: (@_timerStream, @_input, @_physicsWorld, cell, @_personList) ->
    @_movable = @_physicsWorld.createMovable cell

    @height = 1.50 + Math.random() * 0.25
    @color = new color.HSL(Math.random(), 0.8, 0.8).rgb()
    @color2 = @color.hue(0.08, true).lightness(0.7)

    @orientation = 0

    @lastKnownPosition = vec2.create()
    @walkCycle = 0

    @riderSway = vec3.create()
    @riderSwayVelocity = vec3.create()
    @_riderSwayBalanceForce = 2.0 + Math.random() * 2

    @_nd = vec3.create()
    @_tmpV2 = vec2.create()

    @_directionTimer = 0
    @_walkTarget = vec2.clone @_movable.position

    @_timerStream.on 'elapsed', (elapsedSeconds) => @_update elapsedSeconds

  _update: (elapsedSeconds) ->
    @walkCycle = (@walkCycle + vec2.distance(@lastKnownPosition, @_movable.position) * 2) % 1
    vec2.copy @lastKnownPosition, @_movable.position

    @_processRiderPhysics(elapsedSeconds)

    if @_input
      vec2.set @_movable.walk, 0, 0

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
    else
      # update walk target
      if vec2.squaredDistance(@_movable.position, @_walkTarget) < 0.01
        vec2.set @_walkTarget, Math.random() * 1.5 + 0.25, (if @_movable.position[1] > 2 then 0.5 else 5.5),
        @_directionTimer = 0

      # regular walk behaviour
      @_directionTimer -= elapsedSeconds

      if @_directionTimer <= 0
        @_directionTimer += 0.2 + Math.random() * 0.1

        walkDir = Math.atan2(@_walkTarget[1] - @_movable.position[1], @_walkTarget[0] - @_movable.position[0])

        LOOKAHEAD_DISTANCE = 0.3
        vec2.set @_tmpV2, Math.cos(walkDir) * LOOKAHEAD_DISTANCE, Math.sin(walkDir) * LOOKAHEAD_DISTANCE
        vec2.add @_tmpV2, @_tmpV2, @_movable.position

        # scan the rest of people and see what they're up to
        goSlow = false
        for otherPerson in @_personList when otherPerson isnt this
          if vec2.squaredDistance(@_tmpV2, otherPerson._movable.position) > 0.5 * 0.5 # @todo person size
            continue

          # if Math.abs(otherPerson.orientation - walkDir) < 0.8
          goSlow = true

        walkSpeed = if goSlow then 0.05 else 0.1

        @orientation = walkDir
        vec2.set @_movable.walk, Math.cos(walkDir) * walkSpeed, Math.sin(walkDir) * walkSpeed

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
