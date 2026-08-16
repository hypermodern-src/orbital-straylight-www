import { story } from "./mount";

export default {
  tags: ["autodocs"],
  title: "Themes/Avatar",
  render: story("avatar"),
  argTypes: {"variant": {"control": "select", "options": ["soft", "solid"]}, "color": {"control": "select", "options": ["", "indigo", "red", "green", "gray"]}, "size": {"control": "inline-radio", "options": ["1", "2", "3", "4", "5", "6"]}, "fallback": {"control": "text"}},
  args: {"variant": "soft", "color": "indigo", "size": "3", "fallback": "RT"},
};

export const Soft = { args: {"variant": "soft"} };
export const Solid = { args: {"variant": "solid"} };
