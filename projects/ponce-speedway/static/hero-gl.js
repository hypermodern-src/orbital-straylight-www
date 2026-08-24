/* PONCE International Speedway — WebGL hero.
 * Perspective flyover of a stylized 12-turn seaside circuit at dusk:
 * glowing track ribbon, car light-pulses lapping it, sun on the horizon.
 * Raw WebGL1, zero dependencies. Falls back to the CSS hero image. */

(function () {
  'use strict';

  var hero = document.querySelector('.hero');
  if (!hero) return;

  var reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  var canvas = document.createElement('canvas');
  canvas.id = 'hero-gl';
  canvas.setAttribute('aria-hidden', 'true');
  // above the .hero-bg image layer, below the copy and the gradient overlay
  hero.insertBefore(canvas, hero.querySelector('.hero-inner'));

  var gl = canvas.getContext('webgl', { antialias: true, alpha: false });
  if (!gl) { canvas.remove(); return; }
  hero.classList.add('gl-on');

  // ---------------------------------------------------------------- track
  // Control polygon for a closed 12-turn circuit (plane coordinates), then
  // Catmull-Rom resampled to N points baked into a shader uniform array.
  var N = 96;
  // Centerline waypoints digitized from the official circuit map (1939x1080 px,
  // clockwise from start/finish). Shared verbatim with build.js.
  var RAW = [
    [1030, 905], [1300, 905], [1560, 905], [1820, 900], [1885, 893],
    [1908, 860], [1885, 828], [1820, 822], [1500, 800], [1150, 763],
    [1010, 690], [962, 580], [985, 480], [940, 465], [885, 430],
    [830, 485], [760, 565], [700, 650], [672, 700], [618, 745],
    [645, 668], [720, 530], [800, 380], [848, 285], [845, 225],
    [700, 190], [450, 132], [270, 90], [235, 130], [235, 320],
    [222, 520], [200, 700], [150, 880], [110, 955], [70, 995],
    [88, 1022], [160, 1010], [300, 970], [480, 938], [595, 930],
    [645, 952], [700, 985], [758, 933],
  ];
  var MAP_SCALE = 2.9 / 1939;
  var ctrl = RAW.map(function (p) {
    return [p[0] * MAP_SCALE - 1.45, p[1] * MAP_SCALE - (1080 * MAP_SCALE) / 2];
  });
  function catmull(p0, p1, p2, p3, t) {
    var t2 = t * t, t3 = t2 * t;
    return [
      0.5 * (2 * p1[0] + (p2[0] - p0[0]) * t + (2 * p0[0] - 5 * p1[0] + 4 * p2[0] - p3[0]) * t2 + (3 * p1[0] - p0[0] - 3 * p2[0] + p3[0]) * t3),
      0.5 * (2 * p1[1] + (p2[1] - p0[1]) * t + (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * t2 + (3 * p1[1] - p0[1] - 3 * p2[1] + p3[1]) * t3),
    ];
  }
  function samplePath(t) { // any t; wrapped onto the closed loop
    var n = ctrl.length;
    t = ((t % 1) + 1) % 1;
    var f = t * n;
    var i = Math.floor(f);
    var u = f - i;
    var p0 = ctrl[(i - 1 + n) % n], p1 = ctrl[i % n], p2 = ctrl[(i + 1) % n], p3 = ctrl[(i + 2) % n];
    return catmull(p0, p1, p2, p3, u);
  }
  var pts = new Float32Array(N * 2);
  for (var i = 0; i < N; i++) {
    var p = samplePath(i / N);
    pts[i * 2] = p[0];
    pts[i * 2 + 1] = p[1];
  }

  // --------------------------------------------------------------- shaders
  var vsrc = [
    'attribute vec2 a_pos;',
    'void main() { gl_Position = vec4(a_pos, 0.0, 1.0); }',
  ].join('\n');

  var CARS = 5;
  var fsrc = [
    'precision mediump float;',
    'uniform vec2 u_res;',
    'uniform float u_time;',
    'uniform float u_boost;', // 1 at idle, up to ~7 revved
    'uniform vec2 u_pts[' + N + '];',
    'uniform vec3 u_cars[' + CARS + '];', // xy = position, z = 0 white / 1 red
    '',
    'float segDist(vec2 p, vec2 a, vec2 b) {',
    '  vec2 pa = p - a, ba = b - a;',
    '  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);',
    '  return length(pa - ba * h);',
    '}',
    '',
    'void main() {',
    '  vec2 uv = (gl_FragCoord.xy * 2.0 - u_res) / u_res.y;',
    '',
    '  // rev shake: tiny high-frequency jitter, only when boosted',
    '  float rev = max(u_boost - 1.15, 0.0);',
    '  uv += vec2(sin(u_time * 47.0), cos(u_time * 39.0)) * 0.0016 * rev;',
    '',
    '  // slow orbital drift',
    '  float ang = u_time * 0.04;',
    '  float ca = cos(ang), sa = sin(ang);',
    '',
    '  // camera above the plane, pitched down at the horizon',
    '  vec3 ro = vec3(0.0, 0.85, -2.0);',
    '  vec3 rd = normalize(vec3(uv.x, uv.y - 0.35, 1.05));',
    '',
    '  // dusk sky',
    '  float horizon = smoothstep(0.45, -0.05, uv.y);',
    '  vec3 sky = mix(vec3(0.06, 0.06, 0.11), vec3(0.55, 0.20, 0.12), horizon);',
    '  float sun = exp(-9.0 * length(uv - vec2(0.55, 0.12)));',
    '  sky += vec3(1.0, 0.55, 0.25) * sun * (1.15 + 0.14 * rev);',
    '  sky += vec3(1.0, 0.35, 0.15) * exp(-4.0 * abs(uv.y - 0.06)) * 0.22;',
    '',
    '  vec3 col = sky;',
    '  if (rd.y < -0.015) {',
    '    float t = -ro.y / rd.y;',
    '    vec2 w = ro.xz + rd.xz * t;',
    '    // rotate world under the camera, then frame the circuit right of the copy',
    '    w = vec2(w.x * ca - w.y * sa, w.x * sa + w.y * ca);',
    '    w = w * 0.72 - vec2(0.42, -0.05);',
    '',
    '    // sea-dark ground with a faint sheen toward the sun',
    '    vec3 ground = vec3(0.035, 0.045, 0.06);',
    '    ground += vec3(0.10, 0.05, 0.03) * exp(-0.25 * t);',
    '',
    '    // distance to the circuit polyline',
    '    float d = 1e5;',
    '    float dCar = 1e5;',
    '    for (int i = 0; i < ' + N + '; i++) {',
    '      vec2 a = u_pts[i];',
    '      vec2 b = (i == ' + (N - 1) + ') ? u_pts[0] : u_pts[i + 1];',
    '      d = min(d, segDist(w, a, b));',
    '    }',
    '',
    '    // road body + edge glow',
    '    float road = 1.0 - smoothstep(0.030, 0.043, d);',
    '    float edge = smoothstep(0.043, 0.030, d) * smoothstep(0.018, 0.030, d);',
    '    float glow = exp(-d * 26.0);',
    '    ground = mix(ground, vec3(0.13, 0.13, 0.16), road);',
    '    ground += vec3(0.98, 0.26, 0.18) * edge * (1.35 + 0.18 * rev);',
    '    ground += vec3(0.85, 0.18, 0.12) * glow * 0.6;',
    '',
    '    // cars: moving light pulses with a soft bloom',
    '    for (int c = 0; c < ' + CARS + '; c++) {',
    '      vec3 car = u_cars[c];',
    '      float cd = length(w - car.xy);',
    '      vec3 tint = mix(vec3(1.0, 0.95, 0.85), vec3(1.0, 0.25, 0.15), car.z);',
    '      ground += tint * exp(-cd * 90.0) * (2.0 + 0.5 * rev);',
    '      ground += tint * exp(-cd * 16.0) * (0.16 + 0.05 * rev);',
    '    }',
    '',
    '    // distance fog into the horizon band',
    '    float fog = 1.0 - exp(-0.16 * t);',
    '    col = mix(ground, vec3(0.16, 0.07, 0.06), fog * fog);',
    '  }',
    '',
    '  // vignette',
    '  vec2 q = gl_FragCoord.xy / u_res;',
    '  col *= 0.55 + 0.45 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.35);',
    '',
    '  gl_FragColor = vec4(col, 1.0);',
    '}',
  ].join('\n');

  function compile(type, src) {
    var s = gl.createShader(type);
    gl.shaderSource(s, src);
    gl.compileShader(s);
    if (!gl.getShaderParameter(s, gl.COMPILE_STATUS)) {
      throw new Error(gl.getShaderInfoLog(s));
    }
    return s;
  }

  var prog;
  try {
    prog = gl.createProgram();
    gl.attachShader(prog, compile(gl.VERTEX_SHADER, vsrc));
    gl.attachShader(prog, compile(gl.FRAGMENT_SHADER, fsrc));
    gl.linkProgram(prog);
    if (!gl.getProgramParameter(prog, gl.LINK_STATUS)) throw new Error(gl.getProgramInfoLog(prog));
  } catch (e) {
    canvas.remove();
    return;
  }
  gl.useProgram(prog);

  var quad = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, quad);
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 3, -1, -1, 3]), gl.STATIC_DRAW);
  var aPos = gl.getAttribLocation(prog, 'a_pos');
  gl.enableVertexAttribArray(aPos);
  gl.vertexAttribPointer(aPos, 2, gl.FLOAT, false, 0, 0);

  gl.uniform2fv(gl.getUniformLocation(prog, 'u_pts'), pts);
  var uRes = gl.getUniformLocation(prog, 'u_res');
  var uTime = gl.getUniformLocation(prog, 'u_time');
  var uCars = gl.getUniformLocation(prog, 'u_cars');
  var uBoost = gl.getUniformLocation(prog, 'u_boost');

  function resize() {
    var dpr = Math.min(window.devicePixelRatio || 1, 2);
    var w = hero.clientWidth, h = hero.clientHeight;
    if (canvas.width !== w * dpr || canvas.height !== h * dpr) {
      canvas.width = w * dpr;
      canvas.height = h * dpr;
      gl.viewport(0, 0, canvas.width, canvas.height);
    }
  }

  var carState = [];
  for (var c = 0; c < CARS; c++) {
    carState.push({ t: c / CARS, speed: 0.028 + 0.008 * (c % 3), red: c % 2 });
  }
  var cars = new Float32Array(CARS * 3);

  // simulated clock: advances faster while window.heroBoost is revved
  var sim = 0;
  var lastNow = null;
  function frame(now) {
    if (lastNow === null) lastNow = now;
    var dt = Math.min((now - lastNow) / 1000, 0.1);
    lastNow = now;
    sim += dt * ((window.heroBoost && window.heroBoost.v) || 1);
    var t = sim;
    resize();
    for (var c = 0; c < CARS; c++) {
      var s = carState[c];
      var pos = samplePath((s.t + t * s.speed) % 1);
      cars[c * 3] = pos[0];
      cars[c * 3 + 1] = pos[1];
      cars[c * 3 + 2] = s.red;
    }
    gl.uniform2f(uRes, canvas.width, canvas.height);
    gl.uniform1f(uTime, reduced ? 0 : t);
    gl.uniform1f(uBoost, (window.heroBoost && window.heroBoost.v) || 1);
    gl.uniform3fv(uCars, cars);
    gl.drawArrays(gl.TRIANGLES, 0, 3);
    if (!reduced) requestAnimationFrame(frame);
  }
  requestAnimationFrame(frame);
})();
