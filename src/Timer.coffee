EventEmitter = require('events').EventEmitter

module.exports = class Timer
    constructor: () ->
        @_lastTime = null
        @stream = new EventEmitter()

    processTime: (time) ->
        if @_lastTime is null
            @_lastTime = time

        elapsedSeconds = Math.min(100, time - @_lastTime) / 1000 # limit to 100ms jitter
        @_lastTime = time

        @stream.emit 'elapsed', elapsedSeconds
