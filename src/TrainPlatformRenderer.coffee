vec4 = require('gl-matrix').vec4
mat4 = require('gl-matrix').mat4

ImageLoader = require('./ImageLoader.coffee')
FlatTextureShader = require('./FlatTextureShader.coffee')

platformImageURI = 'data:application/octet-stream;base64,' + btoa(require('fs').readFileSync(__dirname + '/floor.png', 'binary'))
platformImagePromise = ImageLoader.load platformImageURI

module.exports = class TrainPlatformRenderer
  constructor: (@_gl) ->
    @_texShader = new FlatTextureShader @_gl
    @_color = vec4.fromValues(1, 1, 1, 1)

    @_platformBuffer = @_gl.createBuffer()
    @_gl.bindBuffer @_gl.ARRAY_BUFFER, @_platformBuffer
    @_gl.bufferData @_gl.ARRAY_BUFFER, new Float32Array([
      0, 0
      16, 0
      0, 16
      0, 16
      16, 0
      16, 16
    ]), @_gl.STATIC_DRAW

    @_platformUVBuffer = @_gl.createBuffer()
    @_gl.bindBuffer @_gl.ARRAY_BUFFER, @_platformUVBuffer
    @_gl.bufferData @_gl.ARRAY_BUFFER, new Float32Array([
      0, 0
      2, 0
      0, 2
      0, 2
      2, 0
      2, 2
    ]), @_gl.STATIC_DRAW

    @_modelMatrix = mat4.create()

    @whenReady = platformImagePromise.then (image) =>
      @_platformTexture = @_gl.createTexture()

      @_gl.bindTexture(@_gl.TEXTURE_2D, @_platformTexture)
      @_gl.pixelStorei(@_gl.UNPACK_FLIP_Y_WEBGL, true)
      @_gl.texImage2D(@_gl.TEXTURE_2D, 0, @_gl.RGBA, @_gl.RGBA, @_gl.UNSIGNED_BYTE, image)
      @_gl.texParameteri(@_gl.TEXTURE_2D, @_gl.TEXTURE_MAG_FILTER, @_gl.NEAREST)
      @_gl.texParameteri(@_gl.TEXTURE_2D, @_gl.TEXTURE_MIN_FILTER, @_gl.NEAREST)
      @_gl.texParameteri(@_gl.TEXTURE_2D, @_gl.TEXTURE_WRAP_S, @_gl.REPEAT)
      @_gl.texParameteri(@_gl.TEXTURE_2D, @_gl.TEXTURE_WRAP_T, @_gl.REPEAT)

      this

  draw: (cameraMatrix, trainPlatform) ->
    if !@_platformTexture
      throw new Error 'not ready'

    @_texShader.bind()

    @_gl.uniformMatrix4fv @_texShader.cameraLocation, false, cameraMatrix

    @_gl.bindTexture @_gl.TEXTURE_2D, @_platformTexture
    @_gl.uniform1i(@_texShader.textureLocation, 0)

    @_gl.bindBuffer @_gl.ARRAY_BUFFER, @_platformBuffer
    @_gl.vertexAttribPointer @_texShader.positionLocation, 2, @_gl.FLOAT, false, 0, 0

    @_gl.bindBuffer @_gl.ARRAY_BUFFER, @_platformUVBuffer
    @_gl.vertexAttribPointer @_texShader.uvPositionLocation, 2, @_gl.FLOAT, false, 0, 0

    @_gl.uniform4fv @_texShader.colorLocation, @_color
    @_gl.uniformMatrix4fv @_texShader.modelLocation, false, @_modelMatrix

    @_gl.drawArrays @_gl.TRIANGLES, 0, 6

