Readable = require('stream').Readable
Promise = require('bluebird')
parseOBJ = require('parse-obj')

createReadStream = (data) ->
  fileStream = new Readable
  fileStream._read = -> # no-op read

  fileStream.push data
  fileStream.push null

  fileStream

class OBJMesh
  constructor: (mesh, meshScale) ->
    @triangleCount = mesh.facePositions.length
    @triangleBuffer = []
    @triangleUVBuffer = []

    for tri in mesh.facePositions
      v0 = mesh.vertexPositions[tri[0]]
      v1 = mesh.vertexPositions[tri[1]]
      v2 = mesh.vertexPositions[tri[2]]

      @triangleBuffer.push v0[0] * meshScale
      @triangleBuffer.push v0[1] * meshScale
      @triangleBuffer.push v0[2] * meshScale

      @triangleBuffer.push v1[0] * meshScale
      @triangleBuffer.push v1[1] * meshScale
      @triangleBuffer.push v1[2] * meshScale

      @triangleBuffer.push v2[0] * meshScale
      @triangleBuffer.push v2[1] * meshScale
      @triangleBuffer.push v2[2] * meshScale

    for tri in mesh.faceUVs
      uv0 = mesh.vertexUVs[tri[0]]
      uv1 = mesh.vertexUVs[tri[1]]
      uv2 = mesh.vertexUVs[tri[2]]

      @triangleUVBuffer.push uv0[0]
      @triangleUVBuffer.push uv0[1]

      @triangleUVBuffer.push uv1[0]
      @triangleUVBuffer.push uv1[1]

      @triangleUVBuffer.push uv2[0]
      @triangleUVBuffer.push uv2[1]

module.exports.loadFromData = (data, meshScale) ->
  new Promise (resolve) ->
    parseOBJ createReadStream(data), (err, mesh) ->
      resolve new OBJMesh mesh, meshScale
