color = require('onecolor')
flickrClient = require('flickr-client')
ImageLoader = require('./ImageLoader.coffee')
Promise = require('bluebird')

# to get group ID, inspect its avatar pic, the 'X@Y' portion of the URL is it, no underscores
GROUP_ID_LIST = [
  '906615@N24' # https://www.flickr.com/groups/japanese_food_lovers/
  '97292664@N00' # https://www.flickr.com/groups/jlandscape/
]

createCanvas = (w, h) ->
  viewCanvas = document.createElement('canvas')
  viewCanvas.width = w
  viewCanvas.height = h
  viewCanvas

module.exports = class PosterGenerator
  constructor: (flickrConfig) ->
    @_flickr = flickrClient {
      key: flickrConfig.key
    }

    # grab several groups
    whenPhotoListsLoaded = Promise.all (for groupId in GROUP_ID_LIST
      new Promise (resolve, reject) =>
        @_flickr 'photos.search', { group_id: groupId, page: 2, per_page: 50 }, (error, response) =>
          if (error)
            reject error
          else
            resolve response.photos.photo
    )

    # then pick from flattened set
    whenPhotoListsLoaded.then (listOfLists) =>
      photoList = [].concat listOfLists...

      count = 0
      while count < 10
        count += 1
        photo = photoList.splice(Math.floor(Math.random() * photoList.length), 1)[0]

        url = 'https://farm' + photo.farm + '.staticflickr.com/' + photo.server + '/' + photo.id + '_' + photo.secret + '_q.jpg'
        @render url

  render: (url) ->
    w = 100
    h = 100
    maxDim = Math.max w, h

    bgMidX = w * [0.333, 0.5, 0.666][Math.floor Math.random() * 3]
    bgMidY = h * [0.333, 0.5, 0.666][Math.floor Math.random() * 3]

    bgColor = new color.HSV(Math.random(), 0.8, 0.8).rgb()
    bgWidth = w * (0.3 + Math.random() * 0.3)
    bgHeight = h * (0.2 + Math.random() * 0.3)
    tintAlpha = Math.random() * 0.3

    canvas = createCanvas w, h
    ctx = canvas.getContext '2d'

    document.body.appendChild canvas

    ImageLoader.load(url).then (img) ->
      ctx.drawImage img, (w - maxDim) / 2, (h - maxDim) / 2, maxDim, maxDim
      ctx.fillStyle = bgColor.alpha(tintAlpha).cssa()
      ctx.fillRect 0, 0, w, h

      ctx.save()
      ctx.fillStyle = bgColor.cssa()
      ctx.moveTo bgMidX - bgWidth * 0.5, bgMidY - bgHeight * 0.5
      ctx.lineTo bgMidX + bgWidth * 0.5, bgMidY - bgHeight * 0.5
      ctx.lineTo bgMidX + bgWidth * 0.5, bgMidY + bgHeight * 0.5
      ctx.lineTo bgMidX - bgWidth * 0.5, bgMidY + bgHeight * 0.5
      ctx.closePath()
      ctx.fill()
      ctx.restore()