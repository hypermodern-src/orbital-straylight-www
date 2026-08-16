(function(){
  'use strict';
  var data=null;
  try{ data=JSON.parse(localStorage.getItem('orbital-waitlist')||'null'); }catch(e){}
  if(!data||!data.code){
    document.getElementById('tkLink').textContent='Join the list first: orbital cache, build, or infer page';
    return;
  }
  var pages={build:'build.html',cache:'cache.html',infer:'infer.html',platform:'index.html'};
  var page=pages[data.product]||'index.html';
  /* TODO(team): swap origin for the production domain at launch */
  var link=location.origin+location.pathname.replace(/thanks\.html$/,page)+'?r='+data.code;
  var pos=document.getElementById('tkPos');
  var pname=data.product==='platform'?'Orbital':data.product.toUpperCase();
  if(typeof data.position==='number'){ pos.textContent='#'+data.position+' on the '+pname+' early-access list'; pos.hidden=false; }
  document.getElementById('tkLink').textContent=link;
  document.getElementById('tkShare').value='Orbital is shipping native, verifiable developer infrastructure for storage, builds, and AI inference. Early access: '+link;

  function wireCopy(btnId,getText){
    var btn=document.getElementById(btnId);
    btn.addEventListener('click',function(){
      navigator.clipboard.writeText(getText()).then(function(){btn.dataset.state='copied';btn.textContent='Copied';},function(){btn.dataset.state='error';});
      setTimeout(function(){delete btn.dataset.state;btn.textContent=btnId==='tkCopyLink'?'Copy':'Copy text';},1600);
    });
  }
  wireCopy('tkCopyLink',function(){return link;});
  wireCopy('tkCopyShare',function(){return document.getElementById('tkShare').value;});

  /* one-tap shares, prefilled at the moment intent is highest */
  var shareText=document.getElementById('tkShare').value;
  document.getElementById('tkShareX').href='https://x.com/intent/post?text='+encodeURIComponent(shareText);
  document.getElementById('tkShareHn').href='https://news.ycombinator.com/submitlink?u='+encodeURIComponent(link)+'&t='+encodeURIComponent('Orbital: verified build infrastructure, early access');
  document.getElementById('tkShareLi').href='https://www.linkedin.com/sharing/share-offsite/?url='+encodeURIComponent(link);

  /* live referral progress */
  window.ORBITALWaitlist.rpc('referral_count',{p_code:data.code}).then(function(n){
    if(typeof n!=='number')return;
    var pct=Math.min(n,3)/3*100;
    document.getElementById('tkFill').style.width=pct+'%';
    document.querySelectorAll('#tkRewards li').forEach(function(li){
      if(n>=parseInt(li.dataset.at,10)) li.classList.add('done');
    });
  }).catch(function(){});
})();
