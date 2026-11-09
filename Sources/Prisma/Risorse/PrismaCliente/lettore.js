// Il lettore del Prisma del cliente (Prisma, «Luce» giro 15). Scritto a mano, senza librerie e senza rete: niente
// richieste, niente risorse esterne (controllo statico nel workflow). Decifra il blocco con la crittografia del browser
// (WebCrypto: PBKDF2-HMAC-SHA256 e AES-256-GCM) e disegna la mini-app con i dati già calcolati da Prisma.
// Il nucleo (PrismaLettore.apri) gira anche senza pagina: la prova del workflow lo esegue in Node.
'use strict';

globalThis.PrismaLettore = {
  base64: function (s) {
    var bin = atob(s);
    var u = new Uint8Array(bin.length);
    for (var i = 0; i < bin.length; i++) { u[i] = bin.charCodeAt(i); }
    return u;
  },

  datiAssociati: function (t) {
    return ['PRISMA-CLIENTE', String(t.versione), t.sale, String(t.iterazioni), t.nonce, t.scadenza].join('|');
  },

  apri: async function (intestazione, bloccoB64, password, subtle) {
    var enc = new TextEncoder();
    var sale = this.base64(intestazione.sale);
    var nonce = this.base64(intestazione.nonce);
    var associati = enc.encode(this.datiAssociati(intestazione));
    var base = await subtle.importKey('raw', enc.encode(String(password).normalize('NFC')), 'PBKDF2', false, ['deriveKey']);
    var chiave = await subtle.deriveKey(
      { name: 'PBKDF2', salt: sale, iterations: intestazione.iterazioni, hash: 'SHA-256' },
      base, { name: 'AES-GCM', length: 256 }, false, ['decrypt']);
    var chiaro = await subtle.decrypt({ name: 'AES-GCM', iv: nonce, additionalData: associati }, chiave,
      this.base64(bloccoB64.trim()));
    return JSON.parse(new TextDecoder().decode(chiaro));
  },

  scaduto: function (scadenza, oggi) {
    var p = String(scadenza).split('-');
    if (p.length !== 3) { return false; }
    var fine = new Date(Number(p[0]), Number(p[1]) - 1, Number(p[2]), 23, 59, 59);
    return oggi.getTime() > fine.getTime();
  },

  mesi: ['gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno', 'luglio', 'agosto', 'settembre', 'ottobre',
    'novembre', 'dicembre'],

  data: function (iso) {
    var d = new Date(iso);
    if (isNaN(d.getTime())) { return ''; }
    return d.getDate() + ' ' + this.mesi[d.getMonth()] + ' ' + d.getFullYear();
  },

  euro: function (v) {
    var n = Math.round(Number(v) || 0);
    var segno = n < 0 ? '−' : '';
    var s = String(Math.abs(n)).replace(/\B(?=(\d{3})+(?!\d))/g, '.');
    return segno + s + ' €';
  },

  frasePensione: function (esaurimento, etaFine) {
    if (esaurimento === null || esaurimento === undefined) { return 'I risparmi bastano oltre i ' + etaFine + ' anni'; }
    return 'I risparmi bastano fino a ' + esaurimento + ' anni';
  }
};

if (typeof document !== 'undefined') {
  (function () {
    var L = globalThis.PrismaLettore;
    var radice = document.getElementById('prisma');
    var porta = document.getElementById('porta');
    var ripiego = document.getElementById('ripiego');
    var intestazione = JSON.parse(document.getElementById('intestazione').textContent);
    var blocco = document.getElementById('blocco').textContent;

    function el(tag, classe, testo) {
      var e = document.createElement(tag);
      if (classe) { e.className = classe; }
      if (testo !== undefined && testo !== null) { e.textContent = testo; }
      return e;
    }

    function stile() { return getComputedStyle(document.documentElement); }
    function colore(nome) { return stile().getPropertyValue('--' + nome).trim(); }

    if (!window.isSecureContext || !(window.crypto && window.crypto.subtle)) {
      ripiego.textContent = 'Apri questo file con Safari o Chrome.';
      return;
    }
    ripiego.textContent = '';

    var modulo = el('form', 'accesso');
    var campo = el('input', 'campo');
    campo.type = 'password';
    campo.autocomplete = 'off';
    campo.placeholder = 'Password';
    campo.setAttribute('aria-label', 'Password');
    var bottone = el('button', 'apri', 'Apri');
    bottone.type = 'submit';
    var errore = el('p', 'errore');
    modulo.appendChild(campo);
    modulo.appendChild(bottone);
    porta.appendChild(modulo);
    porta.appendChild(errore);
    campo.focus();

    modulo.addEventListener('submit', function (ev) {
      ev.preventDefault();
      errore.textContent = '';
      bottone.disabled = true;
      bottone.textContent = 'Apro…';
      L.apri(intestazione, blocco, campo.value, window.crypto.subtle).then(function (c) {
        campo.value = '';
        porta.remove();
        if (L.scaduto(intestazione.scadenza, new Date())) { scadenza(c); } else { disegna(c); }
      }).catch(function () {
        bottone.disabled = false;
        bottone.textContent = 'Apri';
        errore.textContent = 'La password non è giusta';
      });
    });

    function scadenza(c) {
      var nome = String(c.consulente || '');
      var chi = nome.indexOf(' · il tuo consulente') > 0 ? 'a ' + nome.split(' ')[0] : 'al tuo consulente';
      var box = el('section', 'scaduto');
      box.appendChild(el('p', null, 'Questo Prisma era valido fino al ' + L.data(c.validoFinoAl) + '. Chiedi ' + chi +
        ' una copia aggiornata.'));
      var comunque = el('button', 'secondario', 'Mostralo lo stesso');
      comunque.addEventListener('click', function () { box.remove(); disegna(c); });
      box.appendChild(comunque);
      radice.appendChild(box);
    }

    function card(classe) {
      var c = el('section', 'card' + (classe ? ' ' + classe : ''));
      return c;
    }

    function anello(canvas, quota, tinta) {
      var r = window.devicePixelRatio || 1;
      var lato = 60;
      canvas.width = lato * r;
      canvas.height = lato * r;
      canvas.style.width = lato + 'px';
      canvas.style.height = lato + 'px';
      var g = canvas.getContext('2d');
      g.scale(r, r);
      g.lineWidth = 7;
      g.lineCap = 'round';
      g.strokeStyle = 'rgba(20,32,43,0.08)';
      g.beginPath();
      g.arc(lato / 2, lato / 2, (lato - 7) / 2, 0, Math.PI * 2);
      g.stroke();
      var q = Math.max(0, Math.min(1, Number(quota) || 0));
      if (q > 0) {
        g.strokeStyle = tinta;
        g.beginPath();
        g.arc(lato / 2, lato / 2, (lato - 7) / 2, -Math.PI / 2, -Math.PI / 2 + q * Math.PI * 2);
        g.stroke();
      }
    }

    function grafico(canvas, linea, eta) {
      var r = window.devicePixelRatio || 1;
      var w = 232, h = 60;
      canvas.width = w * r;
      canvas.height = h * r;
      canvas.style.width = w + 'px';
      canvas.style.height = h + 'px';
      var g = canvas.getContext('2d');
      g.scale(r, r);
      g.clearRect(0, 0, w, h);
      var s = serie(linea, eta);
      if (!s || s.valori.length < 2) { return; }
      var massimo = 1;
      linea.serie.forEach(function (x) { x.valori.forEach(function (v) { if (v > massimo) { massimo = v; } }); });
      var n = s.valori.length;
      function px(i) { return i / (n - 1) * w; }
      function py(v) { return h - Math.max(0, v) / massimo * (h - 4); }
      var viola = colore('linea') || '#8B5CF6';
      g.beginPath();
      g.moveTo(0, h);
      s.valori.forEach(function (v, i) { g.lineTo(px(i), py(v)); });
      g.lineTo(w, h);
      g.closePath();
      g.globalAlpha = 0.15;
      g.fillStyle = viola;
      g.fill();
      g.globalAlpha = 1;
      g.beginPath();
      s.valori.forEach(function (v, i) { if (i === 0) { g.moveTo(px(i), py(v)); } else { g.lineTo(px(i), py(v)); } });
      g.strokeStyle = viola;
      g.lineWidth = 2.2;
      g.stroke();
      var k = eta - linea.etaOggi;
      if (k >= 0 && k < n) {
        g.setLineDash([2, 3]);
        g.lineWidth = 1;
        g.beginPath();
        g.moveTo(px(k), 0);
        g.lineTo(px(k), h);
        g.stroke();
        g.setLineDash([]);
      }
    }

    function serie(linea, eta) {
      var trovata = null;
      linea.serie.forEach(function (s) { if (s.etaPensione === eta) { trovata = s; } });
      return trovata;
    }

    function disegna(c) {
      var app = el('div', 'app');
      var testata = el('header', 'testata');
      for (var i = 0; i < 3; i++) { testata.appendChild(el('span', 'onda onda' + i)); }
      var logo = el('div', 'logo-piccolo');
      var simbolo = document.querySelector('.logo svg');
      if (simbolo) { logo.appendChild(simbolo.cloneNode(true)); }
      testata.appendChild(logo);
      var nome = el('div', 'nome');
      nome.appendChild(el('div', 'sopra-nome', 'IL PRISMA DI'));
      nome.appendChild(el('div', 'nome-grande', c.nomeBattesimo));
      testata.appendChild(nome);
      app.appendChild(testata);
      if (c.diProva) { app.appendChild(el('p', 'prova', 'DATI DI PROVA')); }

      var corpo = el('div', 'corpo');

      if (c.obiettivi && c.obiettivi.length) {
        var co = card();
        co.appendChild(el('h2', 'occhiello', 'I TUOI OBIETTIVI'));
        var fila = el('div', 'anelli');
        c.obiettivi.forEach(function (o) {
          var v = el('div', 'obiettivo');
          var tela = el('canvas');
          v.appendChild(tela);
          v.appendChild(el('div', 'nome-obiettivo', o.titolo));
          fila.appendChild(v);
          anello(tela, o.quota, o.coloreHex);
        });
        co.appendChild(fila);
        var primo = c.obiettivi[0];
        co.appendChild(el('p', 'frase', 'Hai già messo da parte il ' + Math.round(Math.max(0, Math.min(1, primo.quota)) * 100) +
          '% di «' + primo.titolo + '»'));
        corpo.appendChild(co);
      }

      if (c.lineaVita && c.lineaVita.serie.length) {
        var l = c.lineaVita;
        var cl = card();
        cl.appendChild(el('h2', 'occhiello', 'E SE VADO IN PENSIONE A…'));
        var etaTesto = el('div', 'eta', l.etaProposta + ' anni');
        cl.appendChild(etaTesto);
        var cursore = el('input', 'cursore');
        cursore.type = 'range';
        cursore.min = String(l.serie[0].etaPensione);
        cursore.max = String(l.serie[l.serie.length - 1].etaPensione);
        cursore.step = '1';
        cursore.value = String(l.etaProposta);
        cursore.setAttribute('aria-label', 'Età della pensione');
        cl.appendChild(cursore);
        var tela2 = el('canvas', 'grafico');
        cl.appendChild(tela2);
        var frase = el('p', 'frase');
        cl.appendChild(frase);
        if (l.indicativa) { cl.appendChild(el('p', 'nota', 'Dopo la pensione la linea è indicativa: ne parliamo insieme')); }
        var aggiorna = function () {
          var eta = Number(cursore.value);
          etaTesto.textContent = eta + ' anni';
          var s = serie(l, eta);
          var esaurimento = s ? s.etaEsaurimento : null;
          frase.textContent = L.frasePensione(esaurimento, l.etaFine);
          frase.className = 'frase ' + (esaurimento === null || esaurimento === undefined ? 'basta' : 'non-basta');
          grafico(tela2, l, eta);
        };
        cursore.addEventListener('input', aggiorna);
        corpo.appendChild(cl);
        aggiorna();
      }

      if (c.lettera) {
        var cle = card('riga');
        var q = el('div', 'quadrato', '✉');
        cle.appendChild(q);
        var t = el('div', 'testi');
        t.appendChild(el('div', 'titolo-card', 'Una lettera da te'));
        t.appendChild(el('div', 'sotto-card', 'dal tuo futuro'));
        cle.appendChild(t);
        cle.appendChild(el('div', 'freccia', '›'));
        cle.tabIndex = 0;
        cle.addEventListener('click', function () { lettera(c.lettera); });
        corpo.appendChild(cle);
      }

      if (c.film) {
        var cf = card('film');
        var video = el('video', 'video');
        video.controls = true;
        video.preload = 'metadata';
        video.setAttribute('playsinline', '');
        video.src = 'data:video/mp4;base64,' + c.film;
        cf.appendChild(el('div', 'titolo-card', 'Il film del tuo piano'));
        cf.appendChild(el('div', 'sotto-card', 'venti secondi'));
        cf.appendChild(video);
        corpo.appendChild(cf);
      }

      [['luce', 'Il prisma di luce'], ['giornata', 'Una giornata della pensione']].forEach(function (v) {
        if (!c[v[0]]) { return; }
        var ci = card();
        ci.appendChild(el('h2', 'occhiello', v[1].toUpperCase()));
        var img = el('img', 'immagine');
        img.alt = v[1];
        img.src = 'data:image/png;base64,' + c[v[0]];
        ci.appendChild(img);
        corpo.appendChild(ci);
      });

      if (c.sinistri && c.sinistri.length) {
        c.sinistri.forEach(function (s) {
          var cs = card();
          cs.appendChild(el('h2', 'occhiello', 'IL TUO SINISTRO'));
          cs.appendChild(el('div', 'titolo-card', s.titolo));
          var fasi = el('ol', 'fasi');
          s.fasi.forEach(function (f) {
            var li = el('li', 'fase ' + f.stato);
            li.appendChild(el('span', 'cerchio'));
            li.appendChild(el('span', null, f.nome));
            fasi.appendChild(li);
          });
          cs.appendChild(fasi);
          if (s.ultimoFatto) { cs.appendChild(el('p', 'nota', s.ultimoFatto)); }
          if (s.pagato) { cs.appendChild(el('p', 'nota', 'Pagati ' + s.pagato)); }
          cs.appendChild(el('p', 'nota', 'Aggiornato da ' + String(s.consulente).split(' · ')[0] + ' · ' + L.data(s.aggiornatoIl)));
          corpo.appendChild(cs);
        });
      }

      if (c.posizioni && c.posizioni.length) {
        var cp = card();
        cp.appendChild(el('h2', 'occhiello', 'LE TUE POSIZIONI'));
        c.posizioni.forEach(function (p) {
          var r = el('div', 'posizione');
          var sinistra = el('div', 'testi');
          sinistra.appendChild(el('div', 'titolo-card', p.nome));
          var canale = el('div', 'canale', p.canale);
          canale.style.color = p.coloreCanaleHex;
          sinistra.appendChild(canale);
          r.appendChild(sinistra);
          var destra = el('div', 'valore');
          destra.appendChild(el('div', null, L.euro(p.valore)));
          destra.appendChild(el('div', 'sotto-card', L.data(p.data)));
          r.appendChild(destra);
          cp.appendChild(r);
        });
        corpo.appendChild(cp);
      }

      var piede = el('footer', 'piede');
      piede.appendChild(el('div', null, c.consulente));
      (c.avvertenze || []).forEach(function (a) { piede.appendChild(el('div', null, a)); });
      piede.appendChild(el('div', null, 'Valido fino al ' + L.data(c.validoFinoAl)));
      corpo.appendChild(piede);
      app.appendChild(corpo);
      radice.appendChild(app);
    }

    function lettera(testo) {
      var foglio = el('div', 'lettera');
      var chiudi = el('button', 'secondario', 'Chiudi');
      chiudi.addEventListener('click', function () { foglio.remove(); });
      foglio.appendChild(chiudi);
      foglio.appendChild(el('h2', 'occhiello', 'UNA LETTERA DAL FUTURO'));
      String(testo).split('\n').forEach(function (riga) { foglio.appendChild(el('p', null, riga)); });
      document.body.appendChild(foglio);
    }
  })();
}
