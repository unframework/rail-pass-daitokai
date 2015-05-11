
Promise = require('bluebird')
vec3 = require('gl-matrix').vec3
vec4 = require('gl-matrix').vec4
mat4 = require('gl-matrix').mat4

TrainPlatformRenderer = require('./TrainPlatformRenderer.coffee')
TrainRenderer = require('./TrainRenderer.coffee')
PersonRenderer = require('./PersonRenderer.coffee')

createCanvas = ->
    viewCanvas = document.createElement('canvas')
    viewCanvas.style.position = 'fixed'
    viewCanvas.style.top = '0px'
    viewCanvas.style.left = '0px'
    viewCanvas.width = window.innerWidth
    viewCanvas.height = window.innerHeight

    viewCanvas

setWhiteTexture = (gl, texture) ->
    gl.bindTexture(gl.TEXTURE_2D, texture)
    gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, new Uint8Array([ 255, 255, 255, 255 ]))
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)

module.exports = class View
    constructor: (@_timerStream, @_personList, @_train, @_trainPlatform) ->
        @isReady = false

        viewCanvas = createCanvas()
        document.body.appendChild viewCanvas

        @_gl = viewCanvas.getContext('experimental-webgl')
        @_gl.enable @_gl.DEPTH_TEST
        @_gl.depthFunc @_gl.LEQUAL

        @_platformRenderer = new TrainPlatformRenderer @_gl
        @_trainRenderer = new TrainRenderer @_gl
        @_personRenderer = new PersonRenderer @_gl

        Promise.join(
            @_platformRenderer.whenReady
        ).then =>
            @isReady = true

        @_cameraPosition = vec3.create()
        vec3.set @_cameraPosition, 0, 0, -8

        @_timerStream.on 'elapsed', (elapsedSeconds) =>
          # update camera position
          newCamDelta = vec3.fromValues(-@_personList[0]._movable.position[0], -@_personList[0]._movable.position[1], -8)
          vec3.subtract newCamDelta, newCamDelta, @_cameraPosition
          vec3.scale newCamDelta, newCamDelta, elapsedSeconds

          vec3.add @_cameraPosition, @_cameraPosition, newCamDelta

    draw: ->
        if !@isReady
            throw new Error 'not ready'

        camera = mat4.create()
        mat4.perspective camera, 45, window.innerWidth / window.innerHeight, 1, 10
        mat4.translate camera, camera, @_cameraPosition

        @_platformRenderer.draw camera, @_trainPlatform
        @_trainRenderer.draw camera, @_train

        for person in @_personList
            @_personRenderer.draw camera, person

