// FFI for Hydrogen.Integration.Clerk — @clerk/clerk-js. The bare import pulls the
// whole nested closure (assembled by straylight-prelude's npm placement-tree
// renderer) into the bundle; peers (react etc.) are marked --external.
import { Clerk } from "@clerk/clerk-js";

export const loadImpl = (publishableKey) => (k) => () => {
  const clerk = new Clerk(publishableKey);
  clerk.load().then(() => k(clerk)());
};

export const isSignedIn = (clerk) => () => !!clerk.user;

export const openSignIn = (clerk) => () => {
  clerk.openSignIn();
};

export const clerkSignOut = (clerk) => () => {
  clerk.signOut();
};

export const addListenerImpl = (clerk) => (cb) => () => {
  const unsub = clerk.addListener((resources) => {
    cb(!!resources.user)();
  });
  return () => {
    unsub();
  };
};
