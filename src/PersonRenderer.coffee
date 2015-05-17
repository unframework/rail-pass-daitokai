fs = require('fs')
vec3 = require('gl-matrix').vec3
vec4 = require('gl-matrix').vec4
mat4 = require('gl-matrix').mat4

FlatTextureShader = require('./FlatTextureShader.coffee')
OBJLoader = require('./OBJLoader.coffee')
ImageLoader = require('./ImageLoader.coffee')

textureImageURI = 'data:application/octet-stream;base64,' + btoa(require('fs').readFileSync(__dirname + '/person.png', 'binary'))
textureImagePromise = ImageLoader.load textureImageURI

meshPromise = new OBJLoader.loadFromData fs.readFileSync(__dirname + '/personStanding.obj'), 1

module.exports = class PersonRenderer
  constructor: (@_gl) ->
    @_flatShader = new FlatTextureShader @_gl
    @_color = vec4.fromValues(1, 1, 1, 1)
    @_up = vec3.fromValues(0, 0, 1)

    @_modelPosition = vec3.create()
    @_modelMatrix = mat4.create()

    @_color = vec4.fromValues(0.4, 0.4, 0.4, 1)

    @whenReady = meshPromise.then (mesh) =>
      @_meshTriangleCount = mesh.triangleCount

      @_meshBuffer = @_gl.createBuffer()
      @_gl.bindBuffer @_gl.ARRAY_BUFFER, @_meshBuffer
      @_gl.bufferData @_gl.ARRAY_BUFFER, new Float32Array(mesh.triangleBuffer), @_gl.STATIC_DRAW

      @_meshUVBuffer = @_gl.createBuffer()
      @_gl.bindBuffer @_gl.ARRAY_BUFFER, @_meshUVBuffer
      @_gl.bufferData @_gl.ARRAY_BUFFER, new Float32Array(mesh.triangleUVBuffer), @_gl.STATIC_DRAW

      textureImagePromise.then (image) =>
        @_meshTexture = @_gl.createTexture()

        @_gl.bindTexture(@_gl.TEXTURE_2D, @_meshTexture)
        @_gl.pixelStorei(@_gl.UNPACK_FLIP_Y_WEBGL, true)
        @_gl.texImage2D(@_gl.TEXTURE_2D, 0, @_gl.RGBA, @_gl.RGBA, @_gl.UNSIGNED_BYTE, image)
        @_gl.texParameteri(@_gl.TEXTURE_2D, @_gl.TEXTURE_MAG_FILTER, @_gl.NEAREST)
        @_gl.texParameteri(@_gl.TEXTURE_2D, @_gl.TEXTURE_MIN_FILTER, @_gl.NEAREST)
        @_gl.texParameteri(@_gl.TEXTURE_2D, @_gl.TEXTURE_WRAP_S, @_gl.REPEAT)
        @_gl.texParameteri(@_gl.TEXTURE_2D, @_gl.TEXTURE_WRAP_T, @_gl.REPEAT)

  draw: (cameraMatrix, person) ->
    if !@_meshBuffer or !@_meshTexture
      throw new Error 'not ready'

    # general setup
    @_flatShader.bind()

    @_gl.uniformMatrix4fv @_flatShader.cameraLocation, false, cameraMatrix

    @_gl.bindTexture @_gl.TEXTURE_2D, @_meshTexture
    @_gl.uniform1i(@_flatShader.textureLocation, 0)

    @_gl.bindBuffer @_gl.ARRAY_BUFFER, @_meshUVBuffer
    @_gl.vertexAttribPointer @_flatShader.uvPositionLocation, 2, @_gl.FLOAT, false, 0, 0

    @_gl.bindBuffer @_gl.ARRAY_BUFFER, @_meshBuffer
    @_gl.vertexAttribPointer @_flatShader.positionLocation, 3, @_gl.FLOAT, false, 0, 0

    # body
    vec3.set(@_modelPosition, person._movable.position[0], person._movable.position[1], 0)

    mat4.identity(@_modelMatrix)
    mat4.translate(@_modelMatrix, @_modelMatrix, @_modelPosition)
    mat4.rotate(@_modelMatrix, @_modelMatrix, person.orientation, @_up)

    @_gl.uniform4fv @_flatShader.colorLocation, @_color
    @_gl.uniformMatrix4fv @_flatShader.modelLocation, false, @_modelMatrix

    @_gl.drawArrays @_gl.TRIANGLES, 0, @_meshTriangleCount * 3
