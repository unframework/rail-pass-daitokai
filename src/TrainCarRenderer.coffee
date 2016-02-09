fs = require('fs')
vec3 = require('gl-matrix').vec3
vec4 = require('gl-matrix').vec4
mat4 = require('gl-matrix').mat4

GradientShader = require('./GradientShader.coffee')
FlatTextureShader = require('./FlatTextureShader.coffee')
PosterGenerator = require('./PosterGenerator.coffee')
OBJLoader = require('./OBJLoader.coffee')

flickrConfig = require('../flickr')
topPosterPromise = new PosterGenerator(128, 64, flickrConfig).whenReady
sidePosterPromise = new PosterGenerator(128, 128, flickrConfig).whenReady

meshHeight = 2.5
wallMeshPromise = new OBJLoader.loadFromData fs.readFileSync(__dirname + '/trainCarWall.obj'), 1 / meshHeight
capMeshPromise = new OBJLoader.loadFromData fs.readFileSync(__dirname + '/trainCarCap.obj'), 1 / meshHeight

POSTER_MESH_TRIANGLE_DATA = [
  -0.5, 0, 0
  0.5, 0, 0
  -0.5, 0, 1
  -0.5, 0, 1
  0.5, 0, 0
  0.5, 0, 1
]
POSTER_MESH_TRIANGLE_COUNT = 2

TOP_POSTER_UV_W = 128
TOP_POSTER_UV_H = 64

TOP_POSTER_LIST = [
  # midway
  [ vec3.fromValues(0.5, 0, 2.1), vec3.fromValues(1, 1, 0.4), 0 ]
  [ vec3.fromValues(1.5, 0, 2.1), vec3.fromValues(1, 1, 0.4), 0 ]
  [ vec3.fromValues(0.5, 3, 2.1), vec3.fromValues(1, 1, 0.4), 0 ]
  [ vec3.fromValues(1.5, 3, 2.1), vec3.fromValues(1, 1, 0.4), 0 ]
  [ vec3.fromValues(0.5, 6, 2.1), vec3.fromValues(1, 1, 0.4), 0 ]
  [ vec3.fromValues(1.5, 6, 2.1), vec3.fromValues(1, 1, 0.4), 0 ]
]

SIDE_POSTER_UV_W = 128
SIDE_POSTER_UV_H = 128

SIDE_POSTER_LIST = [
  # left side
  [ vec3.fromValues(-0.5 + 0.005, -1.05, 0.9), vec3.fromValues(0.5, 1, 0.9), Math.PI / 2 ]
  [ vec3.fromValues(-0.5 + 0.005, 1.05, 0.9), vec3.fromValues(0.5, 1, 0.9), Math.PI / 2 ]
  [ vec3.fromValues(-0.5 + 0.005, 4.95, 0.9), vec3.fromValues(0.5, 1, 0.9), Math.PI / 2 ]
  [ vec3.fromValues(-0.5 + 0.005, 7.05, 0.9), vec3.fromValues(0.5, 1, 0.9), Math.PI / 2 ]

  # right side
  [ vec3.fromValues(2.5 - 0.005, -1.05, 0.9), vec3.fromValues(0.5, 1, 0.9), -Math.PI / 2 ]
  [ vec3.fromValues(2.5 - 0.005, 1.05, 0.9), vec3.fromValues(0.5, 1, 0.9), -Math.PI / 2 ]
  [ vec3.fromValues(2.5 - 0.005, 4.95, 0.9), vec3.fromValues(0.5, 1, 0.9), -Math.PI / 2 ]
  [ vec3.fromValues(2.5 - 0.005, 7.05, 0.9), vec3.fromValues(0.5, 1, 0.9), -Math.PI / 2 ]
]

generateUVBuffers = (gl, w, h) ->
  canvasW = w * 4
  canvasH = h * 4

  for index in [0 .. 4 * 4 - 1]
    u1 = (index % 4) * w
    v1 = Math.floor(index / 4) * h
    u2 = u1 + w
    v2 = v1 + h

    uvBuf = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, uvBuf
    gl.bufferData gl.ARRAY_BUFFER, new Float32Array([
      u1 / canvasW, v1 / canvasH
      u2 / canvasW, v1 / canvasH
      u1 / canvasW, v2 / canvasH
      u1 / canvasW, v2 / canvasH
      u2 / canvasW, v1 / canvasH
      u2 / canvasW, v2 / canvasH
    ]), gl.STATIC_DRAW

    uvBuf

module.exports = class TrainCarRenderer
  constructor: (@_gl) ->
    @_gradientShader = new GradientShader @_gl
    @_texShader = new FlatTextureShader @_gl

    @_posterMeshBuffer = @_gl.createBuffer()
    @_gl.bindBuffer @_gl.ARRAY_BUFFER, @_posterMeshBuffer
    @_gl.bufferData @_gl.ARRAY_BUFFER, new Float32Array(POSTER_MESH_TRIANGLE_DATA), @_gl.STATIC_DRAW

    topPosterUVCandidateList = generateUVBuffers @_gl, TOP_POSTER_UV_W, TOP_POSTER_UV_H
    @_topPosterUVBufferList = for index in [0 .. TOP_POSTER_LIST.length - 1]
      topPosterUVCandidateList.splice(Math.floor(Math.random() * topPosterUVCandidateList.length), 1)[0]

    sidePosterUVCandidateList = generateUVBuffers @_gl, SIDE_POSTER_UV_W, SIDE_POSTER_UV_H
    @_sidePosterUVBufferList = for index in [0 .. SIDE_POSTER_LIST.length - 1]
      sidePosterUVCandidateList.splice(Math.floor(Math.random() * sidePosterUVCandidateList.length), 1)[0]

    @_modelPosition = vec3.create()
    @_modelScale = vec3.fromValues(meshHeight, meshHeight, meshHeight)
    @_modelFlipScale = vec3.fromValues(-meshHeight, -meshHeight, meshHeight)
    @_modelMatrix = mat4.create()

    @_color = vec4.fromValues(0.85, 0.85, 0.9, 1)
    @_color2 = vec4.fromValues(0.3, 0.3, 0.3, 1)

    @_posterColor = vec4.fromValues(1, 1, 1, 1)
    @_topPosterTexture = null
    @_sidePosterTexture = null

    @_sidePosterScale = vec3.fromValues(0.5, 1, 0.9)

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

        topPosterPromise.then (canvas) =>
          @_topPosterTexture = @_gl.createTexture()

          @_gl.bindTexture(@_gl.TEXTURE_2D, @_topPosterTexture)
          @_gl.pixelStorei(@_gl.UNPACK_FLIP_Y_WEBGL, true)
          @_gl.texImage2D(@_gl.TEXTURE_2D, 0, @_gl.RGBA, @_gl.RGBA, @_gl.UNSIGNED_BYTE, canvas)
          @_gl.texParameteri(@_gl.TEXTURE_2D, @_gl.TEXTURE_MAG_FILTER, @_gl.NEAREST)
          @_gl.texParameteri(@_gl.TEXTURE_2D, @_gl.TEXTURE_MIN_FILTER, @_gl.NEAREST)
          @_gl.texParameteri(@_gl.TEXTURE_2D, @_gl.TEXTURE_WRAP_S, @_gl.REPEAT)
          @_gl.texParameteri(@_gl.TEXTURE_2D, @_gl.TEXTURE_WRAP_T, @_gl.REPEAT)

          sidePosterPromise.then (canvas) =>
            @_sidePosterTexture = @_gl.createTexture()

            @_gl.bindTexture(@_gl.TEXTURE_2D, @_sidePosterTexture)
            @_gl.pixelStorei(@_gl.UNPACK_FLIP_Y_WEBGL, true)
            @_gl.texImage2D(@_gl.TEXTURE_2D, 0, @_gl.RGBA, @_gl.RGBA, @_gl.UNSIGNED_BYTE, canvas)
            @_gl.texParameteri(@_gl.TEXTURE_2D, @_gl.TEXTURE_MAG_FILTER, @_gl.NEAREST)
            @_gl.texParameteri(@_gl.TEXTURE_2D, @_gl.TEXTURE_MIN_FILTER, @_gl.NEAREST)
            @_gl.texParameteri(@_gl.TEXTURE_2D, @_gl.TEXTURE_WRAP_S, @_gl.REPEAT)
            @_gl.texParameteri(@_gl.TEXTURE_2D, @_gl.TEXTURE_WRAP_T, @_gl.REPEAT)


  draw: (cameraMatrix, car) ->
    if !@_wallMeshBuffer or !@_capMeshBuffer
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

    # posters
    @_texShader.bind()

    @_gl.uniformMatrix4fv @_texShader.cameraLocation, false, cameraMatrix

    @_gl.bindBuffer @_gl.ARRAY_BUFFER, @_posterMeshBuffer
    @_gl.vertexAttribPointer @_texShader.positionLocation, 3, @_gl.FLOAT, false, 0, 0

    @_gl.uniform4fv @_texShader.colorLocation, @_posterColor

    @_gl.bindTexture @_gl.TEXTURE_2D, @_topPosterTexture
    @_gl.uniform1i(@_texShader.textureLocation, 0)

    for posterInfo, posterIndex in TOP_POSTER_LIST
      @_gl.bindBuffer @_gl.ARRAY_BUFFER, @_topPosterUVBufferList[posterIndex]
      @_gl.vertexAttribPointer @_texShader.uvPositionLocation, 2, @_gl.FLOAT, false, 0, 0

      mat4.identity(@_modelMatrix)
      mat4.translate(@_modelMatrix, @_modelMatrix, posterInfo[0])
      mat4.rotateZ(@_modelMatrix, @_modelMatrix, posterInfo[2])
      mat4.scale(@_modelMatrix, @_modelMatrix, posterInfo[1])
      @_gl.uniformMatrix4fv @_texShader.modelLocation, false, @_modelMatrix

      @_gl.drawArrays @_gl.TRIANGLES, 0, POSTER_MESH_TRIANGLE_COUNT * 3

    @_gl.bindTexture @_gl.TEXTURE_2D, @_sidePosterTexture
    @_gl.uniform1i(@_texShader.textureLocation, 0)

    for posterInfo, posterIndex in SIDE_POSTER_LIST
      @_gl.bindBuffer @_gl.ARRAY_BUFFER, @_sidePosterUVBufferList[posterIndex]
      @_gl.vertexAttribPointer @_texShader.uvPositionLocation, 2, @_gl.FLOAT, false, 0, 0

      mat4.identity(@_modelMatrix)
      mat4.translate(@_modelMatrix, @_modelMatrix, posterInfo[0])
      mat4.rotateZ(@_modelMatrix, @_modelMatrix, posterInfo[2])
      mat4.scale(@_modelMatrix, @_modelMatrix, posterInfo[1])
      @_gl.uniformMatrix4fv @_texShader.modelLocation, false, @_modelMatrix

      @_gl.drawArrays @_gl.TRIANGLES, 0, POSTER_MESH_TRIANGLE_COUNT * 3
