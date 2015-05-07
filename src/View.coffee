
vec3 = require('gl-matrix').vec3
vec4 = require('gl-matrix').vec4
mat4 = require('gl-matrix').mat4

createCanvas = ->
    viewCanvas = document.createElement('canvas')
    viewCanvas.style.position = 'fixed'
    viewCanvas.style.top = '0px'
    viewCanvas.style.left = '0px'
    viewCanvas.width = window.innerWidth
    viewCanvas.height = window.innerHeight

    viewCanvas

module.exports = class View
    constructor: (@_world) ->
        viewCanvas = createCanvas()
        document.body.appendChild viewCanvas

        @_gl = viewCanvas.getContext('experimental-webgl')

        vertexShader = @_gl.createShader(@_gl.VERTEX_SHADER)
        @_gl.shaderSource vertexShader, 'uniform mat4 camera; uniform mat4 model; attribute vec4 position; void main() { gl_Position = camera * model * position; }'
        @_gl.compileShader vertexShader
        # console.log(@_gl.getShaderInfoLog(vertexShader))

        fragmentShader = @_gl.createShader(@_gl.FRAGMENT_SHADER)
        @_gl.shaderSource fragmentShader, 'uniform mediump vec4 color; void main() { gl_FragColor = color; }'
        @_gl.compileShader fragmentShader
        # console.log(@_gl.getShaderInfoLog(fragmentShader))

        program = @_gl.createProgram()
        @_gl.attachShader program, vertexShader
        @_gl.attachShader program, fragmentShader
        @_gl.linkProgram program
        # console.log(@_gl.getProgramInfoLog(program));

        @_gl.useProgram program

        # look up where the vertex data needs to go.
        @_modelLocation = @_gl.getUniformLocation(program, 'model')
        @_cameraLocation = @_gl.getUniformLocation(program, 'camera')
        @_positionLocation = @_gl.getAttribLocation(program, 'position')
        @_colorLocation = @_gl.getUniformLocation(program, 'color')

        buffer = @_gl.createBuffer()
        @_gl.bindBuffer @_gl.ARRAY_BUFFER, buffer
        @_gl.bufferData @_gl.ARRAY_BUFFER, new Float32Array([
          -0.5, -0.5
          0.5, -0.5
          -0.5, 0.5
          -0.5, 0.5
          0.5, -0.5
          0.5, 0.5
        ]), @_gl.STATIC_DRAW
        @_gl.enableVertexAttribArray @_positionLocation
        @_gl.vertexAttribPointer @_positionLocation, 2, @_gl.FLOAT, false, 0, 0

        camera = mat4.create()
        cameraPosition = vec3.create()

        vec3.set cameraPosition, 0, 0, -8
        mat4.perspective camera, 45, window.innerWidth / window.innerHeight, 1, 10
        mat4.translate camera, camera, cameraPosition
        @_gl.uniformMatrix4fv @_cameraLocation, false, camera

    render: ->
        modelPosition = vec3.create()
        model = mat4.create()

        blackColor = vec4.fromValues(0, 0, 0, 1)
        grayColor = vec4.fromValues(0.5, 0.5, 0.5, 1)

        for m in @_world._movables
            vec3.set(modelPosition, m._cell.origin[0] + 0.5, m._cell.origin[1] + 0.5, 0)

            mat4.identity(model)
            mat4.translate(model, model, modelPosition)

            @_gl.uniform4fv @_colorLocation, grayColor
            @_gl.uniformMatrix4fv @_modelLocation, false, model
            @_gl.drawArrays @_gl.TRIANGLES, 0, 6

            vec3.set(modelPosition, m.position[0], m.position[1], 0)

            mat4.identity(model)
            mat4.translate(model, model, modelPosition)

            @_gl.uniform4fv @_colorLocation, blackColor
            @_gl.uniformMatrix4fv @_modelLocation, false, model
            @_gl.drawArrays @_gl.TRIANGLES, 0, 6

