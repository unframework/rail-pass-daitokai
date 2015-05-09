Promise = require('bluebird')

module.exports.load = (imageURI) ->
  textureImage = new Image()

  texturePromise = new Promise (resolve) ->
    textureImage.onload = ->
      resolve textureImage

  textureImage.src = imageURI
  texturePromise
