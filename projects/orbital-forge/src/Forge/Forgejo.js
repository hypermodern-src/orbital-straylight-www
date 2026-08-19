export const encodeComponent = globalThis.encodeURIComponent;
export const decodeComponent = (value) => {
  try { return globalThis.decodeURIComponent(value); }
  catch (_) { return value; }
};
