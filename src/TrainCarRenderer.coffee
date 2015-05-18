fs = require('fs')
vec3 = require('gl-matrix').vec3
vec4 = require('gl-matrix').vec4
mat4 = require('gl-matrix').mat4

FlatShader = require('./FlatShader.coffee')
OBJLoader = require('./OBJLoader.coffee')

meshPromise = new OBJLoader.loadFromData fs.readFileSync(__dirname + '/trainCarWall.obj'), 1

module.exports = class TrainCarRenderer
  constructor: (@_gl) ->
    @_flatShader = new FlatShader @_gl

    @_modelPosition = vec3.create()
    @_modelMatrix = mat4.create()

    @_color = vec4.fromValues(0.8, 0.8, 0.8, 1)

    @whenReady = meshPromise.then (mesh) =>
      @_meshTriangleCount = mesh.triangleCount

      @_meshBuffer = @_gl.createBuffer()
      @_gl.bindBuffer @_gl.ARRAY_BUFFER, @_meshBuffer
      @_gl.bufferData @_gl.ARRAY_BUFFER, new Float32Array(mesh.triangleBuffer), @_gl.STATIC_DRAW

  draw: (cameraMatrix, car) ->
    if !@_meshBuffer
      throw new Error 'not ready'

    # general setup
    @_flatShader.bind()

    @_gl.uniformMatrix4fv @_flatShader.cameraLocation, false, cameraMatrix

    @_gl.bindBuffer @_gl.ARRAY_BUFFER, @_meshBuffer
    @_gl.vertexAttribPointer @_flatShader.positionLocation, 3, @_gl.FLOAT, false, 0, 0

    # body
    mat4.identity(@_modelMatrix)
    mat4.translate(@_modelMatrix, @_modelMatrix, @_modelPosition)

    @_gl.uniform4fv @_flatShader.colorLocation, @_color
    @_gl.uniformMatrix4fv @_flatShader.modelLocation, false, @_modelMatrix

    @_gl.drawArrays @_gl.TRIANGLES, 0, @_meshTriangleCount * 3
