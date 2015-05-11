vec2 = require('gl-matrix').vec2

TIME_STEP = 0.016666

module.exports = class Train
  constructor: (@_timerStream) ->
    @_isDocked = false
    @_trackPosition = -1
    @_trackPositionDelta = 0.01

    @_timeAccumulator = 0

    @_timerStream.on 'elapsed', (elapsedSeconds) => @_update elapsedSeconds

  _update: (elapsed) ->
    @_timeAccumulator = Math.max(0.2, @_timeAccumulator + elapsed)

    while @_timeAccumulator > 0
      @_timeAccumulator -= TIME_STEP
      @_performTimeStep()

  _performTimeStep: ->
    # apply inertia
    newPosition = @_trackPosition + @_trackPositionDelta

    # save inertia
    @_trackPositionDelta = newPosition - @_trackPosition

    # apply friction
    absDelta = Math.abs(@_trackPositionDelta)
    if absDelta > 0
      subtract = Math.min(absDelta, 0.05 * TIME_STEP * TIME_STEP);
      @_trackPositionDelta *= 1 - subtract / absDelta

    @_trackPosition = newPosition
