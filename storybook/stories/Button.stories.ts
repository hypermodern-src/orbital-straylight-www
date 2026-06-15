import { story } from "./mount";

export default {
  title: "Themes/Button",
  render: story("button"),
  argTypes: {
    variant: { control: "select", options: ["solid", "soft", "outline", "surface", "ghost"] },
    size: { control: "inline-radio", options: ["1", "2", "3"] },
    color: { control: "select", options: ["", "indigo", "red", "green", "gray", "crimson"] },
    label: { control: "text" },
  },
  args: { variant: "solid", size: "2", color: "", label: "Button" },
};

export const Solid = { args: { variant: "solid" } };
export const Soft = { args: { variant: "soft" } };
export const Outline = { args: { variant: "outline" } };
export const Surface = { args: { variant: "surface" } };
export const Ghost = { args: { variant: "ghost" } };
