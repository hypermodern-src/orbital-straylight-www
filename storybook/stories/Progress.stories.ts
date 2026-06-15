import { story } from "./mount";

export default {
  title: "Themes/Progress",
  render: story("progress"),
  argTypes: {"value": {"control": {"type": "range", "min": 0, "max": 100, "step": 1}}, "variant": {"control": "select", "options": ["", "surface", "soft"]}, "color": {"control": "select", "options": ["", "indigo", "cyan", "green"]}},
  args: {"value": 60, "variant": "", "color": ""},
};

export const Default = {};
