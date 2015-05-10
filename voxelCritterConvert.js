// from https://github.com/shama/voxel-critter/blob/master/lib/convert.js

var Convert = {};

Convert.toVoxels = function(hash, done) {
  var hashChunks = hash.split(':');
  var chunks = {};
  var colors = [0x000000];

  for (var j = 0; j < hashChunks.length; j++) {
    chunks[hashChunks[j][0]] = hashChunks[j].substr(2);
  }

  if (chunks['C']) {
    // decode colors
    colors = [];
    var hexColors = chunks['C'];
    for(var c = 0, nC = hexColors.length/6; c < nC; c++) {
      var hex = hexColors.substr(c * 6, 6);
      colors[c] = this.hex2rgb(hex);
    }
  }

  if (chunks['A']) {
    // decode geo
    var current = [0, 0, 0, 0];
    var data = this.decode(chunks['A']);
    var i = 0, l = data.length;
    var voxels = Object.create(null);
    var bounds = [[-1, -1, -1], [1, 1, 1]];

    while (i < l) {
      var code = data[i++].toString(2);
      if (code.charAt(1) === '1') current[0] += data[i++] - 32;
      if (code.charAt(2) === '1') current[1] += data[i++] - 32;
      if (code.charAt(3) === '1') current[2] += data[i++] - 32;
      if (code.charAt(4) === '1') current[3] += data[i++] - 32;
      if (code.charAt(0) === '1') {
        if (current[0] < 0 && current[0] < bounds[0][0]) bounds[0][0] = current[0];
        if (current[0] > 0 && current[0] > bounds[1][0]) bounds[1][0] = current[0];
        if (current[1] < 0 && current[1] < bounds[0][1]) bounds[0][1] = current[1];
        if (current[1] > 0 && current[1] > bounds[1][1]) bounds[1][1] = current[1];
        if (current[2] < 0 && current[2] < bounds[0][2]) bounds[0][2] = current[2];
        if (current[2] > 0 && current[2] > bounds[1][2]) bounds[1][2] = current[2];
        voxels[current.slice(0, 3).join('|')] = current.slice(3)[0];
      }
    }
  }

  return { voxels: voxels, colors: colors, bounds: bounds };
}

Convert.hex2rgb = function(hex) {
  if (hex[0] === '#') hex = hex.substr(1);
  return [parseInt(hex.substr(0,2), 16)/255, parseInt(hex.substr(2,2), 16)/255, parseInt(hex.substr(4,2), 16)/255];
}

Convert.decode = function(string) {
  var output = [];
  string.split('').forEach(function(v) {
    output.push("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".indexOf(v));
  });
  return output;
}

module.exports = Convert;