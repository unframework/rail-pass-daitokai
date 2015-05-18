
module.exports = class GradientShader
  constructor: (@_gl) ->
    vertexShader = @_gl.createShader(@_gl.VERTEX_SHADER)
    @_gl.shaderSource vertexShader, [
      'uniform mat4 camera;'
      'uniform mat4 model;'
      'uniform mediump vec4 colorTop;'
      'uniform mediump vec4 colorBottom;'
      'attribute vec4 position;'
      'varying vec4 color;'
      'void main() {'
      'gl_Position = camera * model * position;'
      'color = mix(colorBottom, colorTop, position.z);'
      '}'
    ].join ''
    @_gl.compileShader vertexShader
    # console.log(@_gl.getShaderInfoLog(vertexShader))

    fragmentShader = @_gl.createShader(@_gl.FRAGMENT_SHADER)
    @_gl.shaderSource fragmentShader, [
      'varying mediump vec4 color;'
      'void main() {'
      'gl_FragColor = color;'
      '}'
    ].join ''
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
    @positionLocation = @_gl.getAttribLocation(@_program, 'position')
    @colorTopLocation = @_gl.getUniformLocation(@_program, 'colorTop')
    @colorBottomLocation = @_gl.getUniformLocation(@_program, 'colorBottom')

  bind: ->
    @_gl.useProgram @_program
    @_gl.enableVertexAttribArray @positionLocation
