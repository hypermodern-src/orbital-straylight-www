/* ============================================================
   ORBITAL waitlist: pre-launch early-access capture.
   Signup forms, referral attribution (?r=CODE), live counter.
   Backend: Supabase, RPC functions only. The signups table has
   RLS enabled with no policies and all direct grants revoked,
   so this public key can never read or write rows directly;
   email addresses are not retrievable from the browser.
   ============================================================ */
(function () {
  'use strict';
  var API = 'https://lhmodcikykyoxpaojeyn.supabase.co/rest/v1/rpc/';
  var KEY = 'sb_publishable_i5m1V-qbdRMsNM9ulCIBIg_yQKuuKg7'; /* publishable key, safe to ship */
  /* Show the live counter only once it is a meaningful number; it is always
     a real count, never seeded. TODO(team): revisit threshold before launch. */
  var COUNTER_MIN = 25;

  function rpc(fn, body) {
    return fetch(API + fn, {
      method: 'POST',
      headers: { apikey: KEY, Authorization: 'Bearer ' + KEY, 'Content-Type': 'application/json' },
      body: JSON.stringify(body || {})
    }).then(function (r) {
      if (!r.ok) throw new Error('rpc ' + fn + ' -> ' + r.status);
      return r.json();
    });
  }
  window.ORBITALWaitlist = { rpc: rpc };

  /* referral attribution: ?r=CODE persists until the visitor signs up */
  try {
    var ref = new URLSearchParams(location.search).get('r');
    if (ref && /^[a-f0-9]{6,32}$/i.test(ref)) localStorage.setItem('orbital-ref', ref);
  } catch (e) {}

  /* live counter: [data-waitlist-count] elements stay hidden below threshold */
  document.querySelectorAll('[data-waitlist-count]').forEach(function (el) {
    rpc('waitlist_count').then(function (n) {
      if (typeof n === 'number' && n >= COUNTER_MIN) {
        el.querySelector('b').textContent = n.toLocaleString();
        el.hidden = false;
      }
    }).catch(function () {});
  });

  /* signup forms: <form data-waitlist="cache|build|platform"> */
  document.querySelectorAll('form[data-waitlist]').forEach(function (form) {
    var msg = form.querySelector('.ea-msg');
    form.addEventListener('submit', function (e) {
      e.preventDefault();
      var btn = form.querySelector('button[type="submit"]');
      var email = form.querySelector('input[type="email"]').value.trim();
      var sel = form.querySelector('select');
      if (msg) msg.hidden = true;
      btn.disabled = true;
      btn.textContent = 'Joining…';
      rpc('join_waitlist', {
        p_email: email,
        p_product: form.dataset.waitlist,
        p_builds_with: sel ? sel.value : null,
        p_referred_by: (function () { try { return localStorage.getItem('orbital-ref'); } catch (e) { return null; } })()
      }).then(function (res) {
        try {
          localStorage.setItem('orbital-waitlist', JSON.stringify({
            email: email,
            product: form.dataset.waitlist,
            code: res.referral_code,
            position: res.position,
            existing: !!res.existing
          }));
        } catch (e) {}
        location.href = 'thanks.html';
      }).catch(function () {
        btn.disabled = false;
        btn.textContent = 'Get early access';
        if (msg) msg.hidden = false;
      });
    });
  });
})();
