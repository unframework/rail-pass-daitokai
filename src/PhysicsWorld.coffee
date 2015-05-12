
vec2 = require('gl-matrix').vec2;

TIME_STEP = 0.016666
CELL_SIZE = 0.5
CELL_HALF_SIZE = CELL_SIZE / 2

map = [
    'x  '
    'xxx'
]

module.exports = class PhysicsWorld
    constructor: (@_timerStream, @_input) ->
        # sample cell map
        @originCell = { origin: vec2.fromValues(0, 0), center: vec2.fromValues(CELL_HALF_SIZE, CELL_HALF_SIZE) }

        @_timerStream.on 'elapsed', (elapsedSeconds) => @_update elapsedSeconds

        @_timeAccumulator = 0
        @_movables = []

    extrudeLR: (cell, height, dx) ->
        cellRow = [ cell ]

        while cellRow.length < height
            cellRow.push cellRow[cellRow.length - 1]._up

        if dx > 0
            while dx > 0
                dx -= 1

                newCellRow = ({ origin: vec2.fromValues(c.origin[0] + CELL_SIZE, c.origin[1]), center: vec2.fromValues(c.center[0] + CELL_SIZE, c.center[1]) } for c in cellRow)

                for c, i in cellRow
                    if c._right then throw new Error 'cannot override cell link'
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

                newCellRow = ({ origin: vec2.fromValues(c.origin[0] - CELL_SIZE, c.origin[1]), center: vec2.fromValues(c.center[0] - CELL_SIZE, c.center[1]) } for c in cellRow)

                for c, i in cellRow
                    if c._left then throw new Error 'cannot override cell link'
                    c._left = newCellRow[i]
                    newCellRow[i]._right = c

                for c, i in newCellRow
                    if i > 0
                        c._down = newCellRow[i - 1]
                        newCellRow[i - 1]._up = c

                cellRow = newCellRow

        cellRow[cellRow.length - 1]

    extrudeUD: (cell, width, dy) ->
        cellRow = [ cell ]

        while cellRow.length < width
            cellRow.push cellRow[cellRow.length - 1]._right

        if dy > 0
            while dy > 0
                dy -= 1

                newCellRow = ({ origin: vec2.fromValues(c.origin[0], c.origin[1] + CELL_SIZE), center: vec2.fromValues(c.center[0], c.center[1] + CELL_SIZE) } for c in cellRow)

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

                newCellRow = ({ origin: vec2.fromValues(c.origin[0], c.origin[1] - CELL_SIZE), center: vec2.fromValues(c.center[0], c.center[1] - CELL_SIZE) } for c in cellRow)

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
            @_performTimeStep()

    createMovable: (cell) ->
        m = {
            position: vec2.fromValues cell.center[0], cell.center[1]
            walk: vec2.create()
            _nposition: vec2.fromValues cell.center[0], cell.center[1]
            _tv: vec2.create()
            _cell: cell
        }

        @_movables.push m

        m

    _updateMovableCell: (m) ->
        dx = m._nposition[0] - m._cell.center[0]
        dy = m._nposition[1] - m._cell.center[1]

        newCell =
            if dx >= CELL_HALF_SIZE
                if dy > dx then m._cell._up
                else if dy < -dx then m._cell._down
                else m._cell._right
            else if dx < -CELL_HALF_SIZE
                if dy > -dx then m._cell._up
                else if dy < dx then m._cell._down
                else m._cell._left
            else if dy >= CELL_HALF_SIZE then m._cell._up
            else if dy < -CELL_HALF_SIZE then m._cell._down
            else null

        if newCell
            m._cell = newCell

    _performTimeStep: ->
        walkMax = 0.2
        nd = vec2.create()
        halfNudge = vec2.create()

        restoreDistance = (a, b) =>
            vec2.subtract nd, b._nposition, a._nposition
            d2 = vec2.squaredLength nd

            if d2 < CELL_SIZE
                dist = Math.sqrt d2

                nudgeDist = dist - CELL_SIZE
                vec2.scale halfNudge, nd, nudgeDist * 0.5 / dist

                vec2.add a._nposition, a._nposition, halfNudge
                vec2.subtract b._nposition, b._nposition, halfNudge

                @_updateMovableCell a
                @_updateMovableCell b

        ensureDistanceFrom = (m, x, y) ->
            vec2.set nd, x, y
            vec2.subtract nd, m._nposition, nd
            if vec2.squaredLength(nd) < CELL_HALF_SIZE * CELL_HALF_SIZE # @todo check for zero distance
                dist = vec2.length(nd)
                vec2.scale nd, nd, (CELL_HALF_SIZE - dist) / dist
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
                        ensureDistanceFrom m, m._cell.origin[0], m._cell.origin[1] + CELL_SIZE
            else
                if dy < 0
                    # right bottom corner
                    if !m._cell._right
                        m._nposition[0] = m._cell.center[0]

                    if !m._cell._down
                        m._nposition[1] = m._cell.center[1]

                    if m._cell._right and m._cell._down and !m._cell._right._down
                        # @todo deal with overlapping cell graph
                        ensureDistanceFrom m, m._cell.origin[0] + CELL_SIZE, m._cell.origin[1]
                else
                    # right top corner
                    if !m._cell._right
                        m._nposition[0] = m._cell.center[0]

                    if !m._cell._up
                        m._nposition[1] = m._cell.center[1]

                    if m._cell._right and m._cell._up and !m._cell._right._up
                        # @todo deal with overlapping cell graph
                        ensureDistanceFrom m, m._cell.origin[0] + CELL_SIZE, m._cell.origin[1] + CELL_SIZE

        for m in @_movables
            # Verlet inertia
            vec2.add m._nposition, m.position, m._tv

            # apply walk
            # maximum new displacement
            # NOTE: if already moving faster than walk-speed, we preserve that
            maxD = Math.max(vec2.length(m._tv), walkMax * TIME_STEP);

            vec2.scale nd, m.walk, TIME_STEP * TIME_STEP
            vec2.add m._nposition, m._nposition, nd

            # constrain new displacement to our maximum
            vec2.subtract nd, m._nposition, m.position
            d = vec2.length nd
            if(d > maxD)
                vec2.scale nd, nd, (maxD - d) / d
                vec2.add m._nposition, m._nposition, nd

            @_updateMovableCell m

        for a in @_movables
            for b in @_movables
                if a is b
                    break # exit loop early

                # @todo this + cell collision several times
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
                subtract = Math.min(ntv, 0.05 * TIME_STEP * TIME_STEP);
                vec2.scale m._tv, m._tv, 1 - subtract / ntv

            # update position
            vec2.copy m.position, m._nposition
