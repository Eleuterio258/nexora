const fs = require('fs');
const path = require('path');

const baseDir = __dirname;
const sourcePath = path.join(baseDir, 'titulos-playlist-curso-ingles.md');
const outDir = path.join(baseDir, 'curso-ingles-cartazes');
fs.mkdirSync(outDir, { recursive: true });

const markdown = fs.readFileSync(sourcePath, 'utf8');
const lessons = [...markdown.matchAll(/^\s*(\d+)\.\s+Curso de inglês passo a passo - Aula \d+ - (.+)$/gmi)]
  .map((m) => ({ number: Number(m[1]), topic: m[2].trim() }));

if (lessons.length !== 200) {
  throw new Error(`Esperadas 200 aulas, encontradas ${lessons.length}.`);
}

const iconRules = [
  [/shapes/i,'🔷'], [/christmas/i,'🎄'], [/parts of the car/i,'🚗'],
  [/review/i,'🔁'], [/food|comida|breakfast|lunch|dinner|cooking|diet/i,'🍽️'], [/drink|bebida|water/i,'🥤'],
  [/family|people|babies|relationship|wedding/i,'👨‍👩‍👧‍👦'], [/school|university|courses|chemistry|lab|periodic/i,'🏫'],
  [/color|\barts?\b|paint/i,'🎨'], [/number|mathematics|measurement/i,'🔢'], [/instrument|music/i,'🎸'], [/sport|soccer|gym|exercis/i,'⚽'],
  [/toy|game|playground|amusement/i,'🧸'], [/house|bedroom|bathroom|living room|dining room|kitchen|backyard|laundry|hotel/i,'🏠'],
  [/pet|zoo|farm|insect|reptile|amphibian|bird|dinosaur|mammal|marine life/i,'🐾'], [/fruit|vegetable|candy/i,'🍎'],
  [/day|month|season|time|birthday|celebration|christmas|easter|halloween/i,'📅'], [/place|street|direction|landscape/i,'📍'],
  [/movie|circus/i,'🎬'], [/bank|work|profession|form/i,'💼'], [/airport|transport|car|ship/i,'✈️'], [/feeling|greeting/i,'💬'],
  [/alphabet|grammar|adjective|punctuation|present perfect/i,'🔤'], [/clothes|accessor|jewelry|cosmetic|hairdresser/i,'👕'],
  [/computer|internet|electronic/i,'💻'], [/space|planet|moon|zodiac/i,'🚀'], [/beach|camping|weather/i,'🌦️'],
  [/countr|nationalit|continent|language/i,'🌍'], [/election|court|prison|cop|robber/i,'⚖️'], [/flower|plant|tree|garden/i,'🌿'],
  [/body|sense|dentist|hospital|hygiene|pandemic/i,'🩺'], [/tool|construction/i,'🛠️'], [/religion/i,'🕊️'],
  [/precious|metal/i,'💎'], [/biome|recycling|natural disaster/i,'♻️'], [/king|queen|castle|knight/i,'👑'],
  [/army|military|war|fire department/i,'🛡️'], [/clean|housework|supplies/i,'🧹']
];

function iconFor(topic) {
  const found = iconRules.find(([pattern]) => pattern.test(topic));
  return found ? found[1] : '📘';
}

function escapeHtml(text) {
  return text.replace(/[&<>"']/g, (char) => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]));
}

function posterHtml(group, index) {
  const first = group[0].number;
  const last = group[group.length - 1].number;
  const range = `AULAS ${first}–${last}`;
  const compact = group.length < 6;
  const cards = group.map((lesson, i) => `
    <article class="card" style="--accent:${['#149b9e','#ef625b','#f2aa13','#419ee0','#8c7bd8','#52b89f'][i % 6]}">
      <div class="number">${String(lesson.number).padStart(3,'0')}</div>
      <div class="lesson">AULA ${lesson.number}</div>
      <div class="icon">${iconFor(lesson.topic)}</div>
      <div class="topic">${escapeHtml(lesson.topic)}</div>
      <div class="step">CURSO DE INGLÊS <span>→</span></div>
    </article>`).join('');

  return `<!doctype html>
<html lang="pt"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Curso de Inglês — ${range}</title>
<style>
*{box-sizing:border-box}html,body{margin:0;width:3840px;height:2160px;overflow:hidden}body{font-family:"Segoe UI",Arial,sans-serif;background:#fbfaf6;color:#10234f}.poster{width:3840px;height:2160px;padding:64px 92px 52px;display:grid;grid-template-rows:250px 1fr 156px;gap:28px;background:radial-gradient(circle at 2% 4%,rgba(20,155,158,.11) 0 8px,transparent 9px),radial-gradient(circle at 98% 5%,rgba(242,170,19,.12) 0 9px,transparent 10px),#fbfaf6}header{display:flex;flex-direction:column;align-items:center;justify-content:center;position:relative}.eyebrow{color:#10878f;font-size:32px;font-weight:850;letter-spacing:6px;margin-bottom:13px;display:flex;align-items:center;gap:18px}.mini-flag{width:58px;height:36px;border-radius:4px;box-shadow:0 0 0 2px rgba(11,35,83,.08)}h1{margin:0;color:#0b2353;font-size:88px;line-height:1;letter-spacing:2px;font-weight:950}h1 .accent{background:linear-gradient(90deg,#149b9e,#ef625b,#f2aa13,#419ee0,#8c7bd8);-webkit-background-clip:text;color:transparent}.subtitle{margin:18px 0 0;color:#58667d;font-size:30px;font-weight:750;letter-spacing:1px}header:after{content:"";position:absolute;left:0;right:0;bottom:0;height:4px;border-radius:9px;background:linear-gradient(90deg,#149b9e,#419ee0,#8c7bd8,#ef625b,#f2aa13,#149b9e)}.grid{display:grid;grid-template-columns:repeat(${compact ? 2 : 6},1fr);grid-template-rows:repeat(${compact ? 1 : 3},1fr);gap:24px;min-height:0;${compact ? 'max-width:2100px;width:100%;justify-self:center;align-self:center;height:900px' : ''}}.card{--accent:#149b9e;background:#fff;border:3px solid color-mix(in srgb,var(--accent) 55%,white);border-radius:29px;padding:27px 29px 25px;position:relative;overflow:hidden;display:grid;grid-template-columns:120px 1fr 125px;grid-template-rows:102px 1fr 62px;gap:14px 18px;box-shadow:0 7px 0 rgba(16,35,79,.025)}.card:before{content:"";position:absolute;left:0;top:0;bottom:0;width:11px;background:var(--accent)}.number{min-width:112px;height:102px;border-radius:22px;display:grid;place-items:center;background:var(--accent);color:#fff;font-size:43px;font-weight:950;letter-spacing:-2px}.lesson{align-self:center;color:#6b768a;font-size:23px;font-weight:850;letter-spacing:2px}.icon{grid-column:3;grid-row:1/3;align-self:center;justify-self:center;font-family:"Segoe UI Emoji","Apple Color Emoji",sans-serif;font-size:${compact ? 132 : 88}px;line-height:1;filter:drop-shadow(0 3px 0 rgba(16,35,79,.10))}.topic{grid-column:1/3;grid-row:2;align-self:center;padding:28px 10px 24px 2px;border-top:1px solid #e1e6ea;color:#11244d;font-size:${compact ? 58 : 36}px;line-height:1.12;font-weight:900}.step{grid-column:1/4;grid-row:3;display:flex;align-items:center;gap:16px;color:var(--accent);font-size:20px;font-weight:850;letter-spacing:1.5px}.step:after{content:"";flex:1;height:3px;border-radius:3px;background:color-mix(in srgb,var(--accent) 34%,white)}.step span{font-size:29px}footer{border:2px solid #d8e2e5;border-radius:28px;background:#fff;display:grid;grid-template-columns:1.1fr 2.4fr 1.1fr;align-items:center;padding:20px 40px;position:relative;overflow:hidden}footer:before{content:"";position:absolute;left:0;top:0;bottom:0;width:12px;background:#149b9e}.footer-side{color:#647189;font-size:24px;font-weight:750}.footer-side:last-child{text-align:right}.motivation{justify-self:center;color:#fff;background:#0b2353;border-radius:999px;padding:20px 62px;font-size:38px;line-height:1;font-weight:950;letter-spacing:2px}
</style></head><body><main class="poster"><header><div class="eyebrow">
<svg class="mini-flag" viewBox="0 0 60 36" aria-label="Bandeira do Reino Unido"><clipPath id="uk-${index}"><rect width="60" height="36" rx="3"/></clipPath><g clip-path="url(#uk-${index})"><rect width="60" height="36" fill="#012169"/><path d="M0 0L60 36M60 0L0 36" stroke="#fff" stroke-width="8"/><path d="M0 0L60 36M60 0L0 36" stroke="#C8102E" stroke-width="4"/><path d="M30 0V36M0 18H60" stroke="#fff" stroke-width="12"/><path d="M30 0V36M0 18H60" stroke="#C8102E" stroke-width="7"/></g></svg>
<span>APRENDA PASSO A PASSO</span><span>📖</span></div><h1>CURSO DE <span class="accent">INGLÊS</span> PASSO A PASSO</h1><p class="subtitle">${range} · CARTAZ ${String(index).padStart(2,'0')} DE 12</p></header>
<section class="grid">${cards}</section><footer><div class="footer-side">🚀 CONTINUE A APRENDER</div><div class="motivation">LET’S LEARN ENGLISH!</div><div class="footer-side">200 AULAS · CURSO COMPLETO 🏆</div></footer></main></body></html>`;
}

const manifest = [];
for (let start = 0, index = 1; start < lessons.length; start += 18, index += 1) {
  const group = lessons.slice(start, start + 18);
  const baseName = `curso_ingles_cartaz_${String(index).padStart(2,'0')}_aulas_${String(group[0].number).padStart(3,'0')}-${String(group[group.length - 1].number).padStart(3,'0')}`;
  const htmlPath = path.join(outDir, `${baseName}.html`);
  fs.writeFileSync(htmlPath, posterHtml(group, index), 'utf8');
  manifest.push({ index, first: group[0].number, last: group[group.length - 1].number, count: group.length, html: htmlPath, png: path.join(outDir, `${baseName}_4k.png`) });
}

fs.writeFileSync(path.join(outDir, 'manifest.json'), JSON.stringify(manifest, null, 2), 'utf8');
console.log(JSON.stringify({ lessons: lessons.length, posters: manifest.length, outDir, manifest }, null, 2));
