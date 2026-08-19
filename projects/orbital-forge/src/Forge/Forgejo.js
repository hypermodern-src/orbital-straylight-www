export const encodeComponent = globalThis.encodeURIComponent;
export const decodeComponent = (value) => {
  try { return globalThis.decodeURIComponent(value); }
  catch (_) { return value; }
};

const configuredApiBase = document
  .querySelector('meta[name="orbital-forge-api"]')
  ?.getAttribute("content")
  ?.trim();

export const apiBase = globalThis.ORBITAL_FORGE_API_BASE
  || configuredApiBase
  || "/api/forge/v1";
