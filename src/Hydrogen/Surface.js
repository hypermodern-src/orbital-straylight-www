// FFI for Hydrogen.Surface — read the host viewport + capabilities, and observe
// changes. SSR-safe: when there's no window (prerender), report a Roomy default.

const safeMatch = (q) =>
  typeof window !== "undefined" && window.matchMedia
    ? window.matchMedia(q).matches
    : false;

export const readMetrics = () => {
  if (typeof window === "undefined") {
    return { width: 1280, height: 800, touch: false, standalone: false };
  }
  return {
    width: window.innerWidth,
    height: window.innerHeight,
    touch: safeMatch("(pointer: coarse)"),
    standalone: safeMatch("(display-mode: standalone)"),
  };
};

export const onResize = (cb) => () => {
  if (typeof window === "undefined") return () => {};
  const handler = () => cb();
  window.addEventListener("resize", handler);
  window.addEventListener("orientationchange", handler);
  return () => {
    window.removeEventListener("resize", handler);
    window.removeEventListener("orientationchange", handler);
  };
};
