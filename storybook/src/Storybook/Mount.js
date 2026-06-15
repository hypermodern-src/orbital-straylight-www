// FFI for Storybook.Mount — read control values + publish the mount API.

export const argStr = (key) => (def) => (args) =>
  args != null && args[key] != null && args[key] !== "" ? String(args[key]) : def;

export const argBool = (key) => (def) => (args) =>
  args != null && args[key] != null ? Boolean(args[key]) : def;

// `fn` is a PureScript Fn3 (String, Args, Element) -> Effect Unit. Wrap it so a
// story can call `window.hydrogenStorybook.mount(id, args, el)` directly.
export const attach = (fn) => () => {
  const g = typeof window !== "undefined" ? window : globalThis;
  g.hydrogenStorybook = { mount: (id, args, el) => fn(id, args, el)() };
};
