import { story } from "./mount";

export default {
  tags: ["autodocs"],
  title: "Themes/TextField",
  render: story("textfield"),
  argTypes: {"placeholder": {"control": "text"}, "size": {"control": "inline-radio", "options": ["1", "2", "3"]}},
  args: {"placeholder": "Search the docs\u2026", "size": "2"},
};

export const Default = {};
export const Large = { args: {"size": "3", "placeholder": "Larger field"} };
