
Promise = require('bluebird')
vec3 = require('gl-matrix').vec3
vec4 = require('gl-matrix').vec4
mat4 = require('gl-matrix').mat4

FlatShader = require('./FlatShader.coffee')
FlatTextureShader = require('./FlatTextureShader.coffee')

platformImageURI = 'data:application/octet-stream;base64,' + btoa(require('fs').readFileSync(__dirname + '/floor.png', 'binary'))

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

whenTextureLoaded = (gl, imageURI) ->
    texture = gl.createTexture()
    textureImage = new Image()

    texturePromise = new Promise (resolve) ->
        textureImage.onload = ->
            gl.bindTexture(gl.TEXTURE_2D, texture)
            gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true)
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, textureImage)
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)

            resolve texture

    textureImage.src = imageURI
    texturePromise

module.exports = class View
    constructor: (@_timerStream, @_trainPlatform) ->
        @isReady = false

        viewCanvas = createCanvas()
        document.body.appendChild viewCanvas

        @_gl = viewCanvas.getContext('experimental-webgl')
        @_flatShader = new FlatShader @_gl
        @_texShader = new FlatTextureShader @_gl

        @_spriteBuffer = @_gl.createBuffer()
        @_gl.bindBuffer @_gl.ARRAY_BUFFER, @_spriteBuffer
        @_gl.bufferData @_gl.ARRAY_BUFFER, new Float32Array([
          -0.5, -0.5
          0.5, -0.5
          -0.5, 0.5
          -0.5, 0.5
          0.5, -0.5
          0.5, 0.5
        ]), @_gl.STATIC_DRAW

        @_platformBuffer = @_gl.createBuffer()
        @_gl.bindBuffer @_gl.ARRAY_BUFFER, @_platformBuffer
        @_gl.bufferData @_gl.ARRAY_BUFFER, new Float32Array([
          0, 0
          4, 0
          0, 4
          0, 4
          4, 0
          4, 4
        ]), @_gl.STATIC_DRAW

        @_platformUVBuffer = @_gl.createBuffer()
        @_gl.bindBuffer @_gl.ARRAY_BUFFER, @_platformUVBuffer
        @_gl.bufferData @_gl.ARRAY_BUFFER, new Float32Array([
          0, 0
          1, 0
          0, 1
          0, 1
          1, 0
          1, 1
        ]), @_gl.STATIC_DRAW

        Promise.join(
            whenTextureLoaded(@_gl, platformImageURI).then (t) => @_platformTexture = t
        ).then =>
            @isReady = true

        @_cameraPosition = vec3.create()
        vec3.set @_cameraPosition, 0, 0, -8

        @_timerStream.on 'elapsed', (elapsedSeconds) => if @isReady then @_render(elapsedSeconds)

    _render: (elapsedSeconds) ->
        if !@isReady
            throw new Error 'not ready'

        # update camera position
        newCamDelta = vec3.fromValues(-@_trainPlatform._physicsWorld._movables[0].position[0], -@_trainPlatform._physicsWorld._movables[0].position[1], -8)
        vec3.subtract newCamDelta, newCamDelta, @_cameraPosition
        # camDist = vec3.length newCamDelta
        vec3.scale newCamDelta, newCamDelta, elapsedSeconds

        vec3.add @_cameraPosition, @_cameraPosition, newCamDelta

        camera = mat4.create()
        mat4.perspective camera, 45, window.innerWidth / window.innerHeight, 1, 10
        mat4.translate camera, camera, @_cameraPosition

        modelPosition = vec3.create()
        model = mat4.create()

        blackColor = vec4.fromValues(0, 0, 0, 1)
        grayColor = vec4.fromValues(0.5, 0.5, 0.5, 1)

        @_texShader.bind()
        @_gl.uniformMatrix4fv @_texShader.cameraLocation, false, camera
        @_gl.bindTexture @_gl.TEXTURE_2D, @_platformTexture
        @_gl.uniform1i(@_texShader.textureLocation, 0)
        @_gl.bindBuffer @_gl.ARRAY_BUFFER, @_platformBuffer
        @_gl.vertexAttribPointer @_texShader.positionLocation, 2, @_gl.FLOAT, false, 0, 0
        @_gl.bindBuffer @_gl.ARRAY_BUFFER, @_platformUVBuffer
        @_gl.vertexAttribPointer @_texShader.uvPositionLocation, 2, @_gl.FLOAT, false, 0, 0
        @_gl.uniform4fv @_texShader.colorLocation, grayColor
        @_gl.uniformMatrix4fv @_texShader.modelLocation, false, model

        @_gl.drawArrays @_gl.TRIANGLES, 0, 6

        @_flatShader.bind()
        @_gl.uniformMatrix4fv @_flatShader.cameraLocation, false, camera
        @_gl.bindBuffer @_gl.ARRAY_BUFFER, @_spriteBuffer
        @_gl.vertexAttribPointer @_flatShader.positionLocation, 2, @_gl.FLOAT, false, 0, 0

        for m in @_trainPlatform._physicsWorld._movables
            vec3.set(modelPosition, m._cell.center[0], m._cell.center[1], 0)

            mat4.identity(model)
            mat4.translate(model, model, modelPosition)

            @_gl.uniform4fv @_flatShader.colorLocation, grayColor
            @_gl.uniformMatrix4fv @_flatShader.modelLocation, false, model
            @_gl.drawArrays @_gl.TRIANGLES, 0, 6

            vec3.set(modelPosition, m.position[0], m.position[1], 0)

            mat4.identity(model)
            mat4.translate(model, model, modelPosition)

            @_gl.uniform4fv @_flatShader.colorLocation, blackColor
            @_gl.uniformMatrix4fv @_flatShader.modelLocation, false, model
            @_gl.drawArrays @_gl.TRIANGLES, 0, 6

