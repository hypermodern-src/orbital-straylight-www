/* ============================================================
   HM THEME — shared light/dark (Ono-sendai) toggle
   Applies the saved theme on load and injects a toggle button
   into the page nav. Drop <script src="orbital-theme.js"></script> on
   any surface; idempotent (won't double-inject).
   ============================================================ */
(function(){
  'use strict';
  var root=document.documentElement, KEY='orbital-theme', DARK='onosendai';
  // 1) apply saved theme ASAP
  try{ var saved=localStorage.getItem(KEY); if(saved) root.setAttribute('data-theme',saved); }catch(e){}

  var SUN='<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.3"><circle cx="8" cy="8" r="3.4"/><path d="M8 1v2M8 13v2M1 8h2M13 8h2M3.2 3.2l1.4 1.4M11.4 11.4l1.4 1.4M12.8 3.2l-1.4 1.4M4.6 11.4l-1.4 1.4"/></svg>';
  var MOON='<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.3"><path d="M13.5 9.2A5.3 5.3 0 1 1 6.8 2.5a4.2 4.2 0 0 0 6.7 6.7z"/></svg>';

  function isDark(){ return root.getAttribute('data-theme')===DARK; }
  function paint(btn){ btn.innerHTML = isDark()?MOON:SUN; btn.title = isDark()?'Ono-sendai \u2014 dark':'Toggle Ono-sendai'; }
  function toggle(btn){
    if(isDark()){ root.removeAttribute('data-theme'); try{localStorage.removeItem(KEY);}catch(e){} }
    else { root.setAttribute('data-theme',DARK); try{localStorage.setItem(KEY,DARK);}catch(e){} }
    paint(btn);
  }
  function wire(btn){ paint(btn); btn.addEventListener('click',function(){ toggle(btn); }); }

  function mount(){
    // already present? just wire it.
    var existing=document.querySelector('.theme-tog');
    if(existing){ wire(existing); return; }
    // find a nav host: prefer the top nav link row, else the bar's nav, else the sidebar topbar actions
    var host=document.querySelector('.topnav')
          || document.querySelector('.bar nav')
          || document.querySelector('.nav .nl')
          || document.querySelector('.shell-topbar .shell-actions')
          || document.querySelector('.shell-actions');
    if(!host) return;
    var btn=document.createElement('button');
    btn.className='theme-tog'; btn.setAttribute('aria-label','Toggle theme');
    // a divider before it on link-row navs (not on icon-action rows)
    if(host.classList.contains('topnav') || host.matches('.bar nav') || host.classList.contains('nl')){
      var div=document.createElement('span'); div.className='nav-div'; host.appendChild(div);
    }
    host.appendChild(btn);
    wire(btn);
  }
  if(document.readyState==='loading') document.addEventListener('DOMContentLoaded',mount);
  else mount();
})();
