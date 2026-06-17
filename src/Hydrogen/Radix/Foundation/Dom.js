// Hydrogen.Radix.Dom — the ONLY foreign code in the radix port.
//
// A handful of primitives, kept here because purescript-web-* exposes no binding
// for them (see Dom.purs for the why of each). DOM-only: standard browser APIs, no
// external dependency, no module state. Before adding another, check it almost
// certainly already exists in Web.DOM.* / Web.HTML.* — use that instead.

// getComputedStyle(el).getPropertyValue(prop): the engine's resolved value (the
// only source of truth for visibility and running-animation queries).
export const computedStyle = el => prop => () =>
  window.getComputedStyle(el).getPropertyValue(prop);

// el.style.getPropertyValue(prop): the inline value, "" if unset — read back a
// property before overwriting it so it can be restored exactly.
export const inlineStyle = el => prop => () =>
  el.style.getPropertyValue(prop);

// el.style.setProperty(prop, value): the port's single style mutation. "" clears.
export const setInlineStyle = el => prop => value => () => {
  el.style.setProperty(prop, value);
};

// queueMicrotask(eff): run eff after the current task + synchronous render flush but BEFORE
// the next macrotask (a fired event). No web-* binding exposes it; used to move focus into a
// just-opened menu before a driver/user keypress lands (a requestAnimationFrame is too late).
export const queueMicrotask_ = eff => () => {
  queueMicrotask(eff);
};

// { width: el.offsetWidth, height: el.offsetHeight, left: el.offsetLeft, top: el.offsetTop }:
// the element's layout-box geometry (integral, transform-independent). NavigationMenu measures
// these (NOT getBoundingClientRect) to size its viewport (active content) and place its
// indicator (active trigger), so the port must read the same to match upstream.
export const offsetMetrics = el => () => ({
  width: el.offsetWidth,
  height: el.offsetHeight,
  left: el.offsetLeft,
  top: el.offsetTop,
});
