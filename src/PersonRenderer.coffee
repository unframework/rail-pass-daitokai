vec3 = require('gl-matrix').vec3
vec4 = require('gl-matrix').vec4
mat4 = require('gl-matrix').mat4
ndarray = require('ndarray')
isosurface = require('isosurface')

FlatShader = require('./FlatShader.coffee')

meshW = 3
meshH = 3
meshD = 3

meshArray = ndarray(new Float64Array([
  0, 0, 0, 1, 1, 1, 0, 0, 0
  0, 0, 0, 1, 1, 1, 0, 0, 0
  0, 0, 0, 0, 1, 0, 0, 0, 0
]), [meshW, meshH, meshD])

mesh = isosurface.surfaceNets [meshW + 2, meshH + 2, meshD + 2], (x, y, z) ->
  if x < 0 or y < 0 or z < 0
    -0.5
  else if x >= meshW or y >= meshH or z >= meshD
    -0.5
  else
    v = meshArray.get(x, y, z)
    v - 0.5
, [[-1, -1, -1], [meshW + 1, meshH + 1, meshD + 1]]

meshTriangleVertexData = []

for c in mesh.cells
  if c.length is 3
    meshTriangleVertexData.push mesh.positions[c[0]][0]
    meshTriangleVertexData.push mesh.positions[c[0]][1]
    meshTriangleVertexData.push mesh.positions[c[0]][2]
    meshTriangleVertexData.push mesh.positions[c[1]][0]
    meshTriangleVertexData.push mesh.positions[c[1]][1]
    meshTriangleVertexData.push mesh.positions[c[1]][2]
    meshTriangleVertexData.push mesh.positions[c[2]][0]
    meshTriangleVertexData.push mesh.positions[c[2]][1]
    meshTriangleVertexData.push mesh.positions[c[2]][2]
  else
    throw new Error('poly face')

numMeshTriangles = mesh.cells.length

module.exports = class PersonRenderer
  constructor: (@_gl) ->
    @_flatShader = new FlatShader @_gl
    @_color = vec4.fromValues(1, 1, 1, 1)

    @_meshBuffer = @_gl.createBuffer()
    @_gl.bindBuffer @_gl.ARRAY_BUFFER, @_meshBuffer
    @_gl.bufferData @_gl.ARRAY_BUFFER, new Float32Array(meshTriangleVertexData), @_gl.STATIC_DRAW

    @_modelPosition = vec3.create()
    @_modelMatrix = mat4.create()

    @_blackColor = vec4.fromValues(0, 0, 0, 1)
    @_grayColor = vec4.fromValues(0.5, 0.5, 0.5, 1)

  draw: (cameraMatrix, movable) ->
    # general setup
    @_flatShader.bind()

    @_gl.uniformMatrix4fv @_flatShader.cameraLocation, false, cameraMatrix

    @_gl.bindBuffer @_gl.ARRAY_BUFFER, @_meshBuffer
    @_gl.vertexAttribPointer @_flatShader.positionLocation, 3, @_gl.FLOAT, false, 0, 0

    # cell
    vec3.set(@_modelPosition, movable._cell.center[0], movable._cell.center[1], 0)

    mat4.identity(@_modelMatrix)
    mat4.translate(@_modelMatrix, @_modelMatrix, @_modelPosition)

    @_gl.uniform4fv @_flatShader.colorLocation, @_grayColor
    @_gl.uniformMatrix4fv @_flatShader.modelLocation, false, @_modelMatrix

    @_gl.drawArrays @_gl.TRIANGLES, 0, numMeshTriangles * 3

    # body
    vec3.set(@_modelPosition, movable.position[0], movable.position[1], 0)

    mat4.identity(@_modelMatrix)
    mat4.translate(@_modelMatrix, @_modelMatrix, @_modelPosition)

    @_gl.uniform4fv @_flatShader.colorLocation, @_blackColor
    @_gl.uniformMatrix4fv @_flatShader.modelLocation, false, @_modelMatrix

    @_gl.drawArrays @_gl.TRIANGLES, 0, numMeshTriangles * 3
