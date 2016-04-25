
vec2 = require('gl-matrix').vec2;

TIME_STEP = 0.016666
CELL_SIZE = 0.5
CELL_HALF_SIZE = CELL_SIZE / 2

map = [
    'x  '
    'xxx'
]

module.exports = class PhysicsWorld
    constructor: (@_timerStream) ->
        # sample cell map
        @_map = Object.create(null)
        @originCell = { origin: vec2.fromValues(0, 0), center: vec2.fromValues(CELL_HALF_SIZE, CELL_HALF_SIZE) }

        @_map[@originCell.origin[0] + ' ' + @originCell.origin[1]] = @originCell

        @_timerStream.on 'elapsed', (elapsedSeconds) => @_update elapsedSeconds

        @_timeAccumulator = 0
        @_movables = []

    walkAll: (eachCellCallback) ->
        stack = [ @originCell ]
        usedMap = Object.create(null)

        i = 0

        while stack.length > 0
            cell = stack.pop()

            if usedMap[cell.origin[0] + ' ' + cell.origin[1]]
                continue

            usedMap[cell.origin[0] + ' ' + cell.origin[1]] = true

            for nextCell in [ cell._left, cell._up, cell._right, cell._down ] when nextCell
                stack.push nextCell

            eachCellCallback cell

            i += 1
            if i > 1000
                throw new Error('too many cells!')

    extrudeLR: (cell, height, dx) ->
        if height < 0
            height = -height

            count = height
            while count > 1
                count -= 1
                cell = cell._down

        cellRow = [ cell ]

        while cellRow.length < height
            cellRow.push cellRow[cellRow.length - 1]._up

        makeCell = (c, cdx, cdy) =>
            x = c.origin[0] + cdx
            y = c.origin[1] + cdy
            coords = x + ' ' + y

            cell = @_map[coords] or {
                origin: vec2.fromValues(x, y),
                center: vec2.fromValues(c.center[0] + cdx, c.center[1] + cdy)
            }

            @_map[coords] = cell

        if dx > 0
            while dx > 0
                dx -= 1

                newCellRow = (makeCell(c, CELL_SIZE, 0) for c in cellRow)

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

                newCellRow = (makeCell(c, -CELL_SIZE, 0) for c in cellRow)

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
        if width < 0
            width = -width

            count = width
            while count > 1
                count -= 1
                cell = cell._left

        cellRow = [ cell ]

        while cellRow.length < width
            cellRow.push cellRow[cellRow.length - 1]._right

        makeCell = (c, cdx, cdy) =>
            x = c.origin[0] + cdx
            y = c.origin[1] + cdy
            coords = x + ' ' + y

            cell = @_map[coords] or {
                origin: vec2.fromValues(x, y),
                center: vec2.fromValues(c.center[0] + cdx, c.center[1] + cdy)
            }

            @_map[coords] = cell

        if dy > 0
            while dy > 0
                dy -= 1

                newCellRow = (makeCell(c, 0, CELL_SIZE) for c in cellRow)

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

                newCellRow = (makeCell(c, 0, -CELL_SIZE) for c in cellRow)

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

    createMovable: (cell, person) ->
        m = {
            person: person
            position: vec2.fromValues cell.center[0], cell.center[1]
            walk: vec2.create()
            _nposition: vec2.fromValues cell.center[0], cell.center[1]
            _tv: vec2.create()
            _cell: cell
        }

        @_movables.push m

        m

    updateMovablePosition: (movable, delta) ->
        vec2.add movable.position, movable.position, delta
        vec2.add movable._nposition, movable._nposition, delta

        while true
            oldCell = movable._cell
            @_updateMovableCell movable
            if oldCell is movable._cell
                break

        # ensure proper distances again, and copy the new positions over
        for i in [ 0...5 ]
            @_constrainDistances()

        for m in @_movables
            vec2.copy m.position, m._nposition

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
        walkMax = 0.1
        nd = vec2.create()

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

        @_constrainDistances()

        for m in @_movables
            # save speed delta
            vec2.subtract m._tv, m._nposition, m.position

            # apply friction
            ntv = vec2.length m._tv

            if ntv > 0
                subtract = Math.min(ntv, 0.03 * TIME_STEP * TIME_STEP);
                vec2.scale m._tv, m._tv, 1 - subtract / ntv

            # update position
            vec2.copy m.position, m._nposition

    _constrainDistances: ->
        nd = vec2.create()
        halfNudge = vec2.create()

        restoreDistance = (a, b) =>
            vec2.subtract nd, b._nposition, a._nposition
            d2 = vec2.squaredLength nd

            if d2 < CELL_SIZE * CELL_SIZE
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

        for a in @_movables
            for b in @_movables
                if a is b
                    break # exit loop early

                # @todo this + cell collision several times
                restoreDistance a, b

        for m in @_movables
            # enforce being in-bounds as a last thing
            collideWithCells m
            @_updateMovableCell m

