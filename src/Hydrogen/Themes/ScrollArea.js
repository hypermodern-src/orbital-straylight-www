"use strict";

// The viewport's scroll geometry — the input to the custom thumb's size/position.
// (ScrollArea is the one non-overlay stateful component: no portal, just a viewport
// whose scroll is mirrored onto a styled thumb.)
export const _metrics = function (el) {
  return function () {
    return {
      scrollTop: el.scrollTop,
      scrollHeight: el.scrollHeight,
      clientHeight: el.clientHeight,
    };
  };
};
