
module.exports = class FlatTextureShader
  constructor: (@_gl) ->
    vertexShader = @_gl.createShader(@_gl.VERTEX_SHADER)
    @_gl.shaderSource vertexShader, 'uniform mat4 camera; uniform mat4 model; attribute vec4 position; attribute vec2 uvPosition; varying vec2 uv; void main() { gl_Position = camera * model * position; uv = uvPosition; }'
    @_gl.compileShader vertexShader
    # console.log(@_gl.getShaderInfoLog(vertexShader))

    fragmentShader = @_gl.createShader(@_gl.FRAGMENT_SHADER)
    @_gl.shaderSource fragmentShader, 'uniform mediump vec4 color; varying mediump vec2 uv; uniform sampler2D texture; void main() { gl_FragColor = texture2D(texture, uv) * color; }'
    @_gl.compileShader fragmentShader
    # console.log(@_gl.getShaderInfoLog(fragmentShader))

    @_program = @_gl.createProgram()
    @_gl.attachShader @_program, vertexShader
    @_gl.attachShader @_program, fragmentShader
    @_gl.linkProgram @_program
    # console.log(@_gl.getProgramInfoLog(@_program));

    # look up where the vertex data needs to go.
    @modelLocation = @_gl.getUniformLocation(@_program, 'model')
    @cameraLocation = @_gl.getUniformLocation(@_program, 'camera')
    @uvPositionLocation = @_gl.getAttribLocation(@_program, 'uvPosition')
    @positionLocation = @_gl.getAttribLocation(@_program, 'position')
    @colorLocation = @_gl.getUniformLocation(@_program, 'color')
    @textureLocation = @_gl.getUniformLocation(@_program, 'texture')

    @_gl.enableVertexAttribArray @positionLocation
    @_gl.enableVertexAttribArray @uvPositionLocation

  bind: ->
    @_gl.useProgram @_program
