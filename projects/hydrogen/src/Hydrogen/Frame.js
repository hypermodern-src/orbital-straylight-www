// FFI for Hydrogen.Frame — read a key from the host-provided runtime config
// global (window.__straylight__), used by the RouterContext FrameworkContext
// instance. Returns `just value` when present, else `nothing`.
export const readConfig = (key) => (just) => (nothing) => () => {
  const cfg = (typeof window !== "undefined" && window.__straylight__) || {};
  const v = cfg[key];
  return v == null ? nothing : just(String(v));
};
