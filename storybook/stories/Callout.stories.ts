import { story } from "./mount";

export default {
  title: "Themes/Callout",
  render: story("callout"),
  argTypes: {"color": {"control": "select", "options": ["", "indigo", "red", "green", "gray"]}, "text": {"control": "text"}},
  args: {"color": "", "text": "You will need admin privileges to install this app."},
};

export const Default = {};
