
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

        @_timerStream.on 'elapsed', (elapsedSeconds) =>
          # update camera position
          newCamDelta = vec3.fromValues(-@_personList[0]._movable.position[0], -@_personList[0]._movable.position[1] + 4, -3)
          vec3.subtract newCamDelta, newCamDelta, @_cameraPosition
          vec3.scale newCamDelta, newCamDelta, elapsedSeconds

          vec3.add @_cameraPosition, @_cameraPosition, newCamDelta

    draw: ->
        if !@isReady
            throw new Error 'not ready'

        vec3.scale(@_swayOffset, @_personList[0].riderSway, -1)

        camera = mat4.create()
        mat4.perspective camera, 45, window.innerWidth / window.innerHeight, 1, 20
        mat4.rotateX camera, camera, -1.1
        mat4.translate camera, camera, @_cameraPosition
        mat4.translate camera, camera, @_swayOffset

        @_trainCarRenderer.draw camera, null

        for person in @_personList
            @_personRenderer.draw camera, person

