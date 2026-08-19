export const currentHash = () => window.location.hash || "#/";

export const setHash = (hash) => () => {
  if (window.location.hash !== hash) window.location.hash = hash;
};

export const currentTheme = () => document.documentElement.dataset.theme === "onosendai";

export const applyTheme = (dark) => () => {
  if (dark) document.documentElement.dataset.theme = "onosendai";
  else delete document.documentElement.dataset.theme;
  try {
    localStorage.setItem("orbital-theme", dark ? "onosendai" : "light");
  } catch (_) {}
};

export const copyText = (value) => () => {
  if (navigator.clipboard?.writeText) {
    navigator.clipboard.writeText(value).catch(() => {});
    return;
  }
  const node = document.createElement("textarea");
  node.value = value;
  node.setAttribute("readonly", "");
  node.style.position = "fixed";
  node.style.opacity = "0";
  document.body.appendChild(node);
  node.select();
  try { document.execCommand("copy"); } catch (_) {}
  node.remove();
};
