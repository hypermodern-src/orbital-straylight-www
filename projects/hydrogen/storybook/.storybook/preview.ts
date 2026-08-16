import type { Preview } from "@storybook/html";

// Toolbar globals: preview every component under any appearance / accent — the
// Radix stylesheet drives `.radix-themes.{light,dark}` + `[data-accent-color]`.
export const globalTypes = {
  appearance: {
    description: "Theme appearance",
    defaultValue: "light",
    toolbar: {
      title: "Appearance",
      icon: "mirror",
      items: [
        { value: "light", title: "Light" },
        { value: "dark", title: "Dark" },
      ],
      dynamicTitle: true,
    },
  },
  accent: {
    description: "Accent color",
    defaultValue: "indigo",
    toolbar: {
      title: "Accent",
      icon: "paintbrush",
      items: ["indigo", "blue", "cyan", "green", "orange", "red", "crimson", "gray"].map((c) => ({ value: c, title: c })),
      dynamicTitle: true,
    },
  },
};

const BASE_THEME: Record<string, string> = {
  "data-is-root-theme": "true",
  "data-gray-color": "slate",
  "data-has-background": "true",
  "data-panel-background": "translucent",
  "data-radius": "medium",
  "data-scaling": "100%",
};

const preview: Preview = {
  parameters: { layout: "centered", controls: { expanded: true } },
  decorators: [
    (story, context) => {
      const { appearance = "light", accent = "indigo" } = context.globals;
      const wrap = document.createElement("div");
      // .radix-themes.{light,dark} + data-has-background gives the wrapper the
      // theme's own background, so dark mode reads correctly behind the story.
      wrap.className = `radix-themes ${appearance}`;
      Object.entries(BASE_THEME).forEach(([k, v]) => wrap.setAttribute(k, v));
      wrap.setAttribute("data-accent-color", String(accent));
      wrap.style.setProperty("--default-font-family", "'Inter Variable', sans-serif");
      wrap.style.padding = "2rem";
      const node = story();
      wrap.appendChild(node instanceof Node ? node : Object.assign(document.createElement("div"), { innerHTML: String(node) }));
      return wrap;
    },
  ],
};
export default preview;
