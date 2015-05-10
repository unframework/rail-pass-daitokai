vec3 = require('gl-matrix').vec3
vec4 = require('gl-matrix').vec4
mat4 = require('gl-matrix').mat4
voxelCritterConvert = require('../voxelCritterConvert')
isosurface = require('isosurface')

FlatShader = require('./FlatShader.coffee')

voxelScale = 0.25
voxelURL = 'http://voxelbuilder.com/edit.html#C/2ecc713498db34495ee67e22ecf0f1000000:A/YhUhWhhSfSfWhiSfSfWhhUhSfUhWffWfhWffUfUeUhWhfUhWhhefciUhWfeUhUhShShSdSkUhSfSfSfSfWhhShShUhSfSfWhheiehUhWffUhSfUf'

voxelModel = voxelCritterConvert.toVoxels(voxelURL.split('#').pop());

lBound = voxelModel.bounds[0]
hBound = voxelModel.bounds[1]

voxelW = hBound[0] - lBound[0] + 1
voxelH = hBound[1] - lBound[1] + 1
voxelD = hBound[2] - lBound[2] + 1

voxelCW = lBound[0] + (hBound[0] - lBound[0]) / 2
voxelCH = lBound[1] + (hBound[1] - lBound[1]) / 2
voxelCD = lBound[2] + (hBound[2] - lBound[2]) / 2

mesh = isosurface.surfaceNets [voxelW + 2, voxelH + 2, voxelD + 2], (x, y, z) ->
  if x < lBound[0] or y < lBound[1] or z < lBound[2]
    -0.5
  else if x >= hBound[0] + 1 or y >= hBound[1] + 1 or z >= hBound[2] + 1
    -0.5
  else
    if voxelModel.voxels[x + '|' + y + '|' + z] is 0
      0.5
    else
      -0.5
, [[lBound[0] - 1, lBound[1] - 1, lBound[2] - 1], [hBound[0] + 2, hBound[1] + 2, hBound[2] + 2]]

meshTriangleVertexData = []

for c in mesh.cells
  if c.length is 3
    v0 = mesh.positions[c[0]]
    v1 = mesh.positions[c[1]]
    v2 = mesh.positions[c[2]]

    meshTriangleVertexData.push (v0[0] - voxelCW) * voxelScale
    meshTriangleVertexData.push (v0[2] - voxelCD) * voxelScale
    meshTriangleVertexData.push (v0[1]) * voxelScale

    meshTriangleVertexData.push (v1[0] - voxelCW) * voxelScale
    meshTriangleVertexData.push (v1[2] - voxelCD) * voxelScale
    meshTriangleVertexData.push (v1[1]) * voxelScale

    meshTriangleVertexData.push (v2[0] - voxelCW) * voxelScale
    meshTriangleVertexData.push (v2[2] - voxelCD) * voxelScale
    meshTriangleVertexData.push (v2[1]) * voxelScale
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
