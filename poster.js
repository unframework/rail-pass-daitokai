
var flickrConfig = require('./flickr');
var PosterGenerator = require('./src/PosterGenerator.coffee');

var generator = new PosterGenerator(75, 128, flickrConfig);

generator.whenReady.then(function (canvas) {
    document.body.appendChild(canvas);
});
