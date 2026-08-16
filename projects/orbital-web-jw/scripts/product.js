/* clone panel tabs (idiom from the design system's clone component) */
(function(){
  document.querySelectorAll('[data-orbital="clone"]').forEach(function(cl){
    var tabs=cl.querySelectorAll('.clone-tabs button');
    tabs.forEach(function(b){
      b.addEventListener('click',function(){
        tabs.forEach(function(x){x.classList.toggle('on',x===b);});
        cl.querySelectorAll('[data-pane-for]').forEach(function(p){p.hidden=p.getAttribute('data-pane-for')!==b.dataset.pane;});
      });
    });
    cl.querySelectorAll('.copybtn').forEach(function(btn){
      btn.addEventListener('click',function(){
        var code=btn.parentElement.querySelector('code').textContent;
        navigator.clipboard.writeText(code).then(function(){btn.dataset.state='copied';btn.textContent='Copied';},
          function(){btn.dataset.state='error';});
        setTimeout(function(){delete btn.dataset.state;btn.textContent='Copy';},1600);
      });
    });
  });
})();
