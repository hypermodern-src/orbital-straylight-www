import { story } from "./mount";

export default {
  tags: ["autodocs"],
  title: "Themes/Link",
  render: story("link"),
  argTypes: {"size": {"control": "inline-radio", "options": ["1", "2", "3"]}, "label": {"control": "text"}},
  args: {"size": "3", "label": "documentation"},
};

export const Default = {};
