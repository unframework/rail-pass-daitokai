var requestAnimationFrame = require('raf');
var vec3 = require('gl-matrix').vec3;
var mat4 = require('gl-matrix').mat4;

var viewCanvas = document.createElement('canvas');
viewCanvas.style.position = 'fixed';
viewCanvas.style.top = '0px';
viewCanvas.style.left = '0px';
viewCanvas.style.width = '100%';
viewCanvas.style.height = '100%';
viewCanvas.width = window.innerWidth;
viewCanvas.height = window.innerHeight;
document.body.appendChild(viewCanvas);

var gl = viewCanvas.getContext("experimental-webgl");

var vertexShader = gl.createShader(gl.VERTEX_SHADER);
gl.shaderSource(vertexShader, 'uniform mat4 projection; uniform mat4 model; attribute vec4 position; void main() { gl_Position = projection * model * position; }');
gl.compileShader(vertexShader);

// console.log(gl.getShaderInfoLog(vertexShader));

var fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);
gl.shaderSource(fragmentShader, 'void main() { gl_FragColor = vec4(0, 0, 0, 1); }');
gl.compileShader(fragmentShader);

// console.log(gl.getShaderInfoLog(fragmentShader));

var program = gl.createProgram();
gl.attachShader(program, vertexShader);
gl.attachShader(program, fragmentShader);
gl.linkProgram(program);

// console.log(gl.getProgramInfoLog(program));

gl.useProgram(program);

// look up where the vertex data needs to go.
var modelLocation = gl.getUniformLocation(program, "model");
var projectionLocation = gl.getUniformLocation(program, "projection");
var positionLocation = gl.getAttribLocation(program, "position");

var buffer = gl.createBuffer();
gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([
   -0.5, -0.5,
    0.5, -0.5,
   -0.5,  0.5,
   -0.5,  0.5,
    0.5, -0.5,
    0.5,  0.5
]), gl.STATIC_DRAW);

gl.enableVertexAttribArray(positionLocation);
gl.vertexAttribPointer(positionLocation, 2, gl.FLOAT, false, 0, 0);

var persp = mat4.create();
mat4.perspective(persp, 45, window.innerWidth / window.innerHeight, 1, 10);
gl.uniformMatrix4fv(projectionLocation, false, persp);

var position = vec3.create();
vec3.set(position, 0, 0, -1.01);

var model = mat4.create();
mat4.translate(model, model, position);
gl.uniformMatrix4fv(modelLocation, false, model);

requestAnimationFrame(function (time) {
    var renderer = arguments.callee;
    var lastTime = renderer.lastTime || time;

    var elapsedSeconds = Math.min(100, time - lastTime) / 1000; // limit to 100ms jitter

    renderer.lastTime = time;

    gl.drawArrays(gl.TRIANGLES, 0, 6);

    requestAnimationFrame(renderer);
});
