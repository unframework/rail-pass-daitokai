
var flickrConfig = require('./flickr');
var PosterGenerator = require('./src/PosterGenerator.coffee');

var generator = new PosterGenerator(flickrConfig);

generator.whenReady.then(function (canvas) {
    document.body.appendChild(canvas);
});
