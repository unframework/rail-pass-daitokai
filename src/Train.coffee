vec2 = require('gl-matrix').vec2

TIME_STEP = 0.016666
TRAIN_DECELERATION = 0.05
CRAWL_DISTANCE = 0.1
CRAWL_SPEED = 0.01

module.exports = class Train
  constructor: (@_timerStream) ->
    @_isDocked = false
    @_trackPosition = -10
    @_trackPositionDelta = 0.01
    @_accel = 0

    @_timeAccumulator = 0

    @_timerStream.on 'elapsed', (elapsedSeconds) => @_update elapsedSeconds

  _update: (elapsed) ->
    @_timeAccumulator = Math.max(0.2, @_timeAccumulator + elapsed)

    while @_timeAccumulator > 0
      @_timeAccumulator -= TIME_STEP
      @_performTimeStep()

      if @_accel is 0
        vel = @_trackPositionDelta / TIME_STEP
        distanceToStop = vel * vel / (2 * TRAIN_DECELERATION)

        if @_trackPosition + distanceToStop >= -CRAWL_DISTANCE
          @_accel = -TRAIN_DECELERATION

  _performTimeStep: ->
    # apply inertia
    newPosition = @_trackPosition + @_trackPositionDelta

    # clamp against end point
    if newPosition > 0
      newPosition = 0

    # save inertia
    @_trackPositionDelta = newPosition - @_trackPosition

    if @_accel < 0
      # slow down for near-stop
      if @_trackPositionDelta > CRAWL_SPEED * TIME_STEP
        change = Math.min(@_trackPositionDelta, TRAIN_DECELERATION * TIME_STEP * TIME_STEP)
        @_trackPositionDelta -= change

    @_trackPosition = newPosition
