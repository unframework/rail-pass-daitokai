Promise = require('bluebird')

module.exports.load = (imageURI) ->
  textureImage = new Image()
  textureImage.crossOrigin = "anonymous" # prevent "tainted canvas" warning when blitting this

  texturePromise = new Promise (resolve) ->
    textureImage.onload = ->
      resolve textureImage

  textureImage.src = imageURI
  texturePromise
