import { story } from "./mount";

export default {
  title: "Themes/Badge",
  render: story("badge"),
  argTypes: {
    variant: { control: "select", options: ["solid", "soft", "surface", "outline"] },
    color: { control: "select", options: ["", "indigo", "red", "green", "orange", "gray"] },
    label: { control: "text" },
  },
  args: { variant: "soft", color: "green", label: "Complete" },
};

export const Soft = { args: { variant: "soft", color: "green", label: "Complete" } };
export const Solid = { args: { variant: "solid", color: "indigo", label: "New" } };
export const Surface = { args: { variant: "surface", color: "orange", label: "In progress" } };
export const Outline = { args: { variant: "outline", color: "red", label: "Failed" } };
