// tobs_notify: the page. Each message's outline is drawn by a beam of light (an SVG stroke), then the inside fills and
// the words appear; on the way out the beam runs off. The outline's shape says the kind.
'use strict';

const IN_GAME = typeof GetParentResourceName === 'function';
const RES = IN_GAME ? GetParentResourceName() : 'tobs_notify';
const post = (name, data) => IN_GAME
  ? fetch(`https://${RES}/${name}`, { method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' }, body: JSON.stringify(data || {}) })
      .then(r => r.json()).catch(() => null)
  : Promise.resolve(null);

const ICONS = {
  check: '<svg viewBox="0 0 24 24"><path d="M5 12.5l4.5 4.5L19 7.5" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/></svg>',
  cross: '<svg viewBox="0 0 24 24"><path d="M7 7l10 10M17 7L7 17" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round"/></svg>',
  alert: '<svg viewBox="0 0 24 24"><path d="M12 6v8" fill="none" stroke="currentColor" stroke-width="2.8" stroke-linecap="round"/><circle cx="12" cy="18.6" r="1.6" fill="currentColor"/></svg>',
  info: '<svg viewBox="0 0 24 24"><path d="M12 11v7" fill="none" stroke="currentColor" stroke-width="2.8" stroke-linecap="round"/><circle cx="12" cy="6.6" r="1.6" fill="currentColor"/></svg>',
};

let CFG = null;
const active = [];          // shown now, newest first
const waiting = [];         // over the limit: shown when one goes
const root = document.getElementById('root');
let pile = null, island = null, cap = null;
let reportedCount = -1;

/* ---------- shapes: soft corners, notched sides, cut corners, round ends ---------- */
function shapePath(shape, W, H, x = 1, y = 1) {
  const x1 = x + W, y1 = y + H, m = y + H / 2;
  if (shape === 'soft') {
    const r = Math.min(14, H / 3);
    return `M${x + r} ${y} H${x1 - r} Q${x1} ${y} ${x1} ${y + r} V${y1 - r} Q${x1} ${y1} ${x1 - r} ${y1} H${x + r} Q${x} ${y1} ${x} ${y1 - r} V${y + r} Q${x} ${y} ${x + r} ${y} Z`;
  }
  if (shape === 'notched') {
    const n = Math.min(10, H / 4);
    return `M${x} ${y} H${x1} V${m - n} L${x1 - n} ${m} L${x1} ${m + n} V${y1} H${x} V${m + n} L${x + n} ${m} L${x} ${m - n} Z`;
  }
  if (shape === 'cut') {
    const c = Math.min(16, H / 3);
    return `M${x + c} ${y} H${x1} V${y1 - c} L${x1 - c} ${y1} H${x} V${y + c} Z`;
  }
  const R = H / 2;      // round ends
  if (W <= H) return `M${x + R} ${y} A${R} ${R} 0 1 1 ${x + R} ${y1} A${R} ${R} 0 1 1 ${x + R} ${y} Z`;
  return `M${x + R} ${y} H${x1 - R} A${R} ${R} 0 0 1 ${x1 - R} ${y1} H${x + R} A${R} ${R} 0 0 1 ${x + R} ${y} Z`;
}

const kindOf = m => (CFG.kinds[m.type] || CFG.kinds.info);
const keyOf = m => `${m.type}|${m.title || ''}|${m.text || ''}`;
const limit = () => CFG.style === 'island' ? 1 : Math.max(1, CFG.maxVisible || 4);

function iconHTML(m, kind) {
  const name = m.icon || kind.icon;
  if (ICONS[name]) return ICONS[name];
  if (CFG.fontAwesome && /^[a-z0-9-]+$/.test(name)) return `<i class="fa-solid fa-${name}"></i>`;
  return ICONS[kind.icon] || ICONS.info;
}

/* ---------- building one message ---------- */
function build(m) {
  const kind = kindOf(m);
  const el = document.createElement('div');
  el.className = `n k-${kind.shape}`;
  el.style.setProperty('--c', kind.color);
  const edge = '<svg class="edge" aria-hidden="true"><path class="fill"/><path class="line"/></svg>';
  if (CFG.style === 'badge') {
    el.innerHTML = `<div class="words"><div class="ti"><span class="t"></span><span class="x"></span></div><div class="tx"></div></div><div class="badge">${edge}<span class="ic"></span></div>`;
  } else {
    el.innerHTML = `${edge}<div class="body"><span class="ic"></span><div class="words"><div class="ti"><span class="t"></span><span class="x"></span></div><div class="tx"></div></div></div>`;
  }
  fill(el, m, kind);
  return el;
}

function fill(el, m, kind) {
  el.querySelector('.ic').innerHTML = iconHTML(m, kind);
  el.querySelector('.t').textContent = m.title || '';
  el.querySelector('.tx').textContent = m.text || '';
  const x = el.querySelector('.x');
  x.textContent = m.count > 1 ? `×${m.count}` : '';
  el.querySelector('.ti').style.display = (m.title || m.count > 1) ? '' : 'none';
  el.querySelector('.tx').style.display = m.text ? '' : 'none';
}

/* the outline for the element's size; drawn by the light when `enter` */
function drawEdge(el, kind, enter) {
  const svg = el.querySelector('svg.edge');
  const box = svg.parentElement;
  const w = box.clientWidth, h = box.clientHeight;
  if (!w || !h) return;
  svg.setAttribute('viewBox', `0 0 ${w} ${h}`);
  const d = shapePath(kind.shape, w - 2, h - 2, 1, 1);
  const line = svg.querySelector('.line'), fillP = svg.querySelector('.fill');
  line.setAttribute('d', d); fillP.setAttribute('d', d);
  const len = line.getTotalLength();
  if (!enter || CFG.reduced) { line.style.strokeDasharray = 'none'; return; }
  const ms = CFG.drawMs || 650;
  line.style.strokeDasharray = `${len}`;
  line.animate([{ strokeDashoffset: len }, { strokeDashoffset: 0 }], { duration: ms, easing: 'cubic-bezier(.55,.05,.35,1)', fill: 'both' });
  const content = el.querySelector('.body') || el.querySelector('.words');
  const fade = { duration: ms * 0.5, delay: ms * 0.5, easing: 'ease-out', fill: 'backwards' };
  fillP.animate([{ opacity: 0 }, { opacity: 1 }], fade);
  content.animate([{ opacity: 0, transform: 'translateY(3px)' }, { opacity: 1, transform: 'none' }], fade);
  if (CFG.style === 'badge') el.querySelector('.ic').animate([{ opacity: 0 }, { opacity: 1 }], fade);
}

/* ---------- show, repeat, update, close ---------- */
function show(m) {
  // the same message again while it shows: one message with ×n, its time starts again
  const same = active.find(a => (m.idGiven && a.m.id === m.id) || (!m.idGiven && !a.m.idGiven && a.key === keyOf(m)));
  if (same && !m.idGiven) return repeat(same);
  if (same && m.idGiven) return update(m);
  const queuedSame = waiting.find(w => !m.idGiven && keyOf(w) === keyOf(m));
  if (queuedSame) { queuedSame.count = (queuedSame.count || 1) + 1; return; }
  if (active.length >= limit()) { waiting.push(m); report(); return; }
  open(m);
}

function open(m) {
  m.count = m.count || 1;
  const kind = kindOf(m);
  const el = build(m);
  const item = { m, el, key: keyOf(m), timer: null };
  if (CFG.style === 'island') {
    island.classList.add('busy');
    island.append(el);
  } else {
    pile.prepend(el);
  }
  active.unshift(item);
  requestAnimationFrame(() => drawEdge(el, kind, true));
  arm(item);
  dims();
  report();
}

function arm(item) {
  clearTimeout(item.timer);
  const ms = item.m.duration;
  if (ms > 0) item.timer = setTimeout(() => leave(item), ms + (CFG.reduced ? 0 : CFG.drawMs || 650));
}

function repeat(item) {
  item.m.count = (item.m.count || 1) + 1;
  fill(item.el, item.m, kindOf(item.m));
  requestAnimationFrame(() => drawEdge(item.el, kindOf(item.m), false));
  item.el.classList.remove('pulse'); void item.el.offsetWidth; item.el.classList.add('pulse');
  arm(item);
}

function update(m) {
  const item = active.find(a => a.m.id === m.id);
  if (!item) {
    const q = waiting.findIndex(w => w.id === m.id);
    if (q >= 0) { waiting[q] = m; return; }
    return show(m);
  }
  const kind = kindOf(m);
  m.count = item.m.count;
  item.m = m; item.key = keyOf(m);
  item.el.className = `n k-${kind.shape}`;
  item.el.style.setProperty('--c', kind.color);
  fill(item.el, m, kind);
  requestAnimationFrame(() => drawEdge(item.el, kind, false));
  item.el.classList.remove('pulse'); void item.el.offsetWidth; item.el.classList.add('pulse');
  arm(item);
  dims();
}

function close(id) {
  const q = waiting.findIndex(w => w.id === id);
  if (q >= 0) { waiting.splice(q, 1); report(); }
  const item = active.find(a => a.m.id === id);
  if (item) leave(item);
}

function leave(item) {
  if (item.leaving) return;
  item.leaving = true;
  clearTimeout(item.timer);
  const done = () => {
    item.el.remove();
    const i = active.indexOf(item);
    if (i >= 0) active.splice(i, 1);
    if (CFG.style === 'island' && !active.length) island.classList.remove('busy');
    if (waiting.length && active.length < limit()) open(waiting.shift());
    dims();
    report();
  };
  if (CFG.reduced) return done();
  const svg = item.el.querySelector('svg.edge');
  const line = svg.querySelector('.line');
  const len = line.getTotalLength();
  line.style.strokeDasharray = `${len}`;
  line.animate([{ strokeDashoffset: 0 }, { strokeDashoffset: -len }], { duration: 450, easing: 'cubic-bezier(.55,.05,.35,1)', fill: 'forwards' });
  const content = item.el.querySelector('.body') || item.el.querySelector('.words');
  const out = { duration: 260, easing: 'ease-in', fill: 'forwards' };
  svg.querySelector('.fill').animate([{ opacity: 1 }, { opacity: 0 }], out);
  content.animate([{ opacity: 1 }, { opacity: 0 }], out);
  if (CFG.style === 'badge') item.el.querySelector('.ic').animate([{ opacity: 1 }, { opacity: 0 }], out);
  setTimeout(done, 460);
}

// badge: the newest is bright, older ones dimmer
function dims() {
  if (CFG.style !== 'badge') return;
  active.forEach((a, i) => {
    a.el.classList.toggle('dim', i === 1);
    a.el.classList.toggle('dim2', i >= 2);
  });
}

function report() {
  const n = active.length + waiting.length;
  if (n === reportedCount) return;
  reportedCount = n;
  post('count', { n });
}

/* ---------- set up from the config ---------- */
function setup(cfg) {
  CFG = cfg;
  document.documentElement.style.setProperty('--scale', String(cfg.scale || 1));
  root.className = `s-${cfg.style}${cfg.reduced ? ' reduced' : ''}`;
  if (cfg.fontAwesome) {
    const fa = document.createElement('link');
    fa.rel = 'stylesheet';
    fa.href = 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css';
    document.head.append(fa);
  }
  pile = document.createElement('div');
  const pos = cfg.position || 'middle-right';
  pile.className = `pile ${pos}${pos.includes('left') ? ' left' : ''}`;
  root.append(pile);
  if (cfg.style === 'island') {
    island = document.createElement('div');
    island.className = 'island';
    if (cfg.islandIdle !== 'none') {
      cap = document.createElement('div');
      cap.className = 'cap' + (cfg.islandIdle === 'dot' ? ' dot' : '');
      island.append(cap);
      const tick = () => { const d = new Date(); cap.textContent = `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`; };
      tick(); setInterval(tick, 15000);
    }
    pile.append(island);
  }
}

window.addEventListener('message', e => {
  const d = e.data;
  if (!d || !CFG) return;
  if (d.action === 'notify') { const m = d.data; m.idGiven = !!m.idGiven; show(m); }
  else if (d.action === 'update') { const m = d.data; m.idGiven = true; update(m); }
  else if (d.action === 'close') close(d.id);
  else if (d.action === 'hidden') root.classList.toggle('hidden', !!d.hidden);
});

/* ---------- start: the config from the game, or an example in a browser (?style=badge&position=top-left) ---------- */
if (IN_GAME) {
  post('ready').then(cfg => { if (cfg) setup(cfg); });
} else {
  const q = new URLSearchParams(location.search);
  setup({
    style: q.get('style') || 'island', position: q.get('position') || 'middle-right', maxVisible: 4, scale: 1, drawMs: 650,
    reduced: q.has('reduced'), islandIdle: q.get('idle') || 'none', fontAwesome: true,
    kinds: {
      success: { color: '#6ab04c', shape: 'soft', icon: 'check' }, error: { color: '#ff6b7a', shape: 'notched', icon: 'cross' },
      warning: { color: '#f6b93b', shape: 'cut', icon: 'alert' }, info: { color: '#48a6ff', shape: 'round', icon: 'info' },
    },
  });
  document.documentElement.style.background = 'linear-gradient(160deg,#4a5a6a,#2a3038 60%,#1c2026)';
  document.documentElement.style.minHeight = '100%';
  const demo = [
    { type: 'success', title: 'Car stored', text: 'Krieger is in Legion Garage Parking', duration: 5000 },
    { type: 'error', title: 'Not enough money', text: 'You need $2,500 in the bank', duration: 5000 },
    { type: 'warning', title: 'Wanted plate', text: '86TDE835 read at Legion Garage Plate reader', duration: 5000 },
    { type: 'info', title: 'New message', text: 'Unknown number: "Meet at the pier"', duration: 5000 },
    { type: 'info', title: 'New message', text: 'Unknown number: "Meet at the pier"', duration: 5000 },
    { type: 'info', text: 'A longer message without a title, to see how the shape grows with the words and wraps onto a second line.', duration: 6000 },
  ];
  let i = 0;
  setInterval(() => { const m = { ...demo[i++ % demo.length], id: 'n' + Date.now() }; m.idGiven = false; show(m); }, 1700);
}
