
vec2 = require('gl-matrix').vec2;

TIME_STEP = 0.016666

map = [
    'x  '
    'xxx'
]

module.exports = class PhysicsWorld
    constructor: (@_timerStream, @_input) ->
        # sample cell map
        c00 = { origin: vec2.fromValues(0, 0), center: vec2.fromValues(0.5, 0.5) }

        @_extrudeLR c00, 1, 3
        @_extrudeUD c00, 4, 3

        @_timerStream.on 'elapsed', (elapsedSeconds) => @_update elapsedSeconds

        @_timeAccumulator = 0
        @_movables = []

        @_createMovable(c00)

    _extrudeLR: (cell, height, dx) ->
        cellRow = [ cell ]

        while cellRow.length < height
            cellRow.push cellRow[cellRow.length - 1]._up

        if dx > 0
            while dx > 0
                dx -= 1

                newCellRow = ({ origin: vec2.fromValues(c.origin[0] + 1, c.origin[1]), center: vec2.fromValues(c.center[0] + 1, c.center[1]) } for c in cellRow)

                for c, i in cellRow
                    c._right = newCellRow[i]
                    newCellRow[i]._left = c

                for c, i in newCellRow
                    if i > 0
                        c._down = newCellRow[i - 1]
                        newCellRow[i - 1]._up = c

                cellRow = newCellRow

        else
            while dx < 0
                dx += 1

                newCellRow = ({ origin: vec2.fromValues(c.origin[0] - 1, c.origin[1]), center: vec2.fromValues(c.center[0] - 1, c.center[1]) } for c in cellRow)

                for c, i in cellRow
                    c._left = newCellRow[i]
                    newCellRow[i]._right = c

                for c, i in newCellRow
                    if i > 0
                        c._down = newCellRow[i - 1]
                        newCellRow[i - 1]._up = c

                cellRow = newCellRow

        cellRow[cellRow.length - 1]

    _extrudeUD: (cell, width, dy) ->
        cellRow = [ cell ]

        while cellRow.length < width
            cellRow.push cellRow[cellRow.length - 1]._right

        if dy > 0
            while dy > 0
                dy -= 1

                newCellRow = ({ origin: vec2.fromValues(c.origin[0], c.origin[1] + 1), center: vec2.fromValues(c.center[0], c.center[1] + 1) } for c in cellRow)

                for c, i in cellRow
                    c._up = newCellRow[i]
                    newCellRow[i]._down = c

                for c, i in newCellRow
                    if i > 0
                        c._left = newCellRow[i - 1]
                        newCellRow[i - 1]._right = c

                cellRow = newCellRow

        else
            while dy < 0
                dy += 1

                newCellRow = ({ origin: vec2.fromValues(c.origin[0], c.origin[1] - 1), center: vec2.fromValues(c.center[0], c.center[1] - 1) } for c in cellRow)

                for c, i in cellRow
                    c._down = newCellRow[i]
                    newCellRow[i]._up = c

                for c, i in newCellRow
                    if i > 0
                        c._left = newCellRow[i - 1]
                        newCellRow[i - 1]._right = c

                cellRow = newCellRow

        cellRow[cellRow.length - 1]

    _update: (elapsed) ->
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
        }

    _updateMovableCell: (m) ->
        dx = m._nposition[0] - m._cell.center[0]
        dy = m._nposition[1] - m._cell.center[1]

        newCell =
            if dx >= 0.5
                if dy > dx then m._cell._up
                else if dy < -dx then m._cell._down
                else m._cell._right
            else if dx < -0.5
                if dy > -dx then m._cell._up
                else if dy < dx then m._cell._down
                else m._cell._left
            else if dy >= 0.5 then m._cell._up
            else if dy < -0.5 then m._cell._down
            else null

        if newCell
            m._cell = newCell

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
            dx = m._nposition[0] - m._cell.center[0]
            dy = m._nposition[1] - m._cell.center[1]

            if dx < 0
                if dy < 0
                    # left bottom corner
                    if !m._cell._left
                        m._nposition[0] = m._cell.center[0]

                    if !m._cell._down
                        m._nposition[1] = m._cell.center[1]

                    if m._cell._left and m._cell._down and !m._cell._left._down
                        # @todo deal with overlapping cell graph
                        ensureDistanceFrom m, m._cell.origin[0], m._cell.origin[1]
                else
                    # left top corner
                    if !m._cell._left
                        m._nposition[0] = m._cell.center[0]

                    if !m._cell._up
                        m._nposition[1] = m._cell.center[1]

                    if m._cell._left and m._cell._up and !m._cell._left._up
                        # @todo deal with overlapping cell graph
                        ensureDistanceFrom m, m._cell.origin[0], m._cell.origin[1] + 1
            else
                if dy < 0
                    # right bottom corner
                    if !m._cell._right
                        m._nposition[0] = m._cell.center[0]

                    if !m._cell._down
                        m._nposition[1] = m._cell.center[1]

                    if m._cell._right and m._cell._down and !m._cell._right._down
                        # @todo deal with overlapping cell graph
                        ensureDistanceFrom m, m._cell.origin[0] + 1, m._cell.origin[1]
                else
                    # right top corner
                    if !m._cell._right
                        m._nposition[0] = m._cell.center[0]

                    if !m._cell._up
                        m._nposition[1] = m._cell.center[1]

                    if m._cell._right and m._cell._up and !m._cell._right._up
                        # @todo deal with overlapping cell graph
                        ensureDistanceFrom m, m._cell.origin[0] + 1, m._cell.origin[1] + 1

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
            @_updateMovableCell m

            # save speed delta
            vec2.subtract m._tv, m._nposition, m.position

            # apply friction
            ntv = vec2.length m._tv

            if ntv > 0
                subtract = Math.min(ntv, 0.01 * TIME_STEP * TIME_STEP);
                vec2.scale m._tv, m._tv, 1 - subtract / ntv

            # update position
            vec2.copy m.position, m._nposition
