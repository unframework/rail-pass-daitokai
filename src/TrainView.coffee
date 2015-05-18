
Promise = require('bluebird')
vec3 = require('gl-matrix').vec3
vec4 = require('gl-matrix').vec4
mat4 = require('gl-matrix').mat4

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

        Promise.join(
            @_personRenderer.whenReady
        ).then =>
            @isReady = true

        @_cameraPosition = vec3.create()
        vec3.set @_cameraPosition, 0, 0, -8

        @_timerStream.on 'elapsed', (elapsedSeconds) =>
          # update camera position
          newCamDelta = vec3.fromValues(-@_personList[0]._movable.position[0], -@_personList[0]._movable.position[1] + 4, -8)
          vec3.subtract newCamDelta, newCamDelta, @_cameraPosition
          vec3.scale newCamDelta, newCamDelta, elapsedSeconds

          vec3.add @_cameraPosition, @_cameraPosition, newCamDelta

    draw: ->
        if !@isReady
            throw new Error 'not ready'

        camera = mat4.create()
        mat4.perspective camera, 45, window.innerWidth / window.innerHeight, 1, 20
        mat4.rotateX camera, camera, -0.5
        mat4.translate camera, camera, @_cameraPosition

        for person in @_personList
            @_personRenderer.draw camera, person

