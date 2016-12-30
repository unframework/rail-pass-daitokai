vec2 = require('gl-matrix').vec2
vec3 = require('gl-matrix').vec3
color = require('onecolor')
aStar = require('a-star')

angleDiff = (a1, a2) ->
  d = a1 - a2
  while d > Math.PI
    d -= 2 * Math.PI
  while d < -Math.PI
    d += 2 * Math.PI

  d

findPath = (cell, targetX, targetY, avoidCell) ->
  tx = Math.round((targetX - 0.25) * 2) / 2 + 0.25
  ty = Math.round((targetY - 0.25) * 2) / 2 + 0.25
  out = aStar(
    start: cell
    isEnd: (c) ->
      c.center[0] is tx and c.center[1] is ty
    neighbor: (c) ->
      n for n in [
        c._left
        c._left._up if c._left and c._up
        c._right
        c._right._down if c._right and c._down
        c._up
        c._up._right if c._up and c._right
        c._down
        c._down._left if c._down and c._left
      ] when n and n isnt avoidCell
    distance: (a, b) ->
      Math.hypot b.center[0] - (a.center[0]), b.center[1] - (a.center[1])
    heuristic: (c) ->
      Math.hypot tx - (c.center[0]), ty - (c.center[1])
    hash: (c) ->
      c.origin[0] + ' ' + c.origin[1]
    timeout: 500
  )

  out.path

<<<<<<< Updated upstream
class Wanderer
  _STUCK_TIMEOUT: 1.5

  constructor: (@_physicsWorld, @_movable) ->
    @_walkPath = [ @_movable._cell ]
    @_stuckTimer = 0

  walkTo: (walkTarget) ->
    if vec2.squaredDistance(@_movable.position, @_walkPath[0].center) < 0.5 * 0.5
      @_stuckTimer = @_STUCK_TIMEOUT
      @_walkPath.shift()

    if @_walkPath.length < 1
      @_walkPath = findPath @_movable._cell, Math.random() * 10 + 0.25, Math.random() * 10 + 0.25
      @_walkPath.shift() if @_walkPath.length > 1 # no need to target starting point

    cell = @_walkPath[0]
    vec2.set walkTarget, cell.center[0], cell.center[1]

  update: (elapsedSeconds) ->
    @_stuckTimer -= elapsedSeconds

    if @_stuckTimer < 0
      @_stuckTimer = @_STUCK_TIMEOUT + Math.random() # randomize in case re-stuck against someone

      console.log 'unsticking'
      nextCell = @_walkPath[0]
      targetCell = @_walkPath[@_walkPath.length - 1]
      @_walkPath = findPath @_movable._cell, targetCell.center[0], targetCell.center[1], nextCell
      @_walkPath.shift() if @_walkPath.length > 1 # no need to target starting point
=======
  # shortPath = [ out.path.shift() ]
  # na = Math.atan2(
  #   out.path[0].center[1] - shortPath[0].center[1],
  #   out.path[0].center[0] - shortPath[0].center[0]
  # )

  # for c, ci in out.path
  #   ca = Math.atan2(
  #     c.center[1] - shortPath[shortPath.length - 1].center[1],
  #     c.center[0] - shortPath[shortPath.length - 1].center[0]
  #   )

  #   if Math.abs(ca - na) > 0.01
  #     shortPath.push out.path[ci - 1]
  #     na = Math.atan2(
  #       c.center[1] - shortPath[shortPath.length - 1].center[1],
  #       c.center[0] - shortPath[shortPath.length - 1].center[0]
  #     )

  # shortPath.push out.path[out.path.length - 1]

  # shortPath
>>>>>>> Stashed changes

module.exports = class Person
  constructor: (@_timerStream, @_input, @_physicsWorld, cell) ->
    @_movable = @_physicsWorld.createMovable cell, this

    @height = 1.50 + Math.random() * 0.25
    @color = new color.HSL(Math.random(), 0.8, 0.8).rgb()
    @color2 = @color.hue(0.08, true).lightness(0.7)

    @orientation = 0
    @bodyFocusTarget = vec2.fromValues(1, 0)

    @lastKnownPosition = vec2.create()
    @walkCycle = 0

    @riderSway = vec3.create()
    @riderSwayVelocity = vec3.create()
    @_riderSwayBalanceForce = 2.0 + Math.random() * 2

    @_nd = vec3.create()
    @_tmpLookaheadPos = vec2.create()
    @_tmpOtherDiff = vec2.create()
    @_tmpWalkCrossVector = vec2.create()

    @_directionTimer = 0
    @_walkTarget = vec2.clone @_movable.position
<<<<<<< Updated upstream
    @_pathing = unless @_input then new Wanderer @_physicsWorld, @_movable
=======
    @_walkPath = []
    @_walkPathStaleTimer = 0
>>>>>>> Stashed changes

    @_timerStream.on 'elapsed', (elapsedSeconds) => @_update elapsedSeconds

  _update: (elapsedSeconds) ->
    @walkCycle = (@walkCycle + vec2.distance(@lastKnownPosition, @_movable.position) * 2) % 1
    vec2.copy @lastKnownPosition, @_movable.position

    # rotate body gradually towards orientation
    @bodyFocusTarget[0] += (Math.cos(@orientation) - @bodyFocusTarget[0]) * 10 * elapsedSeconds
    @bodyFocusTarget[1] += (Math.sin(@orientation) - @bodyFocusTarget[1]) * 10 * elapsedSeconds

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
      # regular walk behaviour
      @_pathing.update elapsedSeconds
      @_directionTimer -= elapsedSeconds

      if @_directionTimer <= 0
        @_directionTimer += 0.2 + Math.random() * 0.1

        # update walk target
<<<<<<< Updated upstream
        @_pathing.walkTo @_walkTarget
=======
        if vec2.squaredDistance(@_movable.position, @_walkTarget) < 0.04
          if @_walkPath.length < 1
            @_walkPath = findPath @_movable._cell, Math.random() * 10 + 0.25, Math.random() * 10 + 0.25
            @_walkPath.shift() if @_walkPath.length > 1 # no need to target starting point
            @_walkPathStaleTimer = 0

          cell = @_walkPath.shift()
          vec2.set @_walkTarget, cell.center[0], cell.center[1]
>>>>>>> Stashed changes

        if @_walkPathStaleTimer > 0
          @_walkPathStaleTimer -= elapsedSeconds

          if @_walkPathStaleTimer <= 0
            targetCell = @_walkPath[@_walkPath.length - 1]
            @_walkPath = findPath @_movable._cell, targetCell.center[0], targetCell.center[1]
            @_walkPath.shift() if @_walkPath.length > 1 # no need to target starting point
            @_walkPathStaleTimer = 0

        walkDir = Math.atan2(@_walkTarget[1] - @_movable.position[1], @_walkTarget[0] - @_movable.position[0])

        vec2.set @_tmpWalkCrossVector, Math.sin(walkDir), -Math.cos(walkDir)

        LOOKAHEAD_DISTANCE = 0.4
        vec2.set @_tmpLookaheadPos, Math.cos(walkDir) * LOOKAHEAD_DISTANCE, Math.sin(walkDir) * LOOKAHEAD_DISTANCE
        vec2.add @_tmpLookaheadPos, @_tmpLookaheadPos, @_movable.position

        # scan the rest of people and see what they're up to
        goSlow = false
        goLeft = false
        goRight = false

        for otherMovable in @_physicsWorld._movables when otherMovable isnt @_movable
          if vec2.squaredDistance(@_tmpLookaheadPos, otherMovable.position) > 0.5 * 0.5 # @todo person size
            continue

          vec2.subtract @_tmpOtherDiff, otherMovable.position, @_movable.position
          crossPos = vec2.dot @_tmpOtherDiff, @_tmpWalkCrossVector

          otherPerson = otherMovable.person
          if Math.abs(angleDiff otherPerson.orientation, walkDir) > 0.6
            goSlow = true

          if crossPos < 0
            goRight = true
          else if crossPos > 0
            goLeft = true

        walkSpeed = 0.1
        if goLeft and goRight
          walkSpeed = -0.03
        else if goLeft
          walkDir += (if goSlow then 0.75 else 0.3)
          @_walkPathStaleTimer = 0.1 unless @_walkPathStaleTimer > 0 # for next time
        else if goRight
          walkDir -= (if goSlow then 0.75 else 0.3)
          @_walkPathStaleTimer = 0.1 unless @_walkPathStaleTimer > 0 # for next time

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
