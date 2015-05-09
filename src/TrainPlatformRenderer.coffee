vec4 = require('gl-matrix').vec4
mat4 = require('gl-matrix').mat4

FlatTextureShader = require('./FlatTextureShader.coffee')

module.exports = class TrainPlatformRenderer
  constructor: (@_gl, @_platformTexture) ->
    @_texShader = new FlatTextureShader @_gl
    @_color = vec4.fromValues(1, 1, 1, 1)

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
      2, 0
      0, 2
      0, 2
      2, 0
      2, 2
    ]), @_gl.STATIC_DRAW

    @_modelMatrix = mat4.create()

  draw: (cameraMatrix, trainPlatform) ->
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

