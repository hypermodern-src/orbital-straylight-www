"use strict";

// A body-level `.radix-themes` container is where overlay layers (Dialog,
// Popover, Tooltip, …) mount, so their fixed/absolute positioning escapes any
// ancestor stacking/overflow/transform context. One shared container per id,
// created lazily and reused.
export const _ensureContainer = function (id) {
  return function () {
    var el = document.getElementById(id);
    if (!el) {
      el = document.createElement("div");
      el.id = id;
      // carry the theme tokens so portaled content is themed like the app root.
      el.className = "radix-themes";
      document.body.appendChild(el);
    }
    return el;
  };
};

// Move a node into the container (portal in). Idempotent.
export const _adopt = function (container) {
  return function (node) {
    return function () {
      if (node.parentNode !== container) container.appendChild(node);
    };
  };
};

// Set document.body's overflow (scroll-lock while a modal is open). Returns the
// previous value so the caller can restore it on close.
export const _setBodyOverflow = function (value) {
  return function () {
    var prev = document.body.style.overflow;
    document.body.style.overflow = value;
    return prev;
  };
};

// Focus an element (the dialog content takes focus on open for a11y + Escape).
export const _focus = function (node) {
  return function () {
    if (node && typeof node.focus === "function") node.focus();
  };
};

// True when the click landed on the element itself, not a descendant — the
// pointer-down-outside test that closes a modal when its backdrop is clicked.
export const _isSelfTarget = function (event) {
  return function () {
    return event.target === event.currentTarget;
  };
};

// Run an effect after the next frame paints — a stable "Halogen has finished
// patching the DOM" hook. Halogen re-parents matched children into the component
// root on patch, so the body-mount is re-asserted here, after the render.
export const _afterFrame = function (eff) {
  return function () {
    requestAnimationFrame(function () {
      eff();
    });
  };
};
