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

BRAND_LIST = [
  '渋谷系' # shibuya-kei
  'DEBUT!'
  'ゲーム24' # game
  'OH~寝湯' # neyu

  '富士山' # fuji
  '【カメラ店】' # camera
  'YESCO'
  'コンビニエンス' # konbi

  '塚森の^^' # tororu
  'ラーメン' # ramen
  '美味しい' # oishii
  'HPPY一番' # ichiban

  '電車でGO!' # densha
  'COHITEN'
  '偉大な広告' # ad
  'RP 大都会' # metro
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
      while count < BRAND_LIST.length
        do =>
          brandText = BRAND_LIST[count]
          photo = photoList.splice(Math.floor(Math.random() * photoList.length), 1)[0]

          url = 'https://farm' + photo.farm + '.staticflickr.com/' + photo.server + '/' + photo.id + '_' + photo.secret + '_q.jpg'
          whenFontsLoaded.then => @render brandText, url

        count += 1

      null # prevent collection

  render: (brandText, url) ->
    w = 135
    h = 75
    maxDim = Math.max w, h

    brandTextPosX = [0.333, 0.5, 0.666][Math.floor Math.random() * 3]
    brandTextPosY = [0.333, 0.5, 0.666][Math.floor Math.random() * 3]

    brandColor = new color.HSV(Math.random(), 0.8, 0.8).rgb()
    brandTintColor = brandColor.alpha(Math.random() * 0.3)
    brandTextBoxColor = brandColor.alpha(1 - Math.random() * 0.5)

    brandFontSize = 16 + Math.round(Math.random() * 5) * 2
    brandTextPaddingX = Math.round((0.2 + Math.random() * 0.3) * brandFontSize)
    brandTextPaddingY = Math.round((0.05 + Math.random() * 0.4) * brandFontSize)

    canvas = createCanvas w, h
    ctx = canvas.getContext '2d'

    document.body.appendChild canvas

    ImageLoader.load(url).then (img) ->
      ctx.drawImage img, (w - maxDim) / 2, (h - maxDim) / 2, maxDim, maxDim
      ctx.fillStyle = brandTintColor.cssa()
      ctx.fillRect 0, 0, w, h

      ctx.textAlign = 'center'
      ctx.textBaseline = 'middle'
      ctx.font = "bold #{brandFontSize}px 'Meiryo'"
      metrics = ctx.measureText brandText

      bgWidth = metrics.width + brandTextPaddingX * 2
      bgHeight = brandFontSize + brandTextPaddingY * 2

      bgMidX = w * brandTextPosX
      bgMidY = h * brandTextPosY
      bgMidX = Math.max(bgWidth * 0.5, bgMidX);
      bgMidX = Math.min(w - bgWidth * 0.5, bgMidX);
      bgMidY = Math.max(bgHeight * 0.5, bgMidY);
      bgMidY = Math.min(w - bgHeight * 0.5, bgMidY);

      ctx.save()
      ctx.fillStyle = brandTextBoxColor.cssa()
      ctx.moveTo bgMidX - bgWidth * 0.5, bgMidY - bgHeight * 0.5
      ctx.lineTo bgMidX + bgWidth * 0.5, bgMidY - bgHeight * 0.5
      ctx.lineTo bgMidX + bgWidth * 0.5, bgMidY + bgHeight * 0.5
      ctx.lineTo bgMidX - bgWidth * 0.5, bgMidY + bgHeight * 0.5
      ctx.closePath()
      ctx.fill()
      ctx.restore()

      ctx.save()
      ctx.fillStyle = '#fff'
      ctx.fillText brandText, bgMidX, bgMidY
      ctx.strokeStyle = '#000'
      ctx.lineWidth = "#{brandFontSize > 22 ? 2 : 1}px"
      ctx.strokeText brandText, bgMidX, bgMidY
      ctx.restore()
