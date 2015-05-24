flickrClient = require('flickr-client')
ImageLoader = require('./ImageLoader.coffee')

GROUP_ID = '906615@N24' # https://www.flickr.com/groups/japanese_food_lovers/

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

    @_flickr 'photos.search', { group_id: GROUP_ID, page: 2, per_page: 100 }, (error, response) =>
      if (error)
        throw new Error(error)

      photoList = response.photos.photo
      count = 0
      while count < 10
        count += 1
        photo = photoList.splice(Math.floor(Math.random() * photoList.length), 1)[0]

        url = 'https://farm' + photo.farm + '.staticflickr.com/' + photo.server + '/' + photo.id + '_' + photo.secret + '_q.jpg'
        @render url

  render: (url) ->
    w = 64
    h = 32
    maxDim = Math.max w, h

    canvas = createCanvas w, h
    ctx = canvas.getContext '2d'

    document.body.appendChild canvas

    ImageLoader.load(url).then (img) ->
      ctx.drawImage img, (w - maxDim) / 2, (h - maxDim) / 2, maxDim, maxDim
