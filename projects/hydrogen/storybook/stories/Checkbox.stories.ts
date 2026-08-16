import { story } from "./mount";

export default {
  tags: ["autodocs"],
  title: "Themes/Checkbox",
  render: story("checkbox"),
  argTypes: {"checked": {"control": "boolean"}, "disabled": {"control": "boolean"}, "label": {"control": "text"}},
  args: {"checked": true, "disabled": false, "label": "Accept terms"},
};

export const Checked = { args: {"checked": true} };
export const Unchecked = { args: {"checked": false} };
export const Disabled = { args: {"checked": true, "disabled": true} };
