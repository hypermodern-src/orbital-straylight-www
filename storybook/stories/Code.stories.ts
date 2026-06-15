import { story } from "./mount";

export default {
  tags: ["autodocs"],
  title: "Themes/Code",
  render: story("code"),
  argTypes: {"variant": {"control": "select", "options": ["soft", "solid", "outline", "ghost"]}, "size": {"control": "inline-radio", "options": ["1", "2", "3"]}, "label": {"control": "text"}},
  args: {"variant": "soft", "size": "2", "label": "npm install"},
};

export const Soft = { args: {"variant": "soft"} };
export const Solid = { args: {"variant": "solid"} };
