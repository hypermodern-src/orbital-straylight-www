/* PONCE International Speedway — page motion.
 * Scroll reveals, count-up stats, and the self-drawing track map with a
 * light pulse lapping the circuit. No dependencies; everything is gated
 * on prefers-reduced-motion and degrades to static content without JS. */

(function () {
  'use strict';

  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;

  document.documentElement.classList.add('motion');

  // ------------------------------------------------- hero converging slide
  // The bg image and the copy drift toward each other on opposite tracks.
  // Clicking the hero injects a speed burst that decays back to idle —
  // window.heroBoost is shared with the WebGL scene on the home page.
  var boost = { v: 1 };
  window.heroBoost = boost;

  var heroEl = document.querySelector('.hero');
  if (heroEl) {
    var bg = heroEl.querySelector('.hero-bg');
    var inner = heroEl.querySelector('.hero-inner');
    heroEl.addEventListener('click', function (ev) {
      boost.v = Math.min(boost.v + 2.5, 7);
      var rect = heroEl.getBoundingClientRect();
      var ripple = document.createElement('span');
      ripple.className = 'hero-ripple';
      ripple.style.left = (ev.clientX - rect.left) + 'px';
      ripple.style.top = (ev.clientY - rect.top) + 'px';
      heroEl.appendChild(ripple);
      ripple.addEventListener('animationend', function () { ripple.remove(); });
    });
    var phase = 0;
    var last = null;
    var slide = function (now) {
      if (last === null) last = now;
      var dt = Math.min((now - last) / 1000, 0.1);
      last = now;
      boost.v = 1 + (boost.v - 1) * Math.exp(-dt * 0.9);
      phase += dt * 0.32 * boost.v;
      var s = Math.sin(phase);
      var lean = boost.v - 1; // 0 at idle, up to 6 fully revved
      if (bg)
        bg.style.transform =
          'scale(' + (1.09 + lean * 0.012).toFixed(4) + ') translateX(' + (s * 2.2).toFixed(3) + '%)';
      if (inner)
        inner.style.transform =
          'translateX(' + (-s * 1.6).toFixed(3) + '%) skewX(' + (-lean * 0.55).toFixed(3) + 'deg)';
      requestAnimationFrame(slide);
    };
    requestAnimationFrame(slide);
  }

  // ------------------------------------------------------------- reveals
  var targets = document.querySelectorAll(
    'main section h2, main section p, main section ul, .card, .turns li, ' +
    '.timeline li, .faq, .specs > div, .quoteband blockquote, .trackmap, .signup'
  );
  var staggerIndex = new Map();
  targets.forEach(function (el) {
    el.classList.add('reveal');
    var parent = el.parentElement;
    var i = (staggerIndex.get(parent) || 0);
    staggerIndex.set(parent, i + 1);
    el.style.transitionDelay = Math.min(i * 70, 420) + 'ms';
  });

  var revealObserver = new IntersectionObserver(function (entries) {
    entries.forEach(function (e) {
      if (e.isIntersecting) {
        e.target.classList.add('in');
        revealObserver.unobserve(e.target);
      }
    });
  }, { rootMargin: '0px 0px -8% 0px', threshold: 0.05 });
  targets.forEach(function (el) { revealObserver.observe(el); });

  // ------------------------------------------------------ count-up stats
  function countUp(el) {
    var m = el.textContent.match(/^([\d.,]+)(.*)$/);
    if (!m) return;
    var target = parseFloat(m[1].replace(/,/g, ''));
    var suffix = m[2];
    var decimals = (m[1].split('.')[1] || '').length;
    var t0 = null;
    var DUR = 1300;
    function tick(now) {
      if (t0 === null) t0 = now;
      var p = Math.min((now - t0) / DUR, 1);
      var eased = 1 - Math.pow(1 - p, 3);
      el.textContent = (target * eased).toFixed(decimals) + suffix;
      if (p < 1) requestAnimationFrame(tick);
    }
    requestAnimationFrame(tick);
  }

  var statObserver = new IntersectionObserver(function (entries) {
    entries.forEach(function (e) {
      if (e.isIntersecting) {
        countUp(e.target);
        statObserver.unobserve(e.target);
      }
    });
  }, { threshold: 0.4 });
  document.querySelectorAll('.stat .value').forEach(function (el) { statObserver.observe(el); });

  // ------------------------------------- track map: draw-in + lap pulse
  document.querySelectorAll('.trackmap svg').forEach(function (svg) {
    var line = svg.querySelector('.track-line');
    if (!line || typeof line.getTotalLength !== 'function') return;
    var len = line.getTotalLength();
    line.style.strokeDasharray = len + ' ' + len;
    line.style.strokeDashoffset = len;

    var mapObserver = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (!e.isIntersecting) return;
        mapObserver.unobserve(svg);

        line.style.transition = 'stroke-dashoffset 2.4s cubic-bezier(0.4, 0, 0.2, 1)';
        requestAnimationFrame(function () { line.style.strokeDashoffset = '0'; });

        // after the draw-in, a light pulse laps the circuit forever
        setTimeout(function () {
          var pulse = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
          pulse.setAttribute('r', '6');
          pulse.setAttribute('class', 'lap-pulse');
          svg.appendChild(pulse);
          var start = null;
          var LAP_MS = 9000;
          function lap(now) {
            if (start === null) start = now;
            var t = (((now - start) / LAP_MS) % 1 + 1) % 1;
            var pt = line.getPointAtLength(t * len);
            pulse.setAttribute('cx', pt.x);
            pulse.setAttribute('cy', pt.y);
            requestAnimationFrame(lap);
          }
          requestAnimationFrame(lap);
        }, 2400);
      });
    }, { threshold: 0.35 });
    mapObserver.observe(svg);
  });
})();
