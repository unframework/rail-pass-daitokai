color = require('onecolor')
flickrClient = require('flickr-client')
FontFaceObserver = require('fontfaceobserver')
fonts = require('google-fonts')
Promise = require('bluebird')

ImageLoader = require('./ImageLoader.coffee')

# get font going
fonts.add { 'Source Sans Pro': [ 600 ] }
whenFontsLoaded = new FontFaceObserver('Source Sans Pro').check()

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
        do =>
          photo = photoList.splice(Math.floor(Math.random() * photoList.length), 1)[0]

          url = 'https://farm' + photo.farm + '.staticflickr.com/' + photo.server + '/' + photo.id + '_' + photo.secret + '_q.jpg'
          whenFontsLoaded.then => @render url

      null # prevent collection

  render: (url) ->
    w = 135
    h = 75
    maxDim = Math.max w, h

    bgMidX = w * [0.333, 0.5, 0.666][Math.floor Math.random() * 3]
    bgMidY = h * [0.333, 0.5, 0.666][Math.floor Math.random() * 3]

    bgColor = new color.HSV(Math.random(), 0.8, 0.8).rgb()
    tintAlpha = Math.random() * 0.3

    canvas = createCanvas w, h
    ctx = canvas.getContext '2d'

    document.body.appendChild canvas

    ImageLoader.load(url).then (img) ->
      ctx.drawImage img, (w - maxDim) / 2, (h - maxDim) / 2, maxDim, maxDim
      ctx.fillStyle = bgColor.alpha(tintAlpha).cssa()
      ctx.fillRect 0, 0, w, h

      posterHeadline = '渋谷系'
      fontSize = 14 + Math.round(Math.random() * 4) * 2
      paddingX = Math.round((0.2 + Math.random() * 0.3) * fontSize)
      paddingY = Math.round((0.05 + Math.random() * 0.4) * fontSize)

      ctx.textAlign = 'center'
      ctx.textBaseline = 'middle'
      ctx.font = "bold #{fontSize}px 'Meiryo'"
      metrics = ctx.measureText posterHeadline

      bgWidth = metrics.width + paddingX * 2
      bgHeight = fontSize + paddingY * 2

      bgMidX = Math.max(bgWidth * 0.5, bgMidX);
      bgMidX = Math.min(w - bgWidth * 0.5, bgMidX);
      bgMidY = Math.max(bgHeight * 0.5, bgMidY);
      bgMidY = Math.min(w - bgHeight * 0.5, bgMidY);

      ctx.save()
      ctx.fillStyle = bgColor.alpha(1 - Math.random() * 0.5).cssa()
      ctx.moveTo bgMidX - bgWidth * 0.5, bgMidY - bgHeight * 0.5
      ctx.lineTo bgMidX + bgWidth * 0.5, bgMidY - bgHeight * 0.5
      ctx.lineTo bgMidX + bgWidth * 0.5, bgMidY + bgHeight * 0.5
      ctx.lineTo bgMidX - bgWidth * 0.5, bgMidY + bgHeight * 0.5
      ctx.closePath()
      ctx.fill()
      ctx.restore()

      ctx.save()
      ctx.fillStyle = '#fff'
      ctx.fillText posterHeadline, bgMidX, bgMidY
      ctx.strokeStyle = '#000'
      ctx.lineWidth = "#{fontSize > 18 ? 2 : 1}px"
      ctx.strokeText posterHeadline, bgMidX, bgMidY
      ctx.restore()
