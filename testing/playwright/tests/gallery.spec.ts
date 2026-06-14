import { test, expect } from "@playwright/test";

// Generic, fixed harness. It does NOT enumerate stories — it reads the manifest
// the gallery (PureScript) renders on its index, then diffs each `?story=<id>`
// page against golden/<id>.png. Adding a story is pure PureScript (append to
// `stories` in Gallery.Main); this file never changes. That is what makes
// Playwright an implementation detail.

test("radix gallery — every story is pixel-identical to its golden", async ({
  page,
}) => {
  await page.goto("/");
  const ids = await page
    .locator("#gallery-manifest li[data-story]")
    .evaluateAll((els) => els.map((el) => el.getAttribute("data-story")!));
  expect(ids.length).toBeGreaterThan(0);

  for (const id of ids) {
    await page.goto(`/?story=${encodeURIComponent(id)}`, { waitUntil: "load" });
    await page.waitForTimeout(300); // let Halogen mount + the vdom settle
    await expect(page).toHaveScreenshot(`${id}.png`, { fullPage: true });
  }
});
