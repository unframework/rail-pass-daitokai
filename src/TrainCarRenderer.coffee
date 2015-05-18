fs = require('fs')
vec3 = require('gl-matrix').vec3
vec4 = require('gl-matrix').vec4
mat4 = require('gl-matrix').mat4

GradientShader = require('./GradientShader.coffee')
OBJLoader = require('./OBJLoader.coffee')

meshHeight = 2
wallMeshPromise = new OBJLoader.loadFromData fs.readFileSync(__dirname + '/trainCarWall.obj'), 1 / meshHeight
capMeshPromise = new OBJLoader.loadFromData fs.readFileSync(__dirname + '/trainCarCap.obj'), 1 / meshHeight

module.exports = class TrainCarRenderer
  constructor: (@_gl) ->
    @_gradientShader = new GradientShader @_gl

    @_modelPosition = vec3.create()
    @_modelScale = vec3.fromValues(meshHeight, meshHeight, meshHeight)
    @_modelFlipScale = vec3.fromValues(-meshHeight, -meshHeight, meshHeight)
    @_modelMatrix = mat4.create()

    @_color = vec4.fromValues(0.8, 0.8, 0.8, 1)
    @_color2 = vec4.fromValues(0.6, 0.6, 0.6, 1)

    @whenReady = wallMeshPromise.then (wallMesh) =>
      @_wallMeshTriangleCount = wallMesh.triangleCount

      @_wallMeshBuffer = @_gl.createBuffer()
      @_gl.bindBuffer @_gl.ARRAY_BUFFER, @_wallMeshBuffer
      @_gl.bufferData @_gl.ARRAY_BUFFER, new Float32Array(wallMesh.triangleBuffer), @_gl.STATIC_DRAW

      capMeshPromise.then (capMesh) =>
        @_capMeshTriangleCount = capMesh.triangleCount

        @_capMeshBuffer = @_gl.createBuffer()
        @_gl.bindBuffer @_gl.ARRAY_BUFFER, @_capMeshBuffer
        @_gl.bufferData @_gl.ARRAY_BUFFER, new Float32Array(capMesh.triangleBuffer), @_gl.STATIC_DRAW

  draw: (cameraMatrix, car) ->
    if !@_wallMeshBuffer
      throw new Error 'not ready'

    # general setup
    @_gradientShader.bind()

    @_gl.uniformMatrix4fv @_gradientShader.cameraLocation, false, cameraMatrix

    @_gl.uniform4fv @_gradientShader.colorTopLocation, @_color
    @_gl.uniform4fv @_gradientShader.colorBottomLocation, @_color2

    # body
    vec3.set @_modelPosition, -0.5, 0, 0
    mat4.identity(@_modelMatrix)
    mat4.translate(@_modelMatrix, @_modelMatrix, @_modelPosition)
    mat4.scale(@_modelMatrix, @_modelMatrix, @_modelScale)

    @_gl.uniformMatrix4fv @_gradientShader.modelLocation, false, @_modelMatrix

    @_gl.bindBuffer @_gl.ARRAY_BUFFER, @_wallMeshBuffer
    @_gl.vertexAttribPointer @_gradientShader.positionLocation, 3, @_gl.FLOAT, false, 0, 0

    @_gl.drawArrays @_gl.TRIANGLES, 0, @_wallMeshTriangleCount * 3

    @_gl.bindBuffer @_gl.ARRAY_BUFFER, @_capMeshBuffer
    @_gl.vertexAttribPointer @_gradientShader.positionLocation, 3, @_gl.FLOAT, false, 0, 0

    @_gl.drawArrays @_gl.TRIANGLES, 0, @_capMeshTriangleCount * 3

    vec3.set @_modelPosition, 2.5, 6, 0
    mat4.identity(@_modelMatrix)
    mat4.translate(@_modelMatrix, @_modelMatrix, @_modelPosition)
    mat4.scale(@_modelMatrix, @_modelMatrix, @_modelFlipScale)

    @_gl.uniformMatrix4fv @_gradientShader.modelLocation, false, @_modelMatrix

    @_gl.bindBuffer @_gl.ARRAY_BUFFER, @_wallMeshBuffer
    @_gl.vertexAttribPointer @_gradientShader.positionLocation, 3, @_gl.FLOAT, false, 0, 0

    @_gl.drawArrays @_gl.TRIANGLES, 0, @_wallMeshTriangleCount * 3

    @_gl.bindBuffer @_gl.ARRAY_BUFFER, @_capMeshBuffer
    @_gl.vertexAttribPointer @_gradientShader.positionLocation, 3, @_gl.FLOAT, false, 0, 0

    @_gl.drawArrays @_gl.TRIANGLES, 0, @_capMeshTriangleCount * 3
