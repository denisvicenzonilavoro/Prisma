// Prova del lettore del Prisma del cliente («Luce» giro 15), solo nel workflow: Node, nessuna dipendenza, mai nell'app.
// Uso: node Supporto/prova-file-cliente.mjs <cartella>
// La cartella la scrive `Prisma --prova-file-cliente <cartella>`: prova.html (contenuto di prova dichiarato, password di
// prova, 600.000 iterazioni) e atteso.json (password, nome, obiettivi). Qui il lettore vero (lo script #lettore del file)
// gira senza pagina in un contesto `vm`: con la password giusta deve restituire il contenuto atteso, con una sbagliata o
// con l'intestazione alterata deve rifiutare; fuori dal blocco cifrato non devono esserci né il nome né gli obiettivi né
// la password, e nel file nessun indirizzo web. Esce con 1 al primo errore.
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import vm from 'node:vm';
import { webcrypto } from 'node:crypto';

function fallisci(messaggio) {
  console.error('ERRORE: ' + messaggio);
  process.exit(1);
}

const cartella = process.argv[2];
if (!cartella) { fallisci('uso: node Supporto/prova-file-cliente.mjs <cartella>'); }

const html = readFileSync(join(cartella, 'prova.html'), 'utf8');
const atteso = JSON.parse(readFileSync(join(cartella, 'atteso.json'), 'utf8'));

function script(id) {
  const re = new RegExp('<script[^>]*id="' + id + '"[^>]*>([\\s\\S]*?)</script>');
  const m = html.match(re);
  if (!m) { fallisci('script «' + id + '» non trovato nel file'); }
  return m[1];
}

const intestazione = JSON.parse(script('intestazione'));
const blocco = script('blocco').trim();
const lettore = script('lettore');

// Fuori dal blocco: niente nome, obiettivi, password; nel file nessun indirizzo web
const fuori = html.split(blocco).join('');
if (fuori.includes(atteso.nome)) { fallisci('il nome del cliente compare fuori dal blocco cifrato'); }
for (const o of atteso.obiettivi) {
  if (fuori.includes(o)) { fallisci('l\'obiettivo «' + o + '» compare fuori dal blocco cifrato'); }
}
if (html.includes(atteso.password)) { fallisci('la password compare nel file'); }
if (/https?:\/\//.test(html)) { fallisci('il file contiene un indirizzo web'); }
if (/fetch\(|XMLHttpRequest|WebSocket|sendBeacon|import\(/.test(lettore)) { fallisci('il lettore usa la rete'); }
if (intestazione.iterazioni !== 600000) { fallisci('iterazioni attese 600000, trovate ' + intestazione.iterazioni); }

const cripto = globalThis.crypto ?? webcrypto;
const contesto = vm.createContext({ crypto: cripto, TextEncoder, TextDecoder, atob, btoa, console });
vm.runInContext(lettore, contesto, { filename: 'lettore.js' });
const L = contesto.PrismaLettore;
if (!L || typeof L.apri !== 'function') { fallisci('PrismaLettore.apri non definito dal lettore'); }

const contenuto = await L.apri(intestazione, blocco, atteso.password, cripto.subtle);
if (contenuto.nomeBattesimo !== atteso.nome) {
  fallisci('nome decifrato «' + contenuto.nomeBattesimo + '», atteso «' + atteso.nome + '»');
}
const titoli = (contenuto.obiettivi || []).map((o) => o.titolo);
if (JSON.stringify(titoli) !== JSON.stringify(atteso.obiettivi)) {
  fallisci('obiettivi decifrati ' + JSON.stringify(titoli) + ', attesi ' + JSON.stringify(atteso.obiettivi));
}
if (!contenuto.lineaVita || !Array.isArray(contenuto.lineaVita.serie) || contenuto.lineaVita.serie.length === 0) {
  fallisci('linea della vita mancante nel contenuto decifrato');
}

async function rifiuta(i, password, perche) {
  let rifiutata = false;
  try { await L.apri(i, blocco, password, cripto.subtle); } catch (e) { rifiutata = true; }
  if (!rifiutata) { fallisci(perche); }
}
await rifiuta(intestazione, atteso.password + 'x', 'una password sbagliata apre il file');
await rifiuta(Object.assign({}, intestazione, { scadenza: '2099-12-31' }), atteso.password, 'la scadenza alterata apre il file');

if (!L.scaduto('2000-01-01', new Date()) || L.scaduto('2999-01-01', new Date())) { fallisci('controllo della scadenza sbagliato'); }
if (L.frasePensione(null, 90) !== 'I risparmi bastano oltre i 90 anni') { fallisci('frase della pensione sbagliata'); }

console.log('Prova del lettore del file del cliente: decifrato con la password giusta, rifiutate la sbagliata e '
  + 'l\'intestazione alterata, niente dati fuori dal blocco (' + Math.round(html.length / 1024) + ' KB)');
