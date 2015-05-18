vec2 = require('gl-matrix').vec2
color = require('onecolor')

module.exports = class Person
  constructor: (@_timerStream, @_input, @_physicsWorld, cell) ->
    @_movable = @_physicsWorld.createMovable cell

    @color = new color.HSL(Math.random(), 0.8, 0.8).rgb()
    @color2 = @color.hue(0.08, true).lightness(0.7)

    @orientation = 0

    @lastKnownPosition = vec2.create()
    @walkCycle = 0

    @_timerStream.on 'elapsed', (elapsedSeconds) =>
      @walkCycle = (@walkCycle + vec2.distance(@lastKnownPosition, @_movable.position) * 2) % 1
      vec2.copy @lastKnownPosition, @_movable.position

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
