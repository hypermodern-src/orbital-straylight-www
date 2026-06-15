import type { Preview } from "@storybook/html";

// Every story renders inside the .radix-themes root (same config as the goldens),
// so a story is pixel-equivalent to upstream Radix Themes.
const THEME: Record<string, string> = {
  "data-is-root-theme": "true",
  "data-accent-color": "indigo",
  "data-gray-color": "slate",
  "data-has-background": "true",
  "data-panel-background": "translucent",
  "data-radius": "medium",
  "data-scaling": "100%",
};

const preview: Preview = {
  parameters: { layout: "centered", controls: { expanded: true } },
  decorators: [
    (story) => {
      const wrap = document.createElement("div");
      wrap.className = "radix-themes light";
      Object.entries(THEME).forEach(([k, v]) => wrap.setAttribute(k, v));
      wrap.style.setProperty("--default-font-family", "'Inter Variable', sans-serif");
      wrap.style.padding = "2rem";
      const node = story();
      wrap.appendChild(node instanceof Node ? node : Object.assign(document.createElement("div"), { innerHTML: String(node) }));
      return wrap;
    },
  ],
};
export default preview;
