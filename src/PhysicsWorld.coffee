
vec2 = require('gl-matrix').vec2;

TIME_STEP = 0.016666

map = [
    'x  '
    'xxx'
]

module.exports = class PhysicsWorld
    constructor: (@_input) ->
        # sample cell map
        c00 = { origin: vec2.fromValues(0, 0), center: vec2.fromValues(0.5, 0.5) }
        c10 = { origin: vec2.fromValues(1, 0), center: vec2.fromValues(1.5, 0.5) }
        c20 = { origin: vec2.fromValues(2, 0), center: vec2.fromValues(2.5, 0.5) }
        c01 = { origin: vec2.fromValues(0, 1), center: vec2.fromValues(0.5, 1.5) }
        c21 = { origin: vec2.fromValues(2, 1), center: vec2.fromValues(2.5, 1.5) }
        c02 = { origin: vec2.fromValues(0, 2), center: vec2.fromValues(0.5, 2.5) }
        c12 = { origin: vec2.fromValues(1, 2), center: vec2.fromValues(1.5, 2.5) }

        c00._up = c01
        c00._right = c10
        c10._left = c00
        c10._right = c20
        c20._left = c10
        c20._up = c21
        c01._down = c00
        c01._up = c02
        c21._down = c20
        c02._down = c01
        c02._right = c12
        c12._left = c02

        @_timeAccumulator = 0
        @_movables = []

        @_createMovable(c01)
        @_createMovable(c10)

    update: (elapsed) ->
        @_timeAccumulator = Math.max(0.2, @_timeAccumulator + elapsed)

        while @_timeAccumulator > 0
            @_timeAccumulator -= TIME_STEP

            if @_input.status.LEFT
                @_movables[0]._nposition[0] -= 0.1 * TIME_STEP * TIME_STEP
            if @_input.status.RIGHT
                @_movables[0]._nposition[0] += 0.1 * TIME_STEP * TIME_STEP
            if @_input.status.UP
                @_movables[0]._nposition[1] += 0.1 * TIME_STEP * TIME_STEP
            if @_input.status.DOWN
                @_movables[0]._nposition[1] -= 0.1 * TIME_STEP * TIME_STEP

            @_performTimeStep()

    _createMovable: (cell) ->
        @_movables.push {
            position: vec2.fromValues cell.center[0], cell.center[1]
            _nposition: vec2.fromValues cell.center[0], cell.center[1]
            _tv: vec2.create()
            _cell: cell
            _cellLeft: false
            _cellDown: false
        }

    _updateMovableCell: (m) ->
        if m._nposition[0] >= m._cell.center[0] + 1
            if m._cell._right
                m._cell = m._cell._right

            m._cellLeft = false
        else if m._nposition[0] < m._cell.center[0]
            if m._cell._left
                m._cell = m._cell._left
                m._cellLeft = false
            else
                m._cellLeft = true
        else
            m._cellLeft = false

        if m._nposition[1] >= m._cell.center[1] + 1
            if m._cell._up
                m._cell = m._cell._up

            m._cellDown = false
        else if m._nposition[1] < m._cell.center[1]
            if m._cell._down
                m._cell = m._cell._down
                m._cellDown = false
            else
                m._cellDown = true
        else
            m._cellDown = false

    _performTimeStep: ->
        nd = vec2.create()
        halfNudge = vec2.create()

        restoreDistance = (a, b) =>
            vec2.subtract nd, b._nposition, a._nposition
            d2 = vec2.squaredLength nd

            if d2 < 1
                dist = Math.sqrt d2

                nudgeDist = dist - 1
                vec2.scale halfNudge, nd, nudgeDist * 0.5 / dist

                vec2.add a._nposition, a._nposition, halfNudge
                vec2.subtract b._nposition, b._nposition, halfNudge

                @_updateMovableCell a
                @_updateMovableCell b

        ensureDistanceFrom = (m, x, y) ->
            vec2.set nd, x, y
            vec2.subtract nd, m._nposition, nd
            if vec2.squaredLength(nd) < 0.5 * 0.5 # @todo check for zero distance
                dist = vec2.length(nd)
                vec2.scale nd, nd, (0.5 - dist) / dist
                vec2.add m._nposition, m._nposition, nd

        collideWithCells = (m) ->
            if m._cellLeft
                if m._nposition[0] < m._cell.center[0]
                    m._nposition[0] = m._cell.center[0]
                    m._cellLeft = false # out of that quadrant now

            if m._cellDown
                if m._nposition[1] < m._cell.center[1]
                    m._nposition[1] = m._cell.center[1]
                    m._cellDown = false # out of that quadrant now

            if m._nposition[0] < m._cell.origin[0] + 1
                if m._nposition[1] < m._cell.origin[1] + 1
                    # closest quadrant
                    if !m._cell._right
                        m._nposition[0] = m._cell.center[0]

                    if !m._cell._up
                        m._nposition[1] = m._cell.center[1]

                    if m._cell._right and m._cell._up
                        if !m._cell._right._up or !m._cell._up._right
                            ensureDistanceFrom m, m._cell.origin[0] + 1, m._cell.origin[1] + 1

                else
                    # left top quadrant
                    if !m._cell._up
                        m._nposition[1] = m._cell.center[1]
                    else if !m._cell._up._right
                        m._nposition[0] = m._cell.center[0]
                    else if !m._cell._right
                        # do the corner thing
                        ensureDistanceFrom m, m._cell.origin[0] + 1, m._cell.origin[1] + 1
            else
                if m._nposition[1] < m._cell.origin[1] + 1
                    # right bottom quadrant
                    if !m._cell._right
                        m._nposition[0] = m._cell.center[0]
                    else if !m._cell._right._up
                        m._nposition[1] = m._cell.center[1]
                    else if !m._cell._up
                        # do the corner thing
                        ensureDistanceFrom m, m._cell.origin[0] + 1, m._cell.origin[1] + 1

                else
                    # far quadrant
                    if m._cell._up
                        if !m._cell._up._right
                            # must move out of the quadrant
                            m._nposition[0] = m._cell.center[0]
                        else if !m._cell._right
                            # can stay in the quadrant
                            m._nposition[1] = m._cell.center[1] + 1

                    if m._cell._right
                        if !m._cell._right._up
                            # must move out of the quadrant
                            m._nposition[1] = m._cell.center[1]
                        else if !m._cell._up
                            # can stay in the quadrant
                            m._nposition[0] = m._cell.center[0] + 1

                    if !m._cell._up and !m._cell._right
                        m._nposition[0] = m._cell.center[0]
                        m._nposition[1] = m._cell.center[1]

        for m in @_movables
            # Verlet inertia
            vec2.add m._nposition, m._nposition, m._tv
            @_updateMovableCell m


        for a in @_movables
            for b in @_movables
                if a is b
                    break # exit loop early

                restoreDistance a, b

        for m in @_movables
            # enforce being in-bounds
            collideWithCells m

            # save speed delta
            vec2.subtract m._tv, m._nposition, m.position

            # apply friction
            ntv = vec2.length m._tv

            if ntv > 0
                subtract = Math.min(ntv, 0.01 * TIME_STEP * TIME_STEP);
                vec2.scale m._tv, m._tv, 1 - subtract / ntv

            # update position
            vec2.copy m.position, m._nposition
