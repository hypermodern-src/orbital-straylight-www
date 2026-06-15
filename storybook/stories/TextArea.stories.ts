import { story } from "./mount";

export default {
  title: "Themes/TextArea",
  render: story("textarea"),
  argTypes: {"placeholder": {"control": "text"}, "size": {"control": "inline-radio", "options": ["1", "2", "3"]}},
  args: {"placeholder": "Reply to comment\u2026", "size": "2"},
};

export const Default = {};
