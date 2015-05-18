fs = require('fs')
vec3 = require('gl-matrix').vec3
vec4 = require('gl-matrix').vec4
mat4 = require('gl-matrix').mat4

FlatTexturePersonShader = require('./FlatTexturePersonShader.coffee')
OBJLoader = require('./OBJLoader.coffee')
ImageLoader = require('./ImageLoader.coffee')

textureImageURI = 'data:application/octet-stream;base64,' + btoa(require('fs').readFileSync(__dirname + '/person.png', 'binary'))
textureImagePromise = ImageLoader.load textureImageURI

meshHeight = 1.35
meshPromise = new OBJLoader.loadFromData fs.readFileSync(__dirname + '/personStanding.obj'), 1 / meshHeight

module.exports = class PersonRenderer
  constructor: (@_gl) ->
    @_flatShader = new FlatTexturePersonShader @_gl
    @_color = vec4.fromValues(1, 1, 1, 1)
    @_up = vec3.fromValues(0, 0, 1)

    @_modelPosition = vec3.create()
    @_modelScale = vec3.fromValues(meshHeight, meshHeight, meshHeight)
    @_modelMatrix = mat4.create()
    @_deformTopPosition = vec3.create()
    @_deformTopMatrix = mat4.create()
    @_deformBottomMatrix = mat4.create()

    # mat4.rotateZ @_deformBottomMatrix, @_deformBottomMatrix, 0.2
    # mat4.rotateZ @_deformTopMatrix, @_deformTopMatrix, -0.2

    @_color = vec4.create()

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
    mat4.scale(@_modelMatrix, @_modelMatrix, @_modelScale)

    walkCycleAngle = person.walkCycle * Math.PI * 2
    vec3.set(@_deformTopPosition, 0, Math.sin(walkCycleAngle) * 0.01, 0)

    mat4.identity(@_deformTopMatrix)
    mat4.translate(@_deformTopMatrix, @_deformTopMatrix, @_deformTopPosition)
    @_gl.uniformMatrix4fv @_flatShader.deformTopLocation, false, @_deformTopMatrix

    mat4.identity(@_deformBottomMatrix)
    mat4.rotateZ(@_deformBottomMatrix, @_deformBottomMatrix, -Math.sin(walkCycleAngle) * 0.05)
    @_gl.uniformMatrix4fv @_flatShader.deformBottomLocation, false, @_deformBottomMatrix

    vec4.set(@_color, person.color.red(), person.color.green(), person.color.blue(), 1)
    @_gl.uniform4fv @_flatShader.colorTopLocation, @_color
    vec4.set(@_color, person.color2.red(), person.color2.green(), person.color2.blue(), 1)
    @_gl.uniform4fv @_flatShader.colorBottomLocation, @_color

    @_gl.uniformMatrix4fv @_flatShader.modelLocation, false, @_modelMatrix

    @_gl.drawArrays @_gl.TRIANGLES, 0, @_meshTriangleCount * 3
