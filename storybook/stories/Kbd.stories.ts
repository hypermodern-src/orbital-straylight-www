import { story } from "./mount";

export default {
  tags: ["autodocs"],
  title: "Themes/Kbd",
  render: story("kbd"),
  argTypes: {"size": {"control": "inline-radio", "options": ["1", "2", "3"]}, "label": {"control": "text"}},
  args: {"size": "2", "label": "Shift + Tab"},
};

export const Default = {};
