
vec2 = require('gl-matrix').vec2;

TIME_STEP = 0.016666

module.exports = class PhysicsWorld
    constructor: () ->
        @_timeAccumulator = 0
        @_movables = [
            { position: vec2.create() }
        ]

        vec2.set @_movables[0].position, 2, 1

    update: (elapsed) ->
        @_timeAccumulator = Math.max(0.2, @_timeAccumulator + elapsed)

        while @_timeAccumulator > 0
            @_timeAccumulator -= TIME_STEP

            @_performTimeStep()

    _performTimeStep: ->
    #     for m in @_movables
