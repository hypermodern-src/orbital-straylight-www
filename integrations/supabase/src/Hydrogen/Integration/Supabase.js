// FFI for Hydrogen.Integration.Supabase — @supabase/supabase-js. The bare import
// is resolved + bundled by esbuild against NODE_PATH, onto which the
// purescript_library's npm closure (PursLibInfo) places the SDK's node_modules.
import { createClient as _createClient } from "@supabase/supabase-js";

export const createClient = (url) => (anonKey) => () =>
  _createClient(url, anonKey);

export const signInWithPasswordImpl =
  (client) => (creds) => (onError) => (onSuccess) => () => {
    client.auth
      .signInWithPassword({ email: creds.email, password: creds.password })
      .then(({ data, error }) => {
        if (error) onError(error.message)();
        else onSuccess(data.session)();
      })
      .catch((e) => onError(String(e && e.message ? e.message : e))());
  };

export const signOut = (client) => (onError) => (onSuccess) => () => {
  client.auth
    .signOut()
    .then(({ error }) => {
      if (error) onError(error.message)();
      else onSuccess();
    })
    .catch((e) => onError(String(e && e.message ? e.message : e))());
};

export const getSessionImpl = (client) => (just) => (nothing) => (k) => () => {
  client.auth.getSession().then(({ data }) => {
    k(data && data.session ? just(data.session) : nothing)();
  });
};

export const onAuthStateChangeImpl =
  (client) => (just) => (nothing) => (k) => () => {
    const { data } = client.auth.onAuthStateChange((_event, session) => {
      k(session ? just(session) : nothing)();
    });
    return () => {
      data.subscription.unsubscribe();
    };
  };
