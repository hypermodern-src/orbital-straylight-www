#!/usr/bin/env node

/**
 * PONCE International Speedway — Static Site Generator
 * Bilingual (EN/ES). Zero dependencies. `node build.js` → dist/
 */

import * as fs from 'fs';
import * as path from 'path';

const DIST = './dist';

// ---------------------------------------------------------------------------
// Track geometry — same control polygon as the WebGL hero (static/hero-gl.js)
// ---------------------------------------------------------------------------

// Centerline waypoints digitized from the official circuit map (1939x1080 px,
// clockwise from the start/finish line). Shared verbatim with static/hero-gl.js.
const RAW = [
  [1030, 905], [1300, 905], [1560, 905], [1820, 900], [1885, 893],
  [1908, 860], // T1
  [1885, 828], [1820, 822], [1500, 800], [1150, 763],
  [1010, 690], // T2
  [962, 580],
  [985, 480],  // T3
  [940, 465],
  [885, 430],  // T4
  [830, 485], [760, 565], [700, 650], [672, 700],
  [618, 745],  // T5
  [645, 668], [720, 530], [800, 380], [848, 285],
  [845, 225],  // T6
  [700, 190], [450, 132],
  [270, 90],   // T7
  [235, 130], [235, 320], [222, 520],
  [200, 700],  // T8
  [150, 880], [110, 955],
  [70, 995],   // T9
  [88, 1022], [160, 1010], [300, 970], [480, 938],
  [595, 930],  // T10
  [645, 952],
  [700, 985],  // T11
  [758, 933],
];
const MAP_SCALE = 2.9 / 1939; // uniform, aspect-preserving
const ctrl = RAW.map(([x, y]) => [x * MAP_SCALE - 1.45, y * MAP_SCALE - (1080 * MAP_SCALE) / 2]);

function catmull(p0, p1, p2, p3, t) {
  const t2 = t * t, t3 = t2 * t;
  return [
    0.5 * (2 * p1[0] + (p2[0] - p0[0]) * t + (2 * p0[0] - 5 * p1[0] + 4 * p2[0] - p3[0]) * t2 + (3 * p1[0] - p0[0] - 3 * p2[0] + p3[0]) * t3),
    0.5 * (2 * p1[1] + (p2[1] - p0[1]) * t + (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * t2 + (3 * p1[1] - p0[1] - 3 * p2[1] + p3[1]) * t3),
  ];
}

function samplePath(t) {
  const n = ctrl.length;
  t = ((t % 1) + 1) % 1;
  const f = t * n;
  const i = Math.floor(f);
  const u = f - i;
  return catmull(ctrl[(i - 1 + n) % n], ctrl[i % n], ctrl[(i + 1) % n], ctrl[(i + 2) % n], u);
}

// Turn markers: the 11 numbered corners, in lap order from start/finish.
const turnCtrlIndices = [5, 10, 12, 14, 19, 24, 27, 31, 34, 39, 41];

function trackSvg(lang) {
  const W = 640, H = 420, PAD = 46;
  const px = ([x, y]) => [
    ((x + 1.45) / 2.9) * (W - 2 * PAD) + PAD,
    ((y + 0.81) / 1.62) * (H - 2 * PAD) + PAD,
  ];
  const S = 192;
  let d = '';
  for (let i = 0; i <= S; i++) {
    const [x, y] = px(samplePath(i / S));
    d += (i === 0 ? 'M' : 'L') + x.toFixed(1) + ' ' + y.toFixed(1);
  }
  d += 'Z';
  const labels = turnCtrlIndices.map((ci, k) => {
    const [x, y] = px(ctrl[ci]);
    // nudge label outward from centroid
    const [cx, cy] = px([0, 0]);
    const dx = x - cx, dy = y - cy;
    const len = Math.hypot(dx, dy) || 1;
    const lx = x + (dx / len) * 20, ly = y + (dy / len) * 20;
    return `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="4" class="turn-dot"/>
      <text x="${lx.toFixed(1)}" y="${(ly + 4).toFixed(1)}" class="turn-label">${k + 1}</text>`;
  }).join('\n      ');
  const [sx, sy] = px(samplePath(0));
  const sf = lang === 'en' ? 'START / FINISH' : 'META';
  return `
      <figure class="trackmap">
        <svg viewBox="0 0 ${W} ${H}" role="img" aria-label="${lang === 'en' ? 'Circuit map' : 'Mapa del circuito'}">
          <path d="${d}" class="track-outline"/>
          <path d="${d}" class="track-line"/>
          ${labels}
          <rect x="${(sx - 5).toFixed(1)}" y="${(sy - 10).toFixed(1)}" width="10" height="20" class="startfinish"/>
          <text x="${(sx + 14).toFixed(1)}" y="${(sy + 4).toFixed(1)}" class="sf-label">${sf}</text>
        </svg>
        <figcaption>${lang === 'en'
          ? '1.54 mi (2.47 km) · 11 turns · run clockwise along the southern coast'
          : '1.54 mi (2.47 km) · 11 curvas · en sentido horario por la costa sur'}</figcaption>
      </figure>`;
}

// ---------------------------------------------------------------------------
// Content
// ---------------------------------------------------------------------------

const site = {
  name: 'PONCE International Speedway',
  tagline: {
    en: 'The Roar Returns',
    es: 'El Rugido Regresa',
  },
  description: {
    en: 'The longest road course in the Caribbean — 1.54 miles, 11 turns, on the southern coast of Puerto Rico. Reopening 2026.',
    es: 'El circuito más largo del Caribe — 1.54 millas, 11 curvas, en la costa sur de Puerto Rico. Reapertura 2026.',
  },
};

const nav = [
  { slug: { en: 'circuit', es: 'es/circuito' }, label: { en: 'The Circuit', es: 'El Circuito' } },
  { slug: { en: 'events', es: 'es/eventos' }, label: { en: 'Racing Events', es: 'Eventos' } },
  { slug: { en: 'karting', es: 'es/karting' }, label: { en: 'Karting', es: 'Karting' } },
  { slug: { en: 'suites', es: 'es/suites' }, label: { en: 'Auto Suites', es: 'Auto Suites' } },
  { slug: { en: 'sponsors', es: 'es/patrocinadores' }, label: { en: 'Sponsors', es: 'Patrocinadores' } },
  { slug: { en: 'fanclub', es: 'es/fanaticos' }, label: { en: 'Fan Club', es: 'Fanáticos' } },
];

const footer = {
  blurb: {
    en: 'An automotive resort on the southern coast of Puerto Rico — high-speed racing, karting, private auto suites, and the Caribbean Sea past the last curbstone.',
    es: 'Un resort automotriz en la costa sur de Puerto Rico — carreras de alta velocidad, karting, auto suites privadas, y el Mar Caribe detrás de la última curva.',
  },
  poweredBy: [
    { name: 'Sector Sixty6', line: '18400 State Road #3, Canóvanas, Puerto Rico 00729 · (787) 370-6350' },
    { name: 'Misla Hospitality Group', line: 'P.O. Box 331431, Ponce, Puerto Rico 00733 · (787) 376-3256 · mislahospitalitygroup.com' },
  ],
};

const stats = [
  { value: '1.54 mi', label: { en: 'road course — longest in the Caribbean', es: 'circuito — el más largo del Caribe' } },
  { value: '11', label: { en: 'turns, from seaside sweepers to hairpins', es: 'curvas, desde costeras rápidas hasta horquillas' } },
  { value: '2026', label: { en: 'the track reopens — construction began August 2025', es: 'reapertura — la construcción comenzó en agosto 2025' } },
];

// The 11 turns. Names honor Ponce landmarks; descriptions are editorial.
const turns = [
  {
    name: 'La Guancha',
    desc: {
      en: 'Heavy braking off the start/finish straight into a second-gear right-hander — named for the boardwalk where Ponce meets the sea.',
      es: 'Frenada fuerte al final de la recta principal hacia una curva derecha de segunda marcha — nombrada por el paseo tablado donde Ponce encuentra el mar.',
    },
  },
  {
    name: 'El Vigía',
    desc: {
      en: 'A blind, climbing left over a crest. You commit before you can see the exit, like the watchtower hill it borrows its name from.',
      es: 'Una izquierda ciega en subida sobre una cresta. Te comprometes antes de ver la salida, como el cerro del vigía que le presta el nombre.',
    },
  },
  {
    name: 'Serrallés',
    desc: {
      en: 'A long, stately right-hand sweeper that rewards patience and a clean line — carry speed here and the next two corners open up.',
      es: 'Una derecha larga y señorial que premia la paciencia y la línea limpia — lleva velocidad aquí y las próximas dos curvas se abren.',
    },
  },
  {
    name: 'La Cruceta',
    desc: {
      en: 'A quick left-right transition where the circuit changes rhythm. Kerbs are your friend; too much ambition is not.',
      es: 'Una transición rápida izquierda-derecha donde el circuito cambia de ritmo. Los pianos son tus amigos; el exceso de ambición no.',
    },
  },
  {
    name: 'Caja de Muertos',
    desc: {
      en: 'The fastest point on the lap, aimed straight at the offshore island on the horizon before a fourth-gear right.',
      es: 'El punto más rápido de la vuelta, apuntando directo a la isla en el horizonte antes de una derecha de cuarta marcha.',
    },
  },
  {
    name: 'El León',
    desc: {
      en: 'The signature corner — a double-apex right around the seaward point of the circuit, with nothing between you and the Caribbean but armco.',
      es: 'La curva insignia — una derecha de doble ápice en la punta marítima del circuito, con nada entre tú y el Caribe más que la barrera.',
    },
  },
  {
    name: 'Las Delicias',
    desc: {
      en: 'A tightening right that punishes early throttle. Sacrifice the entry, and the plaza-named corner pays you back down the next straight.',
      es: 'Una derecha que se cierra y castiga el acelerador temprano. Sacrifica la entrada, y la curva de la plaza te lo devuelve en la próxima recta.',
    },
  },
  {
    name: 'Parque de Bombas',
    desc: {
      en: 'A hard second-gear left, painted in the red and black of the firehouse it salutes. The best overtaking spot on the circuit.',
      es: 'Una izquierda fuerte de segunda marcha, pintada en el rojo y negro del parque de bombas que saluda. El mejor punto de adelantamiento del circuito.',
    },
  },
  {
    name: 'La Ceiba',
    desc: {
      en: 'A wide, rooted right-hander — multiple lines through, none of them free. Where race craft shows.',
      es: 'Una derecha amplia y arraigada — varias líneas posibles, ninguna gratis. Donde se nota el oficio.',
    },
  },
  {
    name: 'Los Meros',
    desc: {
      en: 'The penultimate test: a downhill left hairpin with the sea filling your windshield on entry.',
      es: 'La penúltima prueba: una horquilla izquierda en bajada con el mar llenando el parabrisas en la entrada.',
    },
  },
  {
    name: 'Fin del Silencio',
    desc: {
      en: 'The last corner earns its name — a rising right that fires you onto the main straight, where a decade of silence ends at full throttle.',
      es: 'La última curva se gana su nombre — una derecha en subida que te lanza a la recta principal, donde una década de silencio termina a todo motor.',
    },
  },
];

const pages = [
  // ------------------------------------------------------------------ home
  {
    slug: { en: '', es: 'es' },
    title: { en: 'Home', es: 'Inicio' },
    hero: { image: 'hero.jpg', gl: true, kicker: { en: 'Ponce · Puerto Rico', es: 'Ponce · Puerto Rico' } },
    heroHeadline: { en: 'The Roar Returns', es: 'El Rugido Regresa' },
    heroSub: {
      en: 'After more than a decade of silence, the legendary Ponce Speedway returns as the PONCE International Speedway Park — the longest road course in the Caribbean, reborn on the southern coast of Puerto Rico.',
      es: 'Después de más de una década de silencio, el legendario Ponce Speedway regresa como el PONCE International Speedway Park — el circuito más largo del Caribe, renacido en la costa sur de Puerto Rico.',
    },
    sections: [
      {
        heading: { en: 'A racing renaissance', es: 'Un renacimiento del automovilismo' },
        body: {
          en: `For generations of Puerto Rican racing fans, Ponce was where the island came to hear engines. Then the gates closed, and for more than a decade the longest road course in the Caribbean sat silent above the sea.

That silence is ending. Construction began in August 2025, and the track reopens in 2026 — not as a restoration, but as a reinvention: a motorsport park designed as the anchor of a world-class automotive resort destination in Ponce, where racing, karting, private auto suites, and hospitality share one venue built around a 1.54-mile seaside circuit.`,
          es: `Para generaciones de fanáticos puertorriqueños, Ponce era donde la isla venía a escuchar motores. Entonces los portones cerraron, y por más de una década el circuito más largo del Caribe quedó en silencio sobre el mar.

Ese silencio está terminando. La construcción comenzó en agosto de 2025, y la pista reabre en 2026 — no como una restauración, sino como una reinvención: un parque de automovilismo diseñado como el ancla de un destino turístico automotriz de clase mundial en Ponce, donde las carreras, el karting, las auto suites privadas y la hospitalidad comparten un solo recinto construido alrededor de un circuito costero de 1.54 millas.`,
        },
      },
      {
        heading: { en: 'The road back', es: 'El camino de regreso' },
        timeline: [
          {
            when: { en: 'The 2010s', es: 'Los 2010s' },
            what: {
              en: 'The original Ponce Speedway falls silent. The Caribbean loses its longest road course; a generation of drivers loses its home track.',
              es: 'El Ponce Speedway original queda en silencio. El Caribe pierde su circuito más largo; una generación de pilotos pierde su pista.',
            },
          },
          {
            when: { en: 'August 2025', es: 'Agosto 2025' },
            what: {
              en: 'Construction begins on the PONCE International Speedway Park — new asphalt, new facilities, a new master plan.',
              es: 'Comienza la construcción del PONCE International Speedway Park — nuevo asfalto, nuevas instalaciones, un nuevo plan maestro.',
            },
          },
          {
            when: { en: '2026', es: '2026' },
            what: {
              en: 'The circuit reopens: 1.54 miles, 11 turns, the sea past the last curbstone. Racing returns to the southern coast.',
              es: 'El circuito reabre: 1.54 millas, 11 curvas, el mar detrás de la última curva. Las carreras regresan a la costa sur.',
            },
          },
          {
            when: { en: 'Beyond', es: 'Después' },
            what: {
              en: 'The resort build-out continues — karting club, auto suites, hospitality, and the events calendar that ties it all together.',
              es: 'El desarrollo del resort continúa — club de karting, auto suites, hospitalidad, y el calendario de eventos que lo une todo.',
            },
          },
        ],
      },
      {
        heading: { en: 'Where speed meets the sea', es: 'Donde la velocidad encuentra el mar' },
        image: 'circuit.jpg',
        body: {
          en: `Eleven turns run through tropical green against panoramic ocean views — palm-fringed straightaways, seaside vistas, and the longest lap in the Caribbean. Drivers get a technical, demanding road course; everyone else gets the best view in motorsport.`,
          es: `Once curvas atraviesan el verde tropical con vistas panorámicas al océano — rectas bordeadas de palmas, vistas al mar, y la vuelta más larga del Caribe. Los pilotos reciben un circuito técnico y exigente; todos los demás, la mejor vista del automovilismo.`,
        },
        cta: { label: { en: 'Explore the circuit', es: 'Explora el circuito' }, slug: { en: 'circuit', es: 'es/circuito' } },
      },
      {
        quote: {
          en: 'At Ponce, racing isn’t just a sport — it’s a lifestyle driven by the thrill of the track and the freedom of the open road.',
          es: 'En Ponce, las carreras no son solo un deporte — son un estilo de vida impulsado por la emoción de la pista y la libertad del camino abierto.',
        },
      },
      {
        heading: { en: 'The master plan', es: 'El plan maestro' },
        body: {
          en: 'The speedway is the first movement of a larger score: an automotive resort where every part of the property answers to the track.',
          es: 'El autódromo es el primer movimiento de una partitura mayor: un resort automotriz donde cada parte de la propiedad responde a la pista.',
        },
        cards: [
          {
            title: { en: 'Racing Events', es: 'Eventos' },
            text: {
              en: 'Circuit races, drag competitions, karting challenges, and motorcycle championships — attend, or host your own.',
              es: 'Carreras de circuito, arrancones, retos de karting y campeonatos de motociclismo — asiste, u organiza el tuyo.',
            },
            slug: { en: 'events', es: 'es/eventos' },
          },
          {
            title: { en: 'Karting Club', es: 'Club de Karting' },
            text: {
              en: 'Professional-grade karts on a dedicated circuit, for first-timers through seasoned racers.',
              es: 'Karts de nivel profesional en un circuito dedicado, desde principiantes hasta pilotos experimentados.',
            },
            slug: { en: 'karting', es: 'es/karting' },
          },
          {
            title: { en: 'Auto Suites', es: 'Auto Suites' },
            text: {
              en: 'Private trackside garages with 20-year leases — your cars, inside the speedway.',
              es: 'Garajes privados junto a la pista con arrendamientos de 20 años — tus autos, dentro del autódromo.',
            },
            slug: { en: 'suites', es: 'es/suites' },
          },
          {
            title: { en: 'Sponsorship', es: 'Patrocinio' },
            text: {
              en: 'Put your brand on the fastest real estate in the Caribbean — from naming rights to paddock activations.',
              es: 'Pon tu marca en el terreno más rápido del Caribe — desde derechos de nombre hasta activaciones en el paddock.',
            },
            slug: { en: 'sponsors', es: 'es/patrocinadores' },
          },
        ],
      },
    ],
  },
  // --------------------------------------------------------------- circuit
  {
    slug: { en: 'circuit', es: 'es/circuito' },
    title: { en: 'The Circuit', es: 'El Circuito' },
    hero: { image: 'circuit.jpg', kicker: { en: 'The Circuit', es: 'El Circuito' } },
    heroHeadline: { en: 'Where Speed Meets the Sea', es: 'Donde la Velocidad Encuentra el Mar' },
    heroSub: {
      en: 'A 1.54-mile (2.47 km) road course with 11 turns, set against the Caribbean Sea on the southern coast of Puerto Rico.',
      es: 'Un circuito de 1.54 millas (2.47 km) con 11 curvas, frente al Mar Caribe en la costa sur de Puerto Rico.',
    },
    sections: [
      {
        heading: { en: 'The longest lap in the Caribbean', es: 'La vuelta más larga del Caribe' },
        body: {
          en: `The road course is designed to challenge experienced drivers: eleven turns that test both speed and precision, from fast seaside sections to tight technical corners. Elevation, camber, and the coastline itself do the rest — the tropical breeze crosses the racing line, and every corner opens onto the sea.

Racing or watching from the stands, there is no other venue like it in the region.`,
          es: `El circuito está diseñado para desafiar a pilotos experimentados: once curvas que ponen a prueba velocidad y precisión, desde secciones costeras rápidas hasta esquinas técnicas cerradas. La elevación, el peralte y la propia costa hacen el resto — la brisa tropical cruza la línea de carrera, y cada curva se abre al mar.

Corriendo o mirando desde las gradas, no hay otro recinto igual en la región.`,
        },
        map: true,
      },
      {
        heading: { en: 'Track facts', es: 'Datos de la pista' },
        specs: [
          { k: { en: 'Length', es: 'Longitud' }, v: '1.54 mi / 2.47 km' },
          { k: { en: 'Turns', es: 'Curvas' }, v: '11' },
          { k: { en: 'Setting', es: 'Entorno' }, v: { en: 'Seaside — southern coast of Puerto Rico', es: 'Costero — costa sur de Puerto Rico' } },
          { k: { en: 'Distinction', es: 'Distinción' }, v: { en: 'Longest road course in the Caribbean', es: 'El circuito más largo del Caribe' } },
          { k: { en: 'Reopening', es: 'Reapertura' }, v: { en: '2026 (construction began August 2025)', es: '2026 (construcción desde agosto 2025)' } },
        ],
      },
      {
        heading: { en: 'Eleven turns, turn by turn', es: 'Once curvas, una por una' },
        body: {
          en: 'Each corner carries the name of a piece of Ponce. Learn them here; earn them on track.',
          es: 'Cada curva lleva el nombre de un pedazo de Ponce. Apréndelas aquí; gánatelas en la pista.',
        },
        turns: true,
      },
      {
        quote: {
          en: 'Feel the adrenaline course through your veins as you navigate the twists and turns of our world-class circuit, surrounded by the stunning beauty of the Caribbean Sea.',
          es: 'Siente la adrenalina correr por tus venas mientras navegas las curvas de nuestro circuito de clase mundial, rodeado de la impresionante belleza del Mar Caribe.',
        },
      },
    ],
  },
  // ---------------------------------------------------------------- events
  {
    slug: { en: 'events', es: 'es/eventos' },
    title: { en: 'Racing Events', es: 'Eventos' },
    hero: { image: 'events.jpg', kicker: { en: 'Racing Events', es: 'Eventos' } },
    heroHeadline: { en: 'Attend — or Host Your Own', es: 'Asiste — u Organiza el Tuyo' },
    heroSub: {
      en: 'Circuit races, drag competitions, karting challenges, and motorcycle championships, with the electric atmosphere of live racing.',
      es: 'Carreras de circuito, competencias de arrancones, retos de karting y campeonatos de motociclismo, con la atmósfera eléctrica de las carreras en vivo.',
    },
    sections: [
      {
        heading: { en: 'What runs here', es: 'Qué corre aquí' },
        cards: [
          {
            title: { en: 'Circuit Racing', es: 'Carreras de Circuito' },
            text: {
              en: 'Wheel-to-wheel racing on the full 1.54-mile course, featuring top local and international drivers.',
              es: 'Carreras rueda a rueda en el circuito completo de 1.54 millas, con los mejores pilotos locales e internacionales.',
            },
          },
          {
            title: { en: 'Motorcycle Championships', es: 'Campeonatos de Motociclismo' },
            text: {
              en: 'Two wheels, eleven turns, and the bravest cornering on the island.',
              es: 'Dos ruedas, once curvas, y el paso por curva más valiente de la isla.',
            },
          },
          {
            title: { en: 'Drag Competitions', es: 'Arrancones' },
            text: {
              en: 'Straight-line power for the launch-control faithful — pure acceleration, measured honestly.',
              es: 'Potencia en línea recta para los fieles del arranque — aceleración pura, medida honestamente.',
            },
          },
          {
            title: { en: 'Karting Challenges', es: 'Retos de Karting' },
            text: {
              en: 'Tournaments and themed race days on the karting circuit — the sharpest racing per dollar there is.',
              es: 'Torneos y días temáticos en el circuito de karting — las carreras más intensas por dólar que existen.',
            },
          },
        ],
      },
      {
        heading: { en: 'A race day at Ponce', es: 'Un día de carreras en Ponce' },
        list: {
          en: [
            'Grandstand and trackside viewing with the Caribbean behind every corner',
            'Premium seating and VIP access with pit and paddock views',
            'Family zones and interactive fan experiences between sessions',
            'Food, music, and the island — race day here is a full day out',
          ],
          es: [
            'Gradas y vistas junto a la pista con el Caribe detrás de cada curva',
            'Asientos premium y acceso VIP con vista a los pits y el paddock',
            'Zonas familiares y experiencias interactivas entre sesiones',
            'Comida, música y la isla — un día de carreras aquí es un día completo',
          ],
        },
      },
      {
        heading: { en: 'Host your own event', es: 'Organiza tu propio evento' },
        body: {
          en: `The speedway is available for corporate events, private races, club track days, and special competitions. You bring the occasion; we bring a 1.54-mile road course, pit facilities, hospitality spaces, and a team that has run race weekends before.

Tell us the date and the ambition, and we'll build the event around it.`,
          es: `El autódromo está disponible para eventos corporativos, carreras privadas, track days de clubes y competencias especiales. Tú traes la ocasión; nosotros un circuito de 1.54 millas, instalaciones de pits, espacios de hospitalidad y un equipo que ya ha corrido fines de semana de carrera.

Dinos la fecha y la ambición, y construiremos el evento alrededor.`,
        },
      },
      {
        heading: { en: 'Common questions', es: 'Preguntas comunes' },
        faq: [
          {
            q: { en: 'Can I drive my own car on the circuit?', es: '¿Puedo conducir mi propio auto en el circuito?' },
            a: {
              en: 'Yes — through organized track days and private events. Helmets and a passed tech inspection are required; instructors are available for first-timers.',
              es: 'Sí — a través de track days organizados y eventos privados. Se requiere casco e inspección técnica aprobada; hay instructores disponibles para principiantes.',
            },
          },
          {
            q: { en: 'When will the event calendar be published?', es: '¿Cuándo se publicará el calendario de eventos?' },
            a: {
              en: 'As the 2026 reopening approaches. Fan Club members hear first — announcements, early tickets, all of it.',
              es: 'A medida que se acerque la reapertura de 2026. Los miembros del Club de Fanáticos se enteran primero — anuncios, boletos anticipados, todo.',
            },
          },
          {
            q: { en: 'Can companies book the whole venue?', es: '¿Pueden las empresas reservar todo el recinto?' },
            a: {
              en: 'Yes. Full-venue corporate bookings include the circuit, pit garages, and hospitality areas, with catering and event staff.',
              es: 'Sí. Las reservas corporativas del recinto completo incluyen el circuito, los garajes de pits y las áreas de hospitalidad, con catering y personal del evento.',
            },
          },
        ],
      },
    ],
  },
  // --------------------------------------------------------------- karting
  {
    slug: { en: 'karting', es: 'es/karting' },
    title: { en: 'Karting Club', es: 'Club de Karting' },
    hero: { image: 'karting.jpg', kicker: { en: 'Karting Club', es: 'Club de Karting' } },
    heroHeadline: { en: 'Karting Adventures Begin Here', es: 'Las Aventuras de Karting Empiezan Aquí' },
    heroSub: {
      en: 'A dedicated karting circuit inside the speedway — for all ages and every skill level, from first laps to head-to-head competition.',
      es: 'Un circuito de karting dedicado dentro del autódromo — para todas las edades y niveles, desde las primeras vueltas hasta la competencia directa.',
    },
    sections: [
      {
        heading: { en: 'Ways to drive', es: 'Formas de correr' },
        cards: [
          {
            title: { en: 'Arrive & Drive', es: 'Llega y Corre' },
            text: {
              en: 'Walk in, gear up, drive. Timed sessions on professional-grade karts with a full safety briefing — no experience needed.',
              es: 'Llega, equípate, corre. Sesiones cronometradas en karts profesionales con charla de seguridad completa — sin experiencia previa.',
            },
          },
          {
            title: { en: 'Junior Program', es: 'Programa Juvenil' },
            text: {
              en: 'Kids sessions with right-sized karts, patient instructors, and the fundamentals taught properly from lap one.',
              es: 'Sesiones para niños con karts a su medida, instructores pacientes, y los fundamentos enseñados bien desde la primera vuelta.',
            },
          },
          {
            title: { en: 'Corporate Grand Prix', es: 'Gran Premio Corporativo' },
            text: {
              en: 'Team-building with a podium. Qualifying, heats, and a final — plus catering and exclusive track time for your group.',
              es: 'Team-building con podio. Clasificación, mangas y una final — más catering y tiempo exclusivo en pista para tu grupo.',
            },
          },
          {
            title: { en: 'League Nights', es: 'Noches de Liga' },
            text: {
              en: 'A recurring championship for regulars: consistent rules, running points, and bragging rights that carry all season.',
              es: 'Un campeonato recurrente para los habituales: reglas consistentes, puntos acumulados, y derecho a presumir toda la temporada.',
            },
          },
        ],
      },
      {
        heading: { en: 'What to expect', es: 'Qué esperar' },
        list: {
          en: [
            'Professional-grade karts — responsive handling, real speed',
            'A technical circuit of twists, turns, and straights that mirrors the big track',
            'Full safety briefing, helmets, and gear included in every session',
            'Electronic lap timing on every session — race your friends for the fastest lap',
            'Karting tournaments and themed race days with prizes',
          ],
          es: [
            'Karts de nivel profesional — manejo preciso, velocidad real',
            'Un circuito técnico de curvas y rectas que refleja la pista grande',
            'Charla de seguridad, cascos y equipo incluidos en cada sesión',
            'Cronometraje electrónico en cada sesión — compite con tus amigos por la vuelta más rápida',
            'Torneos de karting y días temáticos con premios',
          ],
        },
      },
      {
        heading: { en: 'From karts to the big track', es: 'Del karting a la pista grande' },
        body: {
          en: `Every professional driver started in a kart. The Karting Club is built to be a real ladder: learn the racing line and braking points on the karting circuit with instructors who race, then graduate to track days on the full 1.54-mile course when you're ready.

Group packages cover birthday parties, team-building, and race days with friends — exclusive track time, catering options, and instructors on hand.`,
          es: `Todo piloto profesional empezó en un kart. El Club de Karting está construido como una escalera real: aprende la línea de carrera y los puntos de frenado en el circuito de karting con instructores que corren, y gradúate a track days en el circuito completo de 1.54 millas cuando estés listo.

Los paquetes de grupo cubren cumpleaños, actividades de equipo y días de carrera con amigos — tiempo exclusivo en pista, opciones de catering e instructores disponibles.`,
        },
      },
      {
        quote: {
          en: 'Race like a pro — every lap brings excitement, and every corner teaches you something the last one didn’t.',
          es: 'Corre como un profesional — cada vuelta trae emoción, y cada curva te enseña algo que la anterior no.',
        },
      },
    ],
  },
  // ---------------------------------------------------------------- suites
  {
    slug: { en: 'suites', es: 'es/suites' },
    title: { en: 'Auto Suites', es: 'Auto Suites' },
    hero: { image: 'suites.jpg', kicker: { en: 'Auto Suites', es: 'Auto Suites' } },
    heroHeadline: { en: 'Your Space at the Track. Not Near It — Inside It.', es: 'Tu Espacio en la Pista. No Cerca — Adentro.' },
    heroSub: {
      en: 'A limited collection of private trackside garages, built for people whose cars deserve an address at the speedway.',
      es: 'Una colección limitada de garajes privados junto a la pista, para quienes sus autos merecen una dirección en el autódromo.',
    },
    sections: [
      {
        heading: { en: 'The idea', es: 'La idea' },
        body: {
          en: `Most collectors keep their cars far from where they get driven. An Auto Suite closes that distance to zero: a private garage inside the speedway, with the circuit outside your door and a community of people who care about the same things you do.

Store the collection, watch the races from your own suite, roll onto the track on member days — and between all of it, have a place at the speedway that is genuinely yours.`,
          es: `La mayoría de los coleccionistas guardan sus autos lejos de donde los conducen. Una Auto Suite reduce esa distancia a cero: un garaje privado dentro del autódromo, con el circuito afuera de tu puerta y una comunidad de personas que valoran lo mismo que tú.

Guarda la colección, mira las carreras desde tu propia suite, entra a la pista en los días de miembros — y entre todo eso, ten un lugar en el autódromo que es genuinamente tuyo.`,
        },
      },
      {
        heading: { en: 'What a suite includes', es: 'Qué incluye una suite' },
        list: {
          en: [
            'Prime trackside location with a direct view of the racing line',
            'Private garage space for your own supercars or race vehicles',
            'Modern interiors — lounge area, mini bar, catering options',
            'VIP privileges: private events, pit tours, meet-and-greets with professional racers',
            'A community of owners who show up for race weekends, not just storage',
          ],
          es: [
            'Ubicación privilegiada junto a la pista con vista directa a la línea de carrera',
            'Garaje privado para tus superdeportivos o vehículos de carrera',
            'Interiores modernos — sala, mini bar, opciones de catering',
            'Privilegios VIP: eventos privados, tours de pits, encuentros con pilotos profesionales',
            'Una comunidad de dueños que llega para los fines de semana de carrera, no solo para almacenar',
          ],
        },
      },
      {
        heading: { en: 'How the lease program works', es: 'Cómo funciona el programa' },
        timeline: [
          {
            when: { en: '1 · Inquire', es: '1 · Consulta' },
            what: {
              en: 'Contact the Auto Suites team. Tell them what you drive, what you collect, and how you want to use the space.',
              es: 'Contacta al equipo de Auto Suites. Diles qué conduces, qué coleccionas, y cómo quieres usar el espacio.',
            },
          },
          {
            when: { en: '2 · Tour', es: '2 · Recorrido' },
            what: {
              en: 'Walk the suites and the trackside locations available, and see the circuit from where your garage would sit.',
              es: 'Recorre las suites y las ubicaciones disponibles junto a la pista, y mira el circuito desde donde estaría tu garaje.',
            },
          },
          {
            when: { en: '3 · Configure', es: '3 · Configura' },
            what: {
              en: 'Choose your unit and finish level. Accessible packages and financing options are available.',
              es: 'Elige tu unidad y nivel de terminación. Hay paquetes accesibles y opciones de financiamiento disponibles.',
            },
          },
          {
            when: { en: '4 · Sign', es: '4 · Firma' },
            what: {
              en: 'Long-term 20-year leases — stability, control, and a lasting presence inside Puerto Rico’s premier motorsports destination.',
              es: 'Arrendamientos a largo plazo de 20 años — estabilidad, control y una presencia duradera dentro del principal destino de automovilismo de Puerto Rico.',
            },
          },
        ],
      },
      {
        heading: { en: 'Availability', es: 'Disponibilidad' },
        body: {
          en: `The collection is deliberately limited, and units are optioned in order of inquiry. To option a unit or request the brochure:`,
          es: `La colección es deliberadamente limitada, y las unidades se reservan por orden de consulta. Para reservar una unidad o solicitar el folleto:`,
        },
        contact: { email: 'autosuites@poncespeedway.com', phone: '(939) 793-5632' },
      },
    ],
  },
  // -------------------------------------------------------------- sponsors
  {
    slug: { en: 'sponsors', es: 'es/patrocinadores' },
    title: { en: 'Become a Sponsor', es: 'Patrocinadores' },
    hero: { image: 'sponsors.jpg', kicker: { en: 'Sponsorship', es: 'Patrocinio' } },
    heroHeadline: { en: "Fuel Your Brand's Success", es: 'Impulsa el Éxito de tu Marca' },
    heroSub: {
      en: "Align your brand with the Caribbean's premier racing destination and an audience that shows up for speed.",
      es: 'Alinea tu marca con el principal destino de carreras del Caribe y una audiencia que llega por la velocidad.',
    },
    sections: [
      {
        heading: { en: 'Why sponsor', es: 'Por qué patrocinar' },
        body: {
          en: `Motorsport audiences are the kind marketers describe with envy: passionate, loyal, and physically present. A speedway sponsorship isn't an impression on a feed — it's your brand painted on the place where people spend an entire day feeling something.

And in Ponce, sponsorship carries a second meaning: you're helping bring world-class racing back to Puerto Rico, and fueling motorsport culture and tourism on the island.`,
          es: `Las audiencias del automovilismo son las que los mercadólogos describen con envidia: apasionadas, leales y físicamente presentes. Un patrocinio en el autódromo no es una impresión en un feed — es tu marca pintada en el lugar donde la gente pasa un día entero sintiendo algo.

Y en Ponce, el patrocinio tiene un segundo significado: estás ayudando a traer de vuelta las carreras de clase mundial a Puerto Rico, e impulsando la cultura del automovilismo y el turismo en la isla.`,
        },
      },
      {
        heading: { en: 'Partnership levels', es: 'Niveles de alianza' },
        cards: [
          {
            title: { en: 'Pole Position', es: 'Pole Position' },
            text: {
              en: 'Naming rights to races and series, from local tournaments to international events — your brand in the event name, on the podium, and across all media.',
              es: 'Derechos de nombre de carreras y series, desde torneos locales hasta eventos internacionales — tu marca en el nombre del evento, en el podio y en todos los medios.',
            },
          },
          {
            title: { en: 'Podium', es: 'Podio' },
            text: {
              en: 'Trackside advertising in prime positions, hospitality packages for your clients, and presence across the speedway’s digital channels.',
              es: 'Publicidad junto a la pista en posiciones privilegiadas, paquetes de hospitalidad para tus clientes, y presencia en los canales digitales del autódromo.',
            },
          },
          {
            title: { en: 'Paddock', es: 'Paddock' },
            text: {
              en: 'On-site activations, product demos, and fan-zone experiences — put your product in people’s hands on race day.',
              es: 'Activaciones en sitio, demos de producto y experiencias en la zona de fanáticos — pon tu producto en las manos de la gente el día de la carrera.',
            },
          },
        ],
      },
      {
        heading: { en: 'Where your brand lives', es: 'Dónde vive tu marca' },
        list: {
          en: [
            'Trackside billboards and banners in camera-facing positions',
            'Vehicles, uniforms, and race-day materials',
            'Auto Suites, VIP lounges, and hospitality spaces',
            'The speedway’s digital and social channels, growing toward the 2026 reopening',
            'Merchandise and co-branded fan experiences',
          ],
          es: [
            'Vallas y banners junto a la pista en posiciones de cámara',
            'Vehículos, uniformes y materiales del día de carrera',
            'Auto Suites, salones VIP y espacios de hospitalidad',
            'Los canales digitales y sociales del autódromo, creciendo hacia la reapertura de 2026',
            'Mercancía y experiencias de marca compartida para fanáticos',
          ],
        },
      },
      {
        heading: { en: 'Start the conversation', es: 'Empieza la conversación' },
        body: {
          en: 'Sponsorship packages are built per partner, not off a rate card. Contact us with your brand and your goals, and we’ll design the rest together.',
          es: 'Los paquetes de patrocinio se construyen por aliado, no de una tarifa fija. Contáctanos con tu marca y tus metas, y diseñamos el resto juntos.',
        },
      },
    ],
  },
  // --------------------------------------------------------------- fanclub
  {
    slug: { en: 'fanclub', es: 'es/fanaticos' },
    title: { en: 'Fan Club', es: 'Club de Fanáticos' },
    hero: { image: 'hero.jpg', kicker: { en: 'Fan Club', es: 'Club de Fanáticos' } },
    heroHeadline: { en: 'Be Part of the Action', es: 'Sé Parte de la Acción' },
    heroSub: {
      en: 'Race announcements, early ticket sales, VIP experiences, and behind-the-scenes updates — first, and free.',
      es: 'Anuncios de carreras, preventa de boletos, experiencias VIP y noticias detrás de cámaras — primero, y gratis.',
    },
    sections: [
      {
        heading: { en: 'What members get', es: 'Qué reciben los miembros' },
        list: {
          en: [
            'Race and event announcements before the general public',
            'Early access to tickets and member pricing on select events',
            'Behind-the-scenes updates from the rebuild as the 2026 reopening approaches',
            'Invitations to fan-only events, track walks, and open days',
            'A say in the small things — polls on liveries, merch, and event ideas',
          ],
          es: [
            'Anuncios de carreras y eventos antes que el público general',
            'Acceso anticipado a boletos y precios de miembro en eventos seleccionados',
            'Noticias detrás de cámaras de la reconstrucción hacia la reapertura de 2026',
            'Invitaciones a eventos solo para fanáticos, caminatas de pista y días abiertos',
            'Voz en las cosas pequeñas — encuestas sobre diseños, mercancía e ideas de eventos',
          ],
        },
      },
      {
        heading: { en: 'Join the fan club', es: 'Únete al club' },
        body: {
          en: `Membership is free — sign up with your email and you're in. We respect your privacy: no spam, no selling your address, just racing.`,
          es: `La membresía es gratis — regístrate con tu correo y ya estás dentro. Respetamos tu privacidad: nada de spam, no vendemos tu dirección, solo carreras.`,
        },
        signup: true,
      },
      {
        quote: {
          en: 'Where daring curves and the roar of engines meet the stunning Caribbean backdrop.',
          es: 'Donde las curvas atrevidas y el rugido de los motores se encuentran con el impresionante telón caribeño.',
        },
      },
    ],
  },
];

// ---------------------------------------------------------------------------
// Rendering
// ---------------------------------------------------------------------------

const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const root = (slug) => (slug === '' ? '.' : slug.split('/').map(() => '..').join('/'));
const href = (from, to) => `${root(from)}/${to === '' ? '' : to + '/'}`.replace(/^\.\//, './');
const loc = (v, lang) => (typeof v === 'string' ? v : v[lang]);

const paras = (text) => text.trim().split(/\n\s*\n/).map((p) => `<p>${esc(p.trim())}</p>`).join('\n      ');

function renderNav(lang, slug, page) {
  const items = nav
    .map((n) => `<a href="${href(slug, n.slug[lang])}"${page.slug[lang] === n.slug[lang] ? ' class="active"' : ''}>${n.label[lang]}</a>`)
    .join('\n        ');
  const other = lang === 'en' ? 'es' : 'en';
  const langLink = `<a class="lang" href="${href(slug, page.slug[other])}">${other === 'es' ? 'ES' : 'EN'}</a>`;
  return `
    <header class="nav">
      <a class="brand" href="${href(slug, lang === 'en' ? '' : 'es')}">PONCE <span>International Speedway</span></a>
      <nav>
        ${items}
        ${langLink}
      </nav>
    </header>`;
}

function renderTurns(lang) {
  return `\n      <ol class="turns">${turns
    .map(
      (t, i) => `
        <li>
          <div class="turn-head"><span class="turn-no">${i + 1}</span><h3>${esc(t.name)}</h3></div>
          <p>${esc(t.desc[lang])}</p>
        </li>`
    )
    .join('')}\n      </ol>`;
}

function renderSection(lang, slug, s) {
  if (s.quote) {
    return `
    <section class="quoteband">
      <blockquote>“${esc(s.quote[lang])}”</blockquote>
    </section>`;
  }
  let inner = `<h2>${esc(s.heading[lang])}</h2>`;
  if (s.body) inner += `\n      ${paras(s.body[lang])}`;
  if (s.list) inner += `\n      <ul>${s.list[lang].map((li) => `\n        <li>${esc(li)}</li>`).join('')}\n      </ul>`;
  if (s.specs)
    inner += `\n      <dl class="specs">${s.specs
      .map((sp) => `\n        <div><dt>${esc(loc(sp.k, lang))}</dt><dd>${esc(loc(sp.v, lang))}</dd></div>`)
      .join('')}\n      </dl>`;
  if (s.timeline)
    inner += `\n      <ol class="timeline">${s.timeline
      .map((t) => `\n        <li><div class="when">${esc(t.when[lang])}</div><div class="what">${esc(t.what[lang])}</div></li>`)
      .join('')}\n      </ol>`;
  if (s.faq)
    inner += s.faq
      .map(
        (f) => `
      <details class="faq">
        <summary>${esc(f.q[lang])}</summary>
        <p>${esc(f.a[lang])}</p>
      </details>`
      )
      .join('');
  if (s.map) inner += trackSvg(lang);
  if (s.turns) inner += renderTurns(lang);
  if (s.contact)
    inner += `\n      <p class="contact"><a href="mailto:${s.contact.email}">${s.contact.email}</a> · <a href="tel:+1${s.contact.phone.replace(/\D/g, '')}">${s.contact.phone}</a></p>`;
  if (s.cta)
    inner += `\n      <p><a class="button" href="${href(slug, s.cta.slug[lang])}">${esc(s.cta.label[lang])}</a></p>`;
  if (s.signup)
    inner += `
      <form class="signup" action="mailto:info@poncespeedway.com" method="get">
        <input type="email" name="email" placeholder="${lang === 'en' ? 'Email address' : 'Correo electrónico'}" required>
        <button class="button" type="submit">${lang === 'en' ? 'Sign Up' : 'Regístrate'}</button>
      </form>`;
  if (s.cards)
    inner += `\n      <div class="cards">${s.cards
      .map((c) => {
        const tag = c.slug ? 'a' : 'div';
        const attr = c.slug ? ` href="${href(slug, c.slug[lang])}"` : '';
        return `
        <${tag} class="card"${attr}>
          <h3>${esc(c.title[lang])}</h3>
          <p>${esc(c.text[lang])}</p>
        </${tag}>`;
      })
      .join('')}\n      </div>`;
  if (s.image)
    return `
    <section class="split">
      <div class="split-text">
      ${inner}
      </div>
      <div class="split-image" style="background-image:url('${root(slug)}/images/${s.image}')"></div>
    </section>`;
  return `
    <section>
      ${inner}
    </section>`;
}

function renderStats(lang) {
  return `
    <section class="stats">
      ${stats.map((s) => `<div class="stat"><div class="value">${s.value}</div><div class="label">${esc(s.label[lang])}</div></div>`).join('\n      ')}
    </section>`;
}

function renderPage(lang, page) {
  const slug = page.slug[lang];
  const isHome = page.slug.en === '';
  const title = isHome ? `${site.name} — ${site.tagline[lang]}` : `${page.title[lang]} — ${site.name}`;
  return `<!DOCTYPE html>
<html lang="${lang}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${esc(title)}</title>
  <meta name="description" content="${esc(site.description[lang])}">
  <link rel="stylesheet" href="${root(slug)}/style.css">
</head>
<body>
${renderNav(lang, slug, page)}
  <main>
    <div class="hero">
      <div class="hero-bg" style="background-image:url('${root(slug)}/images/${page.hero.image}')"></div>
      <div class="hero-inner">
        <div class="kicker">${esc(page.hero.kicker[lang])}</div>
        <h1>${esc(page.heroHeadline[lang])}</h1>
        <p>${esc(page.heroSub[lang])}</p>
      </div>
    </div>
${isHome ? renderStats(lang) : ''}
${page.sections.map((s) => renderSection(lang, slug, s)).join('\n')}
  </main>
  <footer>
    <p>${esc(footer.blurb[lang])}</p>
    <div class="powered">
      ${footer.poweredBy.map((p) => `<div><strong>${p.name}</strong><br>${p.line}</div>`).join('\n      ')}
    </div>
    <p class="fine">© 2026 PONCE International Speedway Park · Ponce, Puerto Rico</p>
  </footer>
  <script src="${root(slug)}/motion.js" defer></script>
${page.hero.gl ? `  <script src="${root(slug)}/hero-gl.js" defer></script>\n` : ''}</body>
</html>
`;
}

// ---------------------------------------------------------------------------
// Build
// ---------------------------------------------------------------------------

fs.rmSync(DIST, { recursive: true, force: true });
fs.mkdirSync(DIST, { recursive: true });
fs.cpSync('./static', DIST, { recursive: true });

for (const page of pages) {
  for (const lang of ['en', 'es']) {
    const slug = page.slug[lang];
    const dir = path.join(DIST, slug);
    fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(path.join(dir, 'index.html'), renderPage(lang, page));
    console.log(`  Generated: /${slug}`);
  }
}

console.log('\nDone!');
