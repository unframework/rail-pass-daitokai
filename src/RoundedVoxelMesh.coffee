voxelCritterConvert = require('../voxelCritterConvert')
isosurface = require('isosurface')

module.exports = class RoundedVoxelMesh
  constructor: (voxelURL, voxelScale) ->
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

    @triangleCount = mesh.cells.length
    @triangleBuffer = []

    for c in mesh.cells
      if c.length is 3
        v0 = mesh.positions[c[0]]
        v1 = mesh.positions[c[1]]
        v2 = mesh.positions[c[2]]

        @triangleBuffer.push (v0[0] - voxelCW) * voxelScale
        @triangleBuffer.push (v0[2] - voxelCD) * voxelScale
        @triangleBuffer.push (v0[1]) * voxelScale

        @triangleBuffer.push (v1[0] - voxelCW) * voxelScale
        @triangleBuffer.push (v1[2] - voxelCD) * voxelScale
        @triangleBuffer.push (v1[1]) * voxelScale

        @triangleBuffer.push (v2[0] - voxelCW) * voxelScale
        @triangleBuffer.push (v2[2] - voxelCD) * voxelScale
        @triangleBuffer.push (v2[1]) * voxelScale
      else
        throw new Error('poly face')
