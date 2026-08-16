import { story } from "./mount";

export default {
  tags: ["autodocs"],
  title: "Themes/Spinner",
  render: story("spinner"),
  argTypes: {"size": {"control": "inline-radio", "options": ["1", "2", "3"]}},
  args: {"size": "2"},
};

export const Default = {};
