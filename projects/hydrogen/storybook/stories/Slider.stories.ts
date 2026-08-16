import { story } from "./mount";

export default {
  tags: ["autodocs"],
  title: "Themes/Slider",
  render: story("slider"),
  argTypes: {"value": {"control": {"type": "range", "min": 0, "max": 100, "step": 1}}},
  args: {"value": 40},
};

export const Default = {};
