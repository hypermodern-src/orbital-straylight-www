// Bridge each story to the Halogen bundle: render component `id` with the live
// control `args` into a fresh canvas element.
declare global {
  interface Window {
    hydrogenStorybook: { mount: (id: string, args: unknown, el: HTMLElement) => void };
  }
}
export const story = (id: string) => (args: unknown) => {
  const el = document.createElement("div");
  window.hydrogenStorybook.mount(id, args, el);
  return el;
};
