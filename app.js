'use strict';

const STUDIES = [
  {id:1,slug:'tear-off',name:'Tear-off',theme:'tearoff',description:'One day, in red ink. A familiar page to tear off tomorrow.'},
  {id:2,slug:'kalendar-kuda',name:'Kalendar Kuda',theme:'horse',description:'The horse, the red rules, the blue dates. A Malaysian wall-calendar classic.'},
  {id:3,slug:'kopitiam-ledger',name:'Kopitiam Ledger',theme:'ledger',description:'A week of plans, kept between the coffee-shop ledger lines.'},
  {id:4,slug:'kedai-runcit',name:'Kedai Runcit',theme:'runcit',description:'Butter-yellow paper and a calendar from the shop down the road.'},
  {id:5,slug:'batik-margin',name:'Batik Margin',theme:'batik',description:'An open month, with indigo batik along the edge.'},
  {id:6,slug:'postcard-month',name:'Postcard Month',theme:'postcard',description:'A shophouse street above the month. A little postcard on the wall.'},
  {id:7,slug:'rubber-stamp',name:'Rubber Stamp',theme:'stamp',description:'A daily form for appointments and notes, stamped in burgundy.'},
  {id:8,slug:'riso-pop',name:'Riso Pop',theme:'riso',description:'Coral and cobalt, with a big month and a city bus.'},
  {id:9,slug:'midnight-almanac',name:'Midnight Almanac',theme:'midnight',description:'Cream dates and brass rules on a page of dark ink.'}
];

const ANCHOR='2026-10-01';
const MONTHS=['JANUARI','FEBRUARI','MAC','APRIL','MEI','JUN','JULAI','OGOS','SEPTEMBER','OKTOBER','NOVEMBER','DISEMBER'];
const DAYS=['AHAD','ISNIN','SELASA','RABU','KHAMIS','JUMAAT','SABTU'];
const SHORT_DAYS=['AHAD','ISN','SEL','RAB','KHAMIS','JUMAAT','SABTU'];
const DAY_INITIALS=['I','S','R','K','J','S','A'];
const states=new Map();
const storageKey=id=>`malaysian-calendar-v1-${id}`;
const escapeHTML=value=>String(value).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const pad=n=>String(n).padStart(2,'0');
const dateFromISO=value=>{const [y,m,d]=value.split('-').map(Number);return new Date(y,m-1,d,12)};
const isoFromDate=date=>`${date.getFullYear()}-${pad(date.getMonth()+1)}-${pad(date.getDate())}`;
const validISO=value=>typeof value==='string'&&/^\d{4}-\d{2}-\d{2}$/.test(value)&&!Number.isNaN(dateFromISO(value).valueOf())&&isoFromDate(dateFromISO(value))===value&&value>='1900-01-01'&&value<='2100-12-31';
const monthName=date=>MONTHS[date.getMonth()];
const fullLabel=date=>`${DAYS[date.getDay()]}, ${date.getDate()} ${monthName(date)} ${date.getFullYear()}`;
const translated=(date,locale,part)=>new Intl.DateTimeFormat(locale,{[part]:'long'}).format(date);
const announce=text=>{document.getElementById('announcement').textContent=text};

function initialState(id){
  return {selected:ANCHOR,view:id===7?'day':'month',risoCompact:true,ledgerCompact:true,events:[
    {id:`${id}-meeting`,date:ANCHOR,time:'09:00',title:'Mesyuarat',place:'Bilik Mesyuarat, Aras 2',done:false},
    {id:`${id}-dinner`,date:ANCHOR,time:'18:30',title:'Makan keluarga',place:'Rumah',done:false}
  ],notes:{}};
}
function getState(id){
  if(states.has(id))return states.get(id);
  let state=initialState(id);
  try{
    const saved=JSON.parse(localStorage.getItem(storageKey(id)));
    if(saved&&validISO(saved.selected)&&Array.isArray(saved.events)){
      state={...state,...saved,view:['month','day'].includes(saved.view)?saved.view:'month'};
      state.events=state.events.filter(e=>e&&typeof e.id==='string'&&validISO(e.date)&&typeof e.title==='string'&&typeof e.time==='string'&&/^([01]\d|2[0-3]):[0-5]\d$/.test(e.time));
      state.notes=saved.notes&&typeof saved.notes==='object'&&!Array.isArray(saved.notes)?saved.notes:{};
    }
  }catch{ /* The prototype still works when browser storage is unavailable. */ }
  states.set(id,state);return state;
}
function saveState(id){
  try{localStorage.setItem(storageKey(id),JSON.stringify(getState(id)))}catch{announce('Acara disimpan untuk sesi ini. Storan pelayar tidak tersedia.')}
}
function eventsFor(state,iso=state.selected){return state.events.filter(event=>event.date===iso).sort((a,b)=>a.time.localeCompare(b.time)||a.id.localeCompare(b.id))}
function art(kind,extra=''){return `<span class="print-art art-${kind} ${extra}" aria-hidden="true"></span>`}
function multilingual(date){return `<div class="multilingual"><span lang="zh">${escapeHTML(translated(date,'zh-CN','month'))}</span><span lang="en">${escapeHTML(translated(date,'en-GB','month').toUpperCase())}</span><span lang="ta">${escapeHTML(translated(date,'ta-MY','month'))}</span></div>`}
function monthHeading(date,{split=false,compact=false}={}){
  return `<div class="month-title-wrap"><div class="month-nav"><button class="nav-arrow" data-action="month-prev" aria-label="Bulan sebelumnya">‹</button><h3 class="month-heading${split?' split':''}"><span class="month-word">${monthName(date)}</span>${split?'':' '}<span class="year">${date.getFullYear()}</span></h3><button class="nav-arrow" data-action="month-next" aria-label="Bulan seterusnya">›</button></div>${compact?'':multilingual(date)}</div>`;
}
function calendar(state,{mini=false,week=false}={}){
  const selected=dateFromISO(state.selected);
  const start=new Date(selected.getFullYear(),selected.getMonth(),1,12);
  const offset=(start.getDay()+6)%7;
  const daysInMonth=new Date(selected.getFullYear(),selected.getMonth()+1,0,12).getDate();
  let length=Math.ceil((offset+daysInMonth)/7)*7;
  if(week){start.setDate(selected.getDate()-(selected.getDay()+6)%7);length=14}
  const weekdays=DAY_INITIALS.map((day,index)=>`<span class="weekday${index===6?' sunday':''}" aria-label="${DAYS[(index+1)%7]}">${day}</span>`).join('');
  let dates='';
  for(let index=0;index<length;index++){
    const date=new Date(start);
    date.setDate(week?start.getDate()+index:index-offset+1);
    const iso=isoFromDate(date);
    const outside=date.getMonth()!==selected.getMonth();
    if(!week&&outside){dates+='<span class="date-cell blank" aria-hidden="true"></span>';continue}
    const selectedDay=iso===state.selected;
    const hasEvents=eventsFor(state,iso).length>0;
    dates+=`<button type="button" class="date-cell${selectedDay?' selected':''}${date.getDay()===0?' sunday':''}${outside?' outside':''}${hasEvents?' has-events':''}" data-date="${iso}" aria-label="${escapeHTML(fullLabel(date))}${hasEvents?', ada acara':''}" aria-pressed="${selectedDay}"${iso===ANCHOR?' aria-current="date"':''}><span class="date-number">${date.getDate()}</span></button>`;
  }
  return `<div class="calendar${mini?' mini-calendar':''}${week?' week-calendar':''}" aria-label="${week?'Dua minggu':monthName(selected)+' '+selected.getFullYear()}">${weekdays}${dates}</div>`;
}
function eventRows(state,{places=false}={}){
  const rows=eventsFor(state);
  if(!rows.length)return '<p class="empty-events">Tiada acara. Ruang untuk rancangan baru.</p>';
  return rows.map(event=>`<button type="button" class="event-row${event.done?' completed':''}" data-event="${escapeHTML(event.id)}" aria-pressed="${Boolean(event.done)}" aria-label="${escapeHTML(`${event.done?'Tandakan belum selesai':'Tandakan selesai'}: ${event.title}, ${event.time}`)}"><time datetime="${event.date}T${event.time}">${event.time}</time><span class="event-title">${escapeHTML(event.title)}${places&&event.place?`<span class="event-place">${escapeHTML(event.place)}</span>`:''}</span><span class="check" aria-hidden="true">${event.done?'✓':''}</span></button>`).join('');
}
function caption(state){const d=dateFromISO(state.selected);return `<p class="date-caption"><span class="caption-weekday">${DAYS[d.getDay()]}, </span>${d.getDate()} ${monthName(d)} ${d.getFullYear()}</p>`}
function agenda(state,{showCaption=true,places=false}={}){return `<section class="agenda" aria-label="Acara untuk ${escapeHTML(fullLabel(dateFromISO(state.selected)))}">${showCaption?caption(state):''}${eventRows(state,{places})}</section>`}
function addButton(){return '<button type="button" class="add-event" data-action="add">+ Acara</button>'}
function controls(state,{toggle=true,add=true}={}){return `<div class="controls">${toggle?`<div class="view-switch" aria-label="Paparan kalendar"><button type="button" data-action="day" aria-pressed="${state.view==='day'}">Hari</button><button type="button" data-action="month" aria-pressed="${state.view==='month'}">Bulan</button></div>`:''}${add?addButton():''}</div>`}
function selectedDay(state,{expanded=false,motif=false}={}){
  const d=dateFromISO(state.selected);
  return `<div class="selected-day${expanded?' day-expanded':''}"><span class="selected-number">${d.getDate()}</span><div class="selected-day-copy"><h3>${DAYS[d.getDay()]}</h3><p>${escapeHTML(translated(d,'en-GB','weekday'))}</p><p lang="zh">${escapeHTML(translated(d,'zh-CN','weekday'))}</p></div>${motif?art('moon'):''}</div>`;
}
function weekRows(state){
  const date=dateFromISO(state.selected);
  const monday=new Date(date);monday.setDate(date.getDate()-(date.getDay()+6)%7);
  let rows='<div class="ledger-columns" aria-hidden="true"><span></span><span></span><span>ACARA</span></div>';
  for(let n=0;n<7;n++){
    const day=new Date(monday);day.setDate(monday.getDate()+n);const iso=isoFromDate(day);const selected=iso===state.selected;
    const dayEvents=eventsFor(state,iso);
    rows+=`<div class="ledger-row${selected?' is-selected':''}"><div class="ledger-day"><button class="ledger-num${day.getDay()===0?' sunday':''}" data-date="${iso}" aria-label="${escapeHTML(fullLabel(day))}" aria-pressed="${selected}">${day.getDate()}</button><button class="${day.getDay()===0?'sunday':''}" data-date="${iso}" aria-label="${escapeHTML(fullLabel(day))}" aria-pressed="${selected}">${selected?DAYS[day.getDay()].charAt(0)+DAYS[day.getDay()].slice(1).toLowerCase():SHORT_DAYS[day.getDay()]}</button></div><div class="ledger-events">${dayEvents.map(event=>`<button class="ledger-event${event.done?' completed':''}" data-event="${escapeHTML(event.id)}" aria-label="${escapeHTML(`${event.done?'Tandakan belum selesai':'Tandakan selesai'}: ${event.title}, ${event.time}`)}" aria-pressed="${Boolean(event.done)}">${event.time}&nbsp; ${escapeHTML(event.title)}</button>`).join('')}</div></div>`;
  }
  return `<section class="ledger-table" aria-label="Agenda mingguan">${rows}<div class="ledger-tail" aria-hidden="true"><span></span><span></span><span></span></div></section>`;
}
function renderScreen(study,state){
  const date=dateFromISO(state.selected);
  const d=date.getDate();
  switch(study.id){
    case 1:return `<div class="binding" aria-hidden="true"><i></i><i></i></div>${monthHeading(date,{compact:true})}<div class="tear-date${d>=10?' two-digit':''}">${d}</div><h3 class="tear-weekday">${DAYS[date.getDay()]}</h3><div class="tear-translations"><span lang="zh">${escapeHTML(translated(date,'zh-CN','weekday'))}</span><span lang="en">${escapeHTML(translated(date,'en-GB','weekday').toUpperCase())}</span><span lang="ta">${escapeHTML(translated(date,'ta-MY','weekday'))}</span></div><div class="tear-month">${calendar(state,{mini:true})}<div class="tear-month-label">${monthName(date)}<br>${escapeHTML(translated(date,'en-GB','month'))}<br><span lang="zh">${escapeHTML(translated(date,'zh-CN','month'))}</span></div></div>${agenda(state,{showCaption:false})}${controls(state,{toggle:false})}`;
    case 2:return `<header class="horse-masthead"><h3>KALENDAR</h3><div class="horse-copy" lang="zh">萬用<br>實用<br>天天進步<small>KALENDAR KUDA<br>馬牌日曆</small></div>${art('horse')}</header>${monthHeading(date)}${calendar(state)}${selectedDay(state,{expanded:true})}${agenda(state)}${controls(state)}`;
    case 3:return `<header class="coffee-masthead"><h3><small>KEDAI KOPI</small>SINAR PAGI</h3><p class="chinese" lang="zh">新早晨咖啡店</p>${art('coffee')}<p class="strapline">KOPI · ROTI · KAWAN · JADUAL HIDUP</p></header>${monthHeading(date,{compact:true})}${state.view==='day'?`${selectedDay(state)}${agenda(state,{showCaption:false,places:true})}`:state.ledgerCompact?weekRows(state):`${calendar(state)}${agenda(state)}`}${controls(state)}`;
    case 4:return `<header class="shop-masthead"><h3>HARI HARI</h3><h4>KEDAI RUNCIT</h4>${art('goods')}<p>BERAS · GULA · MINYAK MASAK<br>TEPUNG · MINUMAN · BARANG HARIAN</p></header>${monthHeading(date)}${calendar(state)}<div class="receipt">${agenda(state)}${controls(state,{toggle:false})}</div>`;
    case 5:return `<div class="batik-strip" aria-hidden="true"></div>${monthHeading(date,{split:true})}${calendar(state)}${selectedDay(state,{expanded:true})}${agenda(state)}${controls(state)}`;
    case 6:return `<div class="postcard-picture"><img src="assets/postcard-street.png" alt="Vintage illustration of Malaysian shophouses and palm trees"><span class="postcard-greeting">Selamat Datang<br>ke<strong>MALAYSIA</strong></span></div>${monthHeading(date)}${calendar(state)}${selectedDay(state,{expanded:true})}<div class="postcard-bottom">${art('flower')}${agenda(state)}</div>${controls(state)}`;
    case 7:return `<header class="stamp-header"><p>PELAN<br>JADUAL<br>HARIAN</p><p class="serial">No. ${pad(date.getMonth()+1)}${pad(date.getDate())}28</p><div class="weekday-stamp">${DAYS[date.getDay()]}</div></header><h3 class="stamp-date">${pad(d)} / ${pad(date.getMonth()+1)} / ${date.getFullYear()}</h3>${monthHeading(date,{compact:true})}${state.view==='month'?calendar(state):''}${agenda(state,{showCaption:false,places:true})}<label class="stamp-notes" for="notes-${study.id}">NOTA<textarea id="notes-${study.id}" data-notes="${state.selected}" aria-label="Nota untuk ${escapeHTML(fullLabel(date))}" maxlength="500" spellcheck="false">${escapeHTML(state.notes[state.selected]||'')}</textarea></label><div class="stamp-footer"><div><p class="stamp-mini-title">${monthName(date)} ${date.getFullYear()}</p>${calendar(state,{mini:true})}</div><div class="print-seal" aria-hidden="true"><span>JADUAL</span><strong>★</strong><span>HARIAN</span></div></div>${controls(state)}`;
    case 8:return `<header class="riso-masthead"><h3>${monthName(date).slice(0,3)}</h3><p class="riso-year">${date.getFullYear()}</p>${art('flower')}<div class="riso-languages"><span><span lang="zh">${escapeHTML(translated(date,'zh-CN','month'))}</span>&nbsp; ${escapeHTML(translated(date,'en-GB','month').toUpperCase())}</span><span lang="ta">${escapeHTML(translated(date,'ta-MY','month'))}</span></div></header>${calendar(state,{week:state.risoCompact})}${state.view==='month'&&state.risoCompact?'<div class="week-navigation"><button data-action="week-prev" aria-label="Minggu sebelumnya">‹</button><span>DUA MINGGU</span><button data-action="week-next" aria-label="Minggu seterusnya">›</button></div>':''}${selectedDay(state,{expanded:true})}<div class="riso-bottom">${art('bus')}<section class="agenda" aria-label="Acara hari ini">${caption(state)}${eventRows(state)}${addButton()}</section></div>${controls(state,{add:false})}`;
    case 9:return `${art('moon')}${monthHeading(date)}${calendar(state)}${selectedDay(state,{motif:true})}${agenda(state,{showCaption:false})}${controls(state)}`;
    default:return '';
  }
}
function renderStudy(id){
  const study=STUDIES.find(s=>s.id===id),state=getState(id);
  const screen=document.querySelector(`.screen[data-study="${id}"]`);
  if(!screen)return;
  // The daily stamp is the reference default; its month tab is an expanded view.
  screen.dataset.view=state.view;
  screen.innerHTML=renderScreen(study,state);
}
function mountStudy(study,solo=false){
  const article=document.createElement('article');article.className='study';article.id=study.slug;
  article.innerHTML=`<div class="study-heading"><h2><span class="number">${pad(study.id)}</span>${study.name}</h2>${solo?'':`<a class="study-link" href="${study.slug}.html">OPEN ↗</a>`}</div><section class="screen ${study.theme}" data-study="${study.id}" aria-label="${study.name}" lang="ms"></section><p class="study-description">${study.description}</p>`;
  return article;
}
const filename=location.pathname.split('/').pop().replace(/\.html$/,'');
const soloStudy=STUDIES.find(study=>study.slug===filename);
const container=document.getElementById('studies');
if(soloStudy){
  document.body.classList.add('solo');
  document.title=`${soloStudy.name} · Kalendar`;
  const index=STUDIES.indexOf(soloStudy);
  const prev=STUDIES[(index+8)%9],next=STUDIES[(index+1)%9];
  document.querySelector('.gallery-header').outerHTML=`<header class="solo-header"><a href="index.html">← All nine designs</a><nav aria-label="Browse designs"><a href="${prev.slug}.html" aria-label="Previous design: ${prev.name}">← ${pad(prev.id)}</a><a href="${next.slug}.html" aria-label="Next design: ${next.name}">${pad(next.id)} →</a></nav></header>`;
  container.className='solo-main';container.append(mountStudy(soloStudy,true));
  document.querySelector('.gallery-footer').outerHTML='<footer class="solo-footer">Appointments stay in this browser. <button class="reset-demo" data-reset="current">Reset demo</button></footer>';
  if(soloStudy.id===7&&!localStorageSafeHas(7))getState(7).view='day';
  renderStudy(soloStudy.id);
}else{
  STUDIES.forEach(study=>{if(study.id===7&&!localStorageSafeHas(7))getState(7).view='day';container.append(mountStudy(study));renderStudy(study.id)});
}
function localStorageSafeHas(id){try{return Boolean(localStorage.getItem(storageKey(id)))}catch{return false}}

function shiftDate(id,{months=0,days=0}={}){
  const state=getState(id),date=dateFromISO(state.selected);
  if(months){const day=date.getDate();date.setDate(1);date.setMonth(date.getMonth()+months);date.setDate(Math.min(day,new Date(date.getFullYear(),date.getMonth()+1,0).getDate()))}
  if(days)date.setDate(date.getDate()+days);
  const next=isoFromDate(date);if(!validISO(next))return;
  state.selected=next;saveState(id);renderStudy(id);announce(fullLabel(date));
}
const dialog=document.getElementById('event-dialog'),form=document.getElementById('event-form');
const resetPrompt=document.createElement('dialog');
resetPrompt.id='reset-dialog';resetPrompt.className='event-dialog';resetPrompt.setAttribute('aria-labelledby','reset-title');
resetPrompt.innerHTML='<div class="dialog-heading"><h2 id="reset-title">Reset demo?</h2></div><p>Return to 1 October 2026. Added appointments and notes in these demo designs will be cleared.</p><div class="reset-actions"><button class="cancel-reset" type="button">Keep my changes</button><button class="confirm-reset save-event" type="button">Reset demo</button></div>';
document.body.append(resetPrompt);
let activeId=null,returnFocus=null;
function openEvent(id,button){
  activeId=id;returnFocus=button;form.reset();form.elements.date.value=getState(id).selected;form.elements.time.value='09:00';
  const screen=document.querySelector(`.screen[data-study="${id}"]`);
  const style=getComputedStyle(screen);
  dialog.style.setProperty('--modal-paper',id===9?'#f2e7cf':style.getPropertyValue('--paper'));
  dialog.style.setProperty('--modal-ink',id===9?'#272822':style.getPropertyValue('--ink'));
  dialog.style.setProperty('--modal-accent',style.getPropertyValue('--accent'));
  dialog.showModal();form.elements.title.focus();
}
function closeEvent(){dialog.close();if(returnFocus?.isConnected)returnFocus.focus();else document.querySelector(`.screen[data-study="${activeId}"] [data-action="add"]`)?.focus()}
document.addEventListener('click',event=>{
  const target=event.target.closest('button');if(!target)return;
  if(target.dataset.reset){
    resetPrompt.querySelector('p').textContent=`Return ${soloStudy?'this design':'all nine designs'} to 1 October 2026. Added appointments and notes will be cleared.`;
    resetPrompt.showModal();resetPrompt.querySelector('.cancel-reset').focus();return;
  }
  if(target.classList.contains('cancel-reset')){resetPrompt.close();return}
  if(target.classList.contains('confirm-reset')){
    const ids=soloStudy?[soloStudy.id]:STUDIES.map(study=>study.id);
    ids.forEach(id=>{states.set(id,initialState(id));saveState(id);renderStudy(id)});resetPrompt.close();announce('Demo reset to 1 October 2026.');document.querySelector('.reset-demo')?.focus();return;
  }
  if(target.classList.contains('close-dialog')){closeEvent();return}
  const screen=target.closest('.screen');if(!screen)return;
  const id=Number(screen.dataset.study),state=getState(id);
  if(target.dataset.date){
    if(!validISO(target.dataset.date))return;state.selected=target.dataset.date;saveState(id);renderStudy(id);
    document.querySelector(`.screen[data-study="${id}"] [data-date="${state.selected}"]`)?.focus({preventScroll:true});
    announce(fullLabel(dateFromISO(state.selected)));return;
  }
  if(target.dataset.event){
    const item=state.events.find(e=>e.id===target.dataset.event);if(!item)return;
    item.done=!item.done;saveState(id);renderStudy(id);
    document.querySelector(`.screen[data-study="${id}"] [data-event="${CSS.escape(item.id)}"]`)?.focus({preventScroll:true});
    announce(`${item.title}: ${item.done?'selesai':'belum selesai'}`);return;
  }
  switch(target.dataset.action){
    case 'add':openEvent(id,target);break;
    case 'day':state.view='day';saveState(id);renderStudy(id);document.querySelector(`.screen[data-study="${id}"] [data-action="day"]`)?.focus({preventScroll:true});break;
    case 'month':state.view='month';if(id===8)state.risoCompact=false;if(id===3)state.ledgerCompact=false;saveState(id);renderStudy(id);document.querySelector(`.screen[data-study="${id}"] [data-action="month"]`)?.focus({preventScroll:true});break;
    case 'month-prev':shiftDate(id,{months:-1});break;
    case 'month-next':shiftDate(id,{months:1});break;
    case 'week-prev':shiftDate(id,{days:-7});break;
    case 'week-next':shiftDate(id,{days:7});break;
  }
});
document.addEventListener('input',event=>{
  if(!event.target.matches('[data-notes]'))return;
  const id=Number(event.target.closest('.screen').dataset.study);
  getState(id).notes[event.target.dataset.notes]=event.target.value;saveState(id);
});
form.addEventListener('submit',event=>{
  event.preventDefault();if(activeId===null)return;
  const data=new FormData(form),date=String(data.get('date')),title=String(data.get('title')).trim(),time=String(data.get('time'));
  if(!title){form.elements.title.setCustomValidity('Masukkan nama acara.');form.elements.title.reportValidity();return}
  if(!validISO(date)||!/^([01]\d|2[0-3]):[0-5]\d$/.test(time))return;
  const state=getState(activeId);
  state.events.push({id:crypto.randomUUID?.()||`${Date.now()}-${Math.random()}`,date,time,title,place:String(data.get('place')||'').trim(),done:false});state.selected=date;
  saveState(activeId);renderStudy(activeId);closeEvent();announce(`Acara ${title} disimpan untuk ${fullLabel(dateFromISO(date))}.`);
});
form.elements.title.addEventListener('input',()=>form.elements.title.setCustomValidity(''));
dialog.addEventListener('click',event=>{if(event.target===dialog){const rect=dialog.getBoundingClientRect();if(event.clientX<rect.left||event.clientX>rect.right||event.clientY<rect.top||event.clientY>rect.bottom)closeEvent()}});
dialog.addEventListener('cancel',()=>{requestAnimationFrame(()=>returnFocus?.isConnected?returnFocus.focus():document.querySelector(`.screen[data-study="${activeId}"] [data-action="add"]`)?.focus())});
