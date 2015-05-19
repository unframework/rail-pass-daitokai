
Promise = require('bluebird')
vec3 = require('gl-matrix').vec3
vec4 = require('gl-matrix').vec4
mat4 = require('gl-matrix').mat4

TrainCarRenderer = require('./TrainCarRenderer.coffee')
PersonRenderer = require('./PersonRenderer.coffee')

createCanvas = ->
    viewCanvas = document.createElement('canvas')
    viewCanvas.style.position = 'fixed'
    viewCanvas.style.top = '0px'
    viewCanvas.style.left = '0px'
    viewCanvas.width = window.innerWidth
    viewCanvas.height = window.innerHeight

    viewCanvas

module.exports = class TrainView
    constructor: (@_timerStream, @_personList) ->
        @isReady = false

        viewCanvas = createCanvas()
        document.body.appendChild viewCanvas

        @_gl = viewCanvas.getContext('experimental-webgl')
        @_gl.enable @_gl.DEPTH_TEST
        @_gl.depthFunc @_gl.LEQUAL

        @_gl.enable @_gl.CULL_FACE
        @_gl.cullFace @_gl.BACK

        @_personRenderer = new PersonRenderer @_gl
        @_trainCarRenderer = new TrainCarRenderer @_gl

        Promise.join(
            @_personRenderer.whenReady
            @_trainCarRenderer.whenReady
        ).then =>
            @isReady = true

        @_cameraPosition = vec3.create()
        vec3.set @_cameraPosition, 0, 0, -8

        @_swayOffset = vec3.create()

        @targetPerson = @_personList[0]

        @_timerStream.on 'elapsed', (elapsedSeconds) =>
          # update camera position
          MIN_CAM_Y = -2.3
          MIN_TARGET_Y = -2.5 + 0.5 / 2
          CAM_FOLLOW_Y = 2

          newCamDelta = vec3.fromValues(-@targetPerson._movable.position[0] * 0.5 - 1 * 0.5, -@targetPerson._movable.position[1] + CAM_FOLLOW_Y, -2)
          if newCamDelta[1] > -MIN_CAM_Y
            newCamDelta[2] -= 0.5 * (newCamDelta[1] + MIN_CAM_Y) / (CAM_FOLLOW_Y + MIN_TARGET_Y - MIN_CAM_Y)
            newCamDelta[1] = -MIN_CAM_Y

          vec3.subtract newCamDelta, newCamDelta, @_cameraPosition
          vec3.scale newCamDelta, newCamDelta, elapsedSeconds

          vec3.add @_cameraPosition, @_cameraPosition, newCamDelta

    draw: ->
        if !@isReady
            throw new Error 'not ready'

        vec3.scale(@_swayOffset, @_personList[0].riderSway, -1)

        camera = mat4.create()
        mat4.perspective camera, 45, window.innerWidth / window.innerHeight, 0.1, 20
        mat4.rotateX camera, camera, -Math.atan2(@targetPerson._movable.position[1] + @_cameraPosition[1], -@_cameraPosition[2] - 1.5)
        mat4.rotateZ camera, camera, 0.3 * Math.atan2(@targetPerson._movable.position[0] + @_cameraPosition[0], @targetPerson._movable.position[1] + @_cameraPosition[1])
        mat4.translate camera, camera, @_cameraPosition
        mat4.translate camera, camera, @_swayOffset

        @_trainCarRenderer.draw camera, null

        for person in @_personList
            @_personRenderer.draw camera, person

