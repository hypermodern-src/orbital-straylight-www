// FFI for Reinit.Statsig

export const getHeroVariant = () => {
  if (typeof window !== "undefined" && window.statsig) {
    return window.statsig.getHeroVariant();
  }
  // Fallback for SSR/SSG or before Statsig loads
  return {
    variant: "control",
    headline: "Your AI broke it.",
    subhead: "We fix it.",
    tagline:
      "Vibe-coded apps cleaned up by engineers who understand what the AI was trying to do.",
    cta: "GET QUOTE",
  };
};

export const logCtaClick = (location) => () => {
  if (typeof window !== "undefined" && window.statsig) {
    window.statsig.logCtaClick(location);
  }
};

export const logSubmit = (type) => () => {
  if (typeof window !== "undefined" && window.statsig) {
    window.statsig.logSubmit(type);
  }
};
