import { story } from "./mount";

export default {
  title: "Themes/Blockquote",
  render: story("blockquote"),
  argTypes: {"size": {"control": "inline-radio", "options": ["1", "2", "3", "4"]}, "text": {"control": "text"}},
  args: {"size": "3", "text": "Perfect is the enemy of good."},
};

export const Default = {};
