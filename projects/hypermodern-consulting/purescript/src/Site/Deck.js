/* FFI for Site.Deck — the scroll-linked painting from orbital-site.js,
   ported function-for-function. Halogen owns state; these own the DOM
   effects that follow scroll position and page transitions. */

const q = (sel) => document.querySelector(sel);
const qa = (sel) => [...document.querySelectorAll(sel)];
const activePanel = () => q(".pn.active");

/* ---------- deterministic reveal-on-scroll ---------- */
function reveal(p) {
  const h = p.clientHeight;
  p.querySelectorAll(".sr:not(.visible)").forEach((el) => {
    if (el.offsetTop - p.scrollTop < h * 0.92) {
      el.classList.add("visible");
      safetyTimer(el);
    }
  });
}
function resetReveal(p) {
  p.querySelectorAll(".sr").forEach((el) => el.classList.remove("visible"));
}
/* Safety net: if the entrance animation never paints, force visible. */
function safetyTimer(el) {
  setTimeout(() => {
    if (getComputedStyle(el).opacity === "0") {
      el.style.animation = "none";
      el.style.opacity = "1";
      el.style.transform = "none";
    }
  }, 1000);
}
function forceVisible(p) {
  p.querySelectorAll(".pc, .sc, .sr.visible, .re-stat.counted").forEach((el) => {
    if (getComputedStyle(el).opacity === "0") {
      el.style.animation = "none";
      el.style.opacity = "1";
      el.style.transform = "none";
    }
  });
}

/* ---------- vertical scroll rail + cue ---------- */
function updateVrail() {
  const p = activePanel();
  const vrail = q("#vrail");
  const vthumb = q("#vthumb");
  const shint = q("#shint");
  if (!p || !vrail) return;
  const over = p.scrollHeight - p.clientHeight;
  if (over > 8) {
    vrail.classList.add("show");
    const trackH = vrail.clientHeight;
    const th = Math.max(24, trackH * (p.clientHeight / p.scrollHeight));
    const top = (p.scrollTop / over) * (trackH - th);
    vthumb.style.height = th + "px";
    vthumb.style.transform = `translateY(${top}px)`;
    shint.classList.toggle("show", p.scrollTop < 40);
  } else {
    vrail.classList.remove("show");
    shint.classList.remove("show");
  }
}

/* ---------- count-up stats ---------- */
function countUp(p) {
  p.querySelectorAll(".re-stat").forEach((el, i) => {
    setTimeout(
      () => {
        el.classList.add("counted");
        if (el.dataset.static) {
          el.textContent = el.dataset.static;
          return;
        }
        const t = Number.parseInt(el.dataset.target),
          pre = el.dataset.prefix || "",
          suf = el.dataset.suffix || "";
        if (!t) {
          el.textContent = pre + "0" + suf;
          return;
        }
        const steps = 24;
        let s = 0;
        const timer = setInterval(() => {
          s++;
          const e = 1 - Math.pow(1 - s / steps, 3);
          el.textContent = pre + Math.round(t * e).toLocaleString() + suf;
          if (s >= steps) clearInterval(timer);
        }, 900 / steps);
      },
      180 + i * 70,
    );
  });
}

/* ============================================================
   exports
   ============================================================ */

export const initEffectsImpl = () => {
  qa(".pn").forEach((p) => {
    p.addEventListener(
      "scroll",
      () => {
        if (p === activePanel()) {
          updateVrail();
          reveal(p);
        }
      },
      { passive: true },
    );
  });
  window.addEventListener("resize", updateVrail);
  window.addEventListener("load", () => {
    updateVrail();
    const p = activePanel();
    if (p) reveal(p);
  });
  requestAnimationFrame(() => {
    const p = activePanel();
    if (p) reveal(p);
    updateVrail();
  });
  setTimeout(() => {
    const p = activePanel();
    if (p) forceVisible(p);
  }, 1400);
};

export const pageEffectsImpl = (i) => () => {
  /* after Halogen paints the new active panel */
  requestAnimationFrame(() =>
    requestAnimationFrame(() => {
      const p = q(`.pn[data-i="${i}"]`);
      if (!p) return;
      p.scrollTop = 0;
      resetReveal(p);
      reveal(p);
      countUp(p);
      updateVrail();
      setTimeout(() => {
        reveal(p);
        updateVrail();
      }, 900);
      setTimeout(() => forceVisible(p), 1300);
    }),
  );
};

export const setBodyDarkImpl = (dk) => () => {
  document.body.classList.toggle("dk", dk);
};

export const scrubIndexImpl = (me) => (total) => () => {
  const ind = q("#ind");
  const r = ind.getBoundingClientRect();
  const pct = (me.clientX - r.left) / r.width;
  return Math.max(0, Math.min(total - 1, Math.round(pct * (total - 1))));
};

export const scrollActiveImpl = (mode) => () => {
  const p = activePanel();
  if (!p) return;
  switch (mode) {
    case "down":
      p.scrollBy({ top: p.clientHeight * 0.18, behavior: "smooth" });
      break;
    case "up":
      p.scrollBy({ top: -p.clientHeight * 0.18, behavior: "smooth" });
      break;
    case "pgdn":
      p.scrollBy({ top: p.clientHeight * 0.85, behavior: "smooth" });
      break;
    case "pgup":
      p.scrollBy({ top: -p.clientHeight * 0.85, behavior: "smooth" });
      break;
    case "top":
      p.scrollTo({ top: 0, behavior: "smooth" });
      break;
    case "end":
      p.scrollTo({ top: p.scrollHeight, behavior: "smooth" });
      break;
  }
};

/* horizontal-dominant wheel gesture pages sections */
export const onHorizontalPageImpl = (cb) => () => {
  qa(".pn").forEach((p) => {
    let ha = 0,
      ht;
    p.addEventListener(
      "wheel",
      (e) => {
        const ax = Math.abs(e.deltaX),
          ay = Math.abs(e.deltaY);
        if (ax > ay * 1.8 && ax > 10) {
          e.preventDefault();
          ha += e.deltaX;
          clearTimeout(ht);
          ht = setTimeout(() => {
            ha = 0;
          }, 250);
          if (Math.abs(ha) > 60) {
            cb(ha > 0 ? 1 : -1)();
            ha = 0;
          }
        }
      },
      { passive: false },
    );
  });
};

/* touch: horizontal swipe = sections, vertical = native scroll */
export const onSwipeImpl = (cb) => () => {
  let tx = 0,
    ty = 0;
  window.addEventListener(
    "touchstart",
    (e) => {
      tx = e.touches[0].clientX;
      ty = e.touches[0].clientY;
    },
    { passive: true },
  );
  window.addEventListener(
    "touchend",
    (e) => {
      const dx = e.changedTouches[0].clientX - tx,
        dy = e.changedTouches[0].clientY - ty;
      if (Math.abs(dx) > 70 && Math.abs(dx) > Math.abs(dy) * 1.6) {
        cb(dx < 0 ? 1 : -1)();
      }
    },
    { passive: true },
  );
};

/* theme (orbital-theme.js): data-theme="onosendai" + localStorage */
export const applyThemeImpl = (dark) => () => {
  const root = document.documentElement;
  if (dark) {
    root.setAttribute("data-theme", "onosendai");
    try {
      localStorage.setItem("orbital-theme", "onosendai");
    } catch (e) {}
  } else {
    root.removeAttribute("data-theme");
    try {
      localStorage.removeItem("orbital-theme");
    } catch (e) {}
  }
};

export const storedDarkImpl = () => {
  try {
    return localStorage.getItem("orbital-theme") === "onosendai";
  } catch (e) {
    return false;
  }
};
