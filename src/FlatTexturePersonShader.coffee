
module.exports = class FlatTexturePersonShader
  constructor: (@_gl) ->
    vertexShader = @_gl.createShader(@_gl.VERTEX_SHADER)
    @_gl.shaderSource vertexShader, [
        'uniform mat4 camera;'
        'uniform mat4 model;'
        'uniform mat4 deformTop;'
        'uniform mat4 deformBottom;'
        'uniform mediump vec4 colorTop;'
        'uniform mediump vec4 colorBottom;'
        'attribute vec4 position;'
        'attribute vec2 uvPosition;'
        'varying vec2 uv;'
        'varying vec4 color;'
        'void main() {'
        'vec4 deformedTop = deformTop * position;'
        'vec4 deformedBottom = deformBottom * position;'
        'gl_Position = camera * model * mix(deformedBottom, deformedTop, position.z);'
        'color = mix(colorBottom, colorTop, position.z);'
        'uv = uvPosition;'
        '}'
    ].join ''
    @_gl.compileShader vertexShader
    # console.log(@_gl.getShaderInfoLog(vertexShader))

    fragmentShader = @_gl.createShader(@_gl.FRAGMENT_SHADER)
    @_gl.shaderSource fragmentShader, [
        'varying mediump vec4 color;'
        'varying mediump vec2 uv;'
        'uniform sampler2D texture;'
        'void main() {'
        'gl_FragColor = texture2D(texture, uv) * color;'
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
    @deformTopLocation = @_gl.getUniformLocation(@_program, 'deformTop')
    @deformBottomLocation = @_gl.getUniformLocation(@_program, 'deformBottom')
    @modelLocation = @_gl.getUniformLocation(@_program, 'model')
    @cameraLocation = @_gl.getUniformLocation(@_program, 'camera')
    @uvPositionLocation = @_gl.getAttribLocation(@_program, 'uvPosition')
    @positionLocation = @_gl.getAttribLocation(@_program, 'position')
    @colorTopLocation = @_gl.getUniformLocation(@_program, 'colorTop')
    @colorBottomLocation = @_gl.getUniformLocation(@_program, 'colorBottom')
    @textureLocation = @_gl.getUniformLocation(@_program, 'texture')

    @_gl.enableVertexAttribArray @positionLocation
    @_gl.enableVertexAttribArray @uvPositionLocation

  bind: ->
    @_gl.useProgram @_program
