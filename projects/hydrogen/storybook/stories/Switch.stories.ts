import { story } from "./mount";

export default {
  tags: ["autodocs"],
  title: "Themes/Switch",
  render: story("switch"),
  argTypes: {"checked": {"control": "boolean"}, "disabled": {"control": "boolean"}},
  args: {"checked": true, "disabled": false},
};

export const Checked = { args: {"checked": true} };
export const Unchecked = { args: {"checked": false} };
export const Disabled = { args: {"checked": true, "disabled": true} };
