import type { StorybookConfig } from "@storybook/html-vite";

const config: StorybookConfig = {
  stories: ["../stories/**/*.stories.ts"],
  addons: ["@storybook/addon-essentials"],
  framework: { name: "@storybook/html-vite", options: {} },
  // dist/ holds the Spago-built Halogen bundle + the Radix stylesheet, served at /.
  staticDirs: ["../dist"],
};
export default config;
