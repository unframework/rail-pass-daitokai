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
  constructor: (w, h, flickrConfig) ->
    @_flickr = flickrClient {
      key: flickrConfig.key
    }

    canvas = createCanvas w * 4, h * 4
    ctx = canvas.getContext '2d'

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
    whenRendered = whenPhotoListsLoaded.then (listOfLists) =>
      photoList = [].concat listOfLists...

      renderPromiseList = for count in [0 .. BRAND_LIST.length - 1]
        do =>
          x = (count % 4) * w
          y = Math.floor(count / 4) * h
          brandText = BRAND_LIST[count]
          photo = photoList.splice(Math.floor(Math.random() * photoList.length), 1)[0]

          url = 'https://farm' + photo.farm + '.staticflickr.com/' + photo.server + '/' + photo.id + '_' + photo.secret + '_q.jpg'
          ImageLoader.load(url).then (img) =>
            whenFontsLoaded.then =>
              @render ctx, x, y, w, h, brandText, img

      Promise.all renderPromiseList

    @whenReady = whenRendered.then -> canvas

  render: (ctx, x, y, w, h, brandText, img) ->
    brandTextPosX = [0, 0.5, 1][Math.floor Math.random() * 3]
    brandTextPosY = [0.333, 0.5, 0.666][Math.floor Math.random() * 3]

    brandColorH = Math.random()
    brandColor = new color.HSV(brandColorH, 0.8, 0.8).rgb()
    brandTextLightness = [0, 0.5, 1][Math.floor Math.random() * 3]
    brandTextColor = new color.HSL(brandColorH + 10.5, 0.6, brandTextLightness).rgb()
    brandTintColor = brandColor.alpha(Math.random() * 0.3)
    brandTextBoxColor = brandColor.alpha(1 - Math.random() * 0.5)

    brandFontSize = 10 + Math.round(Math.random() * 4) * 2
    brandTextPaddingX = Math.round((0.2 + Math.random() * 0.3) * brandFontSize)
    brandTextPaddingY = Math.round((0.05 + Math.random() * 0.4) * brandFontSize)

    ctx.save() # main save
    ctx.translate x, y

    ctx.beginPath()
    ctx.rect 0, 0, w, h
    ctx.clip()

    IMG_W = 150
    IMG_H = 150

    ctx.drawImage img, w / 2 - IMG_W / 2, h / 2 - IMG_H / 2
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
    bgMidY = Math.min(h - bgHeight * 0.5, bgMidY);

    ctx.save()
    ctx.fillStyle = brandTextBoxColor.cssa()
    ctx.beginPath()
    ctx.moveTo bgMidX - bgWidth * 0.5, bgMidY - bgHeight * 0.5
    ctx.lineTo bgMidX + bgWidth * 0.5, bgMidY - bgHeight * 0.5
    ctx.lineTo bgMidX + bgWidth * 0.5, bgMidY + bgHeight * 0.5
    ctx.lineTo bgMidX - bgWidth * 0.5, bgMidY + bgHeight * 0.5
    ctx.closePath()
    ctx.fill()
    ctx.restore()

    ctx.save()
    ctx.fillStyle = brandTextColor.cssa()
    ctx.fillText brandText, bgMidX, bgMidY
    if brandTextLightness isnt 0.5 and brandFontSize > 15
      ctx.strokeStyle = new color.HSL(0, 0, 1 - brandTextLightness).rgb().alpha(0.6).cssa()
      ctx.lineWidth = "2px"
      ctx.strokeText brandText, bgMidX, bgMidY
    ctx.restore()

    ctx.restore() # main restore
