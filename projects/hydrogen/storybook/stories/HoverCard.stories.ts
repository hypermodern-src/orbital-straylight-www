import { story } from "./mount";

export default {
  tags: ["autodocs"],
  title: "Radix/HoverCard",
  render: story("hovercard"),
};

// A live Hydrogen.Radix.HoverCard primitive — hover the trigger; after the open delay
// (200ms) the card reveals (native floating-ui positioning, openDelay/closeDelay timers).
export const Overview = {};
