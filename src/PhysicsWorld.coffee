
vec2 = require('gl-matrix').vec2;

TIME_STEP = 0.016666

module.exports = class PhysicsWorld
    constructor: (@_input) ->
        @_timeAccumulator = 0
        @_movables = []

        @_createMovable()
        @_createMovable()

        vec2.set @_movables[0].position, 2, 1
        vec2.set @_movables[0]._nposition, 2, 1

        vec2.set @_movables[1].position, -1, 1.5
        vec2.set @_movables[1]._nposition, -1 + 0.001, 1.5

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

    _createMovable: () ->
        @_movables.push {
            position: vec2.create()
            _nposition: vec2.create()
            _tv: vec2.create()
        }

    _performTimeStep: ->
        nd = vec2.create()
        halfNudge = vec2.create()

        restoreDistance = (a, b) ->
            vec2.subtract nd, b._nposition, a._nposition
            d2 = vec2.squaredLength nd

            if d2 < 1
                dist = Math.sqrt d2

                nudgeDist = dist - 1
                vec2.scale halfNudge, nd, nudgeDist * 0.5 / dist

                vec2.add a._nposition, a._nposition, halfNudge
                vec2.subtract b._nposition, b._nposition, halfNudge

        for m in @_movables
            # Verlet inertia
            vec2.add m._nposition, m._nposition, m._tv

        for a in @_movables
            for b in @_movables
                if a is b
                    break # exit loop early

                restoreDistance a, b

        for m in @_movables
            # save speed delta
            vec2.subtract m._tv, m._nposition, m.position

            # apply friction
            ntv = vec2.length m._tv

            if ntv > 0
                subtract = Math.min(ntv, 0.01 * TIME_STEP * TIME_STEP);
                vec2.scale m._tv, m._tv, 1 - subtract / ntv

            # update position
            vec2.copy m.position, m._nposition
