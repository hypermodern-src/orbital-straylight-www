import { story } from "./mount";

export default {
  title: "Themes/Quote",
  render: story("quote"),
  argTypes: {"text": {"control": "text"}},
  args: {"text": "Design is not just what it looks like."},
};

export const Default = {};
