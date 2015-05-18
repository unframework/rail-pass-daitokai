vec2 = require('gl-matrix').vec2

TIME_STEP = 0.016666
TRAIN_DECELERATION = 0.05
CRAWL_DISTANCE = 0.3
CRAWL_SPEED = 0.01

module.exports = class Train
  constructor: (@_timerStream, @_physicsWorld) ->
    @_isDocked = false
    @_isCrawling = false
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

      if !@_isDocked
        if !@_isCrawling
          # see when to start braking
          if @_accel is 0
            vel = @_trackPositionDelta / TIME_STEP
            distanceToStop = vel * vel / (2 * TRAIN_DECELERATION)

            if @_trackPosition + distanceToStop >= -CRAWL_DISTANCE
              @_accel = -TRAIN_DECELERATION

          # while braking, see when to stop at a crawl
          else if @_trackPositionDelta < @_accel * TIME_STEP * TIME_STEP
            @_isCrawling = true
            @_accel = 0
        else
          # crawling up to a stop
          if @_trackPosition is 0
            @_dock()
          else if @_trackPositionDelta / TIME_STEP < CRAWL_SPEED
            # ensure minimal speed
            @_accel = 0.01
          else
            @_accel = 0

  _dock: ->
    if @_isDocked
      throw new Error 'already docked'

    @_isDocked = true

    # doorPlatformCell = @_physicsWorld.originCell._up # @todo proper interface
    # @_doorCell = @_physicsWorld.extrudeLR(doorPlatformCell, 2, -1)._down
    # @_physicsWorld.extrudeLR @_doorCell, 2, -5
    # @_physicsWorld.extrudeUD @_doorCell._left, -4, -1
    # @_physicsWorld.extrudeUD @_doorCell._left._up, -4, 1

  _performTimeStep: ->
    # apply inertia
    newPosition = @_trackPosition + @_trackPositionDelta

    # apply acceleration
    newPosition += @_accel * TIME_STEP * TIME_STEP

    # clamp against end point
    if newPosition > 0
      newPosition = 0

    # save inertia
    @_trackPositionDelta = newPosition - @_trackPosition
    @_trackPosition = newPosition
