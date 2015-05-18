fs = require('fs')
vec3 = require('gl-matrix').vec3
vec4 = require('gl-matrix').vec4
mat4 = require('gl-matrix').mat4

GradientShader = require('./GradientShader.coffee')
OBJLoader = require('./OBJLoader.coffee')

meshHeight = 2
meshPromise = new OBJLoader.loadFromData fs.readFileSync(__dirname + '/trainCarWall.obj'), 1 / meshHeight

module.exports = class TrainCarRenderer
  constructor: (@_gl) ->
    @_gradientShader = new GradientShader @_gl

    @_modelPosition = vec3.create()
    @_modelScale = vec3.fromValues(meshHeight, meshHeight, meshHeight)
    @_modelMatrix = mat4.create()

    @_color = vec4.fromValues(0.8, 0.8, 0.8, 1)
    @_color2 = vec4.fromValues(0.6, 0.6, 0.6, 1)

    @whenReady = meshPromise.then (mesh) =>
      @_meshTriangleCount = mesh.triangleCount

      @_meshBuffer = @_gl.createBuffer()
      @_gl.bindBuffer @_gl.ARRAY_BUFFER, @_meshBuffer
      @_gl.bufferData @_gl.ARRAY_BUFFER, new Float32Array(mesh.triangleBuffer), @_gl.STATIC_DRAW

  draw: (cameraMatrix, car) ->
    if !@_meshBuffer
      throw new Error 'not ready'

    # general setup
    @_gradientShader.bind()

    @_gl.uniformMatrix4fv @_gradientShader.cameraLocation, false, cameraMatrix

    @_gl.bindBuffer @_gl.ARRAY_BUFFER, @_meshBuffer
    @_gl.vertexAttribPointer @_gradientShader.positionLocation, 3, @_gl.FLOAT, false, 0, 0

    # body
    mat4.identity(@_modelMatrix)
    mat4.translate(@_modelMatrix, @_modelMatrix, @_modelPosition)
    mat4.scale(@_modelMatrix, @_modelMatrix, @_modelScale)

    @_gl.uniformMatrix4fv @_gradientShader.modelLocation, false, @_modelMatrix

    @_gl.uniform4fv @_gradientShader.colorTopLocation, @_color
    @_gl.uniform4fv @_gradientShader.colorBottomLocation, @_color2

    @_gl.drawArrays @_gl.TRIANGLES, 0, @_meshTriangleCount * 3
