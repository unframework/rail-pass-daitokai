var requestAnimationFrame = require('raf');
var vec3 = require('gl-matrix').vec3;
var mat4 = require('gl-matrix').mat4;

var PhysicsWorld = require('./src/PhysicsWorld.coffee');

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
gl.shaderSource(vertexShader, 'uniform mat4 camera; uniform mat4 model; attribute vec4 position; void main() { gl_Position = camera * model * position; }');
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
var cameraLocation = gl.getUniformLocation(program, "camera");
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

var camera = mat4.create();
var cameraPosition = vec3.create();
vec3.set(cameraPosition, 0, 0, -8);
mat4.perspective(camera, 45, window.innerWidth / window.innerHeight, 1, 10);
mat4.translate(camera, camera, cameraPosition);
gl.uniformMatrix4fv(cameraLocation, false, camera);

var modelPosition = vec3.create();
var model = mat4.create();

var world = new PhysicsWorld();

requestAnimationFrame(function (time) {
    var renderer = arguments.callee;
    var lastTime = renderer.lastTime || time;

    var elapsedSeconds = Math.min(100, time - lastTime) / 1000; // limit to 100ms jitter

    renderer.lastTime = time;

    world.update(elapsedSeconds);

    world._movables.forEach(function (m) {
        vec3.set(modelPosition, m.position[0], m.position[1], 0);

        mat4.identity(model);
        mat4.translate(model, model, modelPosition);

        gl.uniformMatrix4fv(modelLocation, false, model);
        gl.drawArrays(gl.TRIANGLES, 0, 6);
    });

    requestAnimationFrame(renderer);
});
