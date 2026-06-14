// Hydrogen.Radix.Dom — the ONLY foreign code in the radix port.
//
// Three primitives, kept here because purescript-web-* exposes no binding for
// them (see Dom.purs for the why of each). DOM-only: standard browser APIs, no
// external dependency, no module state. If you reach for a fourth, it almost
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
