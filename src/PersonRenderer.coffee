vec3 = require('gl-matrix').vec3
vec4 = require('gl-matrix').vec4
mat4 = require('gl-matrix').mat4

FlatShader = require('./FlatShader.coffee')
RoundedVoxelMesh = require('./RoundedVoxelMesh.coffee')

voxelURL = 'http://voxelbuilder.com/edit.html#C/2ecc713498db34495ee67e22ecf0f1000000:A/YhUhWhhSfSfWhiSfSfWhhUhSfUhWffWfhWffUfUeUhWhfUhWhhefciUhWfeUhUhShShSdSkUhSfSfSfSfWhhShShUhSfSfWhheiehUhWffUhSfUf'
voxelMesh = new RoundedVoxelMesh voxelURL, 0.25

module.exports = class PersonRenderer
  constructor: (@_gl) ->
    @_flatShader = new FlatShader @_gl
    @_color = vec4.fromValues(1, 1, 1, 1)

    @_meshBuffer = @_gl.createBuffer()
    @_gl.bindBuffer @_gl.ARRAY_BUFFER, @_meshBuffer
    @_gl.bufferData @_gl.ARRAY_BUFFER, new Float32Array(voxelMesh.triangleBuffer), @_gl.STATIC_DRAW

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

    @_gl.drawArrays @_gl.TRIANGLES, 0, voxelMesh.triangleCount * 3

    # body
    vec3.set(@_modelPosition, movable.position[0], movable.position[1], 0)

    mat4.identity(@_modelMatrix)
    mat4.translate(@_modelMatrix, @_modelMatrix, @_modelPosition)

    @_gl.uniform4fv @_flatShader.colorLocation, @_blackColor
    @_gl.uniformMatrix4fv @_flatShader.modelLocation, false, @_modelMatrix

    @_gl.drawArrays @_gl.TRIANGLES, 0, voxelMesh.triangleCount * 3
