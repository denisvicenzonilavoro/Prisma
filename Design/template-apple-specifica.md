# Prisma · specifica unica per il porting in SwiftUI del template «stile Apple»

Fonte: `/tmp/acqua/template-apple.html` (copia di `Design/template-apple.html`, 717 righe: CSS 15-187, HTML 189-221, JS 222-715).
Relazioni di partenza: `spec-shell.md`, `spec-movimento.md`, `spec-posizioni-clienti.md`, `spec-analisi-agenda.md`, `spec-prospetti-impostazioni-ruby.md` (tutte in `/tmp/acqua/`).
Schermate di riferimento (1440×900, ognuna `-chiaro.png` e `-scuro.png`): `/tmp/acqua/shots/{shell,movimento,posizioni-clienti,analisi-agenda,prospetti-impostazioni-ruby}/`.

Unità: 1 px CSS del palco = 1 pt SwiftUI. Durate in secondi. Curve scritte come `(x1,y1,x2,y2)` di `cubic-bezier`.

---

## Indice

0. Valori in conflitto tra le relazioni, verificati nel codice
1. Tema Apple: i token
   - 1.1 Colori che cambiano con l'aspetto
   - 1.2 Colori fissi
   - 1.3 Superfici (vetro, finestra, card, pannelli, carta)
   - 1.4 Ombre
   - 1.5 Raggi
   - 1.6 Spaziature e misure ricorrenti
   - 1.7 Caratteri e scala tipografica
   - 1.8 Tempi e curve (`Tema.Apple.Moto`)
2. Componenti: comportamento e API SwiftUI
   - 2.0 Regole comuni: Riduci movimento e istantanee
   - 2.1-2.24 Un paragrafo per componente
3. Shell e scrivania
   - 3.1 Livelli · 3.2 Blocco · 3.3 Barra superiore · 3.4 Dock · 3.5 Finestra · 3.6 Scrivania · 3.7 Acqua · 3.8 Notifiche · 3.9 Toast · 3.10 Tastiera
4. Le app, schermata per schermata
   - 4.1 Posizioni · 4.2 Clienti · 4.3 Analisi 360 · 4.4 Agenda · 4.5 Prospetti · 4.6 Impostazioni · 4.7 Ruby · 4.8 Ricerca
   - 4.9 Errori del template da non copiare
5. Differenze da Prisma di oggi
   - 5.1 Differenze di progetto e di regole
   - 5.2 Token diversi da quelli di `Tema` di oggi
   - 5.3 macOS 13: cosa manca in SwiftUI e il ripiego
   - 5.4 Ordine di lavoro proposto

---

## 0. Valori in conflitto tra le relazioni, verificati nel codice

| # | Punto | Relazioni | Codice (riga) | Valore da usare |
|---|---|---|---|---|
| 1 | Dissolvenza del contenuto della finestra al montaggio | movimento: curva `ease`. shell: lineare | `wc.animate([{opacity:0},{opacity:1}],{duration:200})` (390): WAAPI senza `easing`, quindi **lineare** | 0,2 s lineare |
| 2 | Ritardo base della cascata nelle finestre | posizioni-clienti: «140, o 0 se nessuna app era aperta». movimento e analisi: sempre 140 | `entrata(wc,curApp?140:0)` dopo `curApp=app` (388-391) | **sempre 0,14 s** |
| 3 | Anelli della scrivania senza animazione d'ingresso | shell: `accendi(desk,0)` parte a 0/130/260 ms | `(d\|\|200)+i*130` (249): 0 è falso | **0,20 / 0,33 / 0,46 s** |
| 4 | Massima inclinazione | movimento: impegni non elencati | `data-max="3"` sugli impegni dell'agenda (597); 5 aree di Analisi 360 e «Prossimo incontro»; 6 familiari; 10 (predefinito) schede «Da fare» e obiettivi | 3 / 5 / 6 / 10 |
| 5 | Voci delle notifiche | il compito diceva «a molla» | `translateX(20px)`, 400 ms, `delay:80+i*70`, `(.22,1,.36,1)` (698) | 0,4 s `--out`, ritardo 0,08 + i·0,07 s |
| 6 | Superamento di `--spring` | movimento: «circa il 10%» | picco numerico della bézier `(.34,1.45,.64,1)` = **1,066** | 6,6% |
| 7 | Superamento delle altre curve | «circa 5-8%» per il dettaglio | picchi: apertura dettaglio 1,0155; finestra 1,0037; chiusura dettaglio 1,0013 | 1,6% / 0,4% / 0,1% |
| 8 | Uscita della scheda del dossier e della griglia di Analisi 360 | «curva predefinita» | WAAPI senza `easing` (456, 543) | **lineare**, 0,13 s e 0,14 s |
| 9 | Comparsa del blocco (lucchetto) con Riduci movimento | shell: «quasi tutte le durate a 1 ms» | `blocca()` (702) usa 500 ms senza ramo `ridotto`; `sblocca()` invece sì | nel porting vanno ridotte entrambe (§2.0) |
| 10 | Pioggia con Riduci movimento | movimento: ogni 2,5-3,6 s | `(ridotto?2.5:.7)+Math.random()*1.1` (315) | 2,5 + rand·1,1 s, forza 3 |
| 11 | Nome del file di relazione dei componenti | il riassunto citava `spec-componenti.md` | il file vero è `spec-movimento.md` | — |
| 12 | Relazione Prospetti/Ruby | citata come `spec-prospetti-ruby.md` | il file vero è `spec-prospetti-impostazioni-ruby.md` | — |

Tutti gli altri valori delle cinque relazioni coincidono tra loro e con il codice. Sono stati ricontrollati in particolare: `entrata`, `conteggi`, `accendi`, `espandi`, `chiudiDet`, `vai`, `chiudiFinestra`, `sblocca`, `blocca`, `rimbalza`, `completaTask`, `prepara`, `morphP`, `gira`, `chiediRuby`, `.tilt`, `.sheen`, agenda e pioggia.

---

## 1. Tema Apple: i token

Spazio dei nomi proposto: `Tema.Apple` in un file nuovo, `Sources/Prisma/DesignSystem/TemaApple.swift` (più `TemaAppleMoto.swift` per i tempi). Si appoggia agli aiuti che già esistono: `Color.dinamico(chiaro:scuro:)`, `Color(hex:)` e `Color(r:g:b:a:)`.

### 1.1 Colori che cambiano con l'aspetto (`Tema.Apple.Colore`)

| Nome Swift | CSS | Chiaro | Scuro | Uso |
|---|---|---|---|---|
| `inchiostro` | `--ink` | `rgba(0,0,0,.87)` | `rgba(255,255,255,.94)` | testo principale |
| `inchiostro2` | `--ink2` | `rgba(0,0,0,.55)` | `rgba(255,255,255,.62)` | testo secondario, `.k`, `.lbl` |
| `inchiostro3` | `--ink3` | `rgba(0,0,0,.34)` | `rgba(255,255,255,.38)` | etichette di assi, ore, giorni fuori mese |
| `separatore` | `--sep` | `rgba(0,0,0,.08)` | `rgba(255,255,255,.09)` | bordi 1 pt, divisori |
| `finestra` | `--win` | `rgba(246,248,251,.86)` | `rgba(16,26,35,.86)` | fondo della finestra interna |
| `pannello` | `--panel` | `rgba(255,255,255,.72)` | `rgba(255,255,255,.05)` | barre laterali `.side` |
| `card` | `--card` | `rgba(255,255,255,.82)` | `rgba(255,255,255,.07)` | card, tile, suggerimenti |
| `cardPiena` | `--cardE` | `#FFFFFF` | `rgba(40,54,66,1)` = `#283642` | dettaglio, pulsanti, pillola del segmentato, campo di Ruby |
| `binario` | `--track` | `rgba(0,0,0,.07)` | `rgba(255,255,255,.10)` | binari di barre, interruttori, cursori, mesi vuoti, cerchietti |
| `chip` | `--chip` | `rgba(0,0,0,.05)` | `rgba(255,255,255,.08)` | fondo dei segmentati, ricerca, hover, bolle di Ruby, fondo dell'anteprima |
| `vetro` | `--glass` | `rgba(255,255,255,.50)` | `rgba(16,32,44,.42)` | riempimento di `.glass` |
| `bordoVetro` | `--glassE` | `rgba(255,255,255,.70)` | `rgba(255,255,255,.16)` | bordo di `.glass` e della finestra |
| `inchiostroAcqua` | `--wallInk` | `rgba(8,26,38,.88)` | `#FFFFFF` | testo sopra l'acqua (barra, saluto, dock) |
| `inchiostroAcqua2` | `--wallInk2` | `rgba(8,26,38,.60)` | `rgba(255,255,255,.66)` | sottotitolo del saluto |
| `velo` | `--scrim` | `rgba(220,232,240,.40)` | `rgba(5,12,18,.50)` | velo sotto il dettaglio |
| `canaleAlleanza` | `--chA` | `#2563EB` | `#6B95FF` | testo e pallino dell'etichetta Alleanza, barra del canale |
| `canaleIndipendente` | `--chI` | `#B06E12` | `#D0954A` | testo e pallino dell'etichetta indipendente |
| `fuoriPalco` | `html,body` | `#BFD4DF` | `#081219` | non serve nell'app (il palco è la finestra) |
| `veloBlocco` | `#lock` | `rgba(220,234,242,.18)` | `rgba(5,14,20,.25)` | velo del blocco (+ sfocatura 3) |
| `logo` | `.logoF` | `#0F2433` | `#FFFFFF` | logo Prisma nella barra e nel blocco (come oggi) |
| `riflessoInclinazione` | `.sheen` | bianco .60, fusione `softLight` | bianco .16, fusione `normal` | riflesso delle schede inclinabili |
| `filoVetro` | inset del vetro | bianco .55 | bianco .12 | filo di luce interno in alto di `.glass` |

### 1.2 Colori fissi (`Tema.Apple.Colore`, uguali nei due aspetti)

| Nome Swift | Valore | Uso |
|---|---|---|
| `accento` | `#007AFF` | pulsante primario, collegamenti, bolle dell'utente, puntini dell'agenda |
| `rosso` | `#E5484D` | urgenza, oggi nel calendario, linea dell'ora, area Protezione |
| `arancio` | `#E08A00` | urgenza media, completezza sotto l'85% |
| `verde` | `#2FA35A` | positivo, spunte, «Ti preparo», delta |
| `verdeInterruttore` | `#34C759` | interruttore acceso |
| `rossoBadge` | `#FF3B30` | badge della campanella |
| `anello1` / `anello2` / `anello3` | `#30B15C` / `#0A84FF` / `#8B5CF6` | anelli (in regola, riesami, proposte); verde backup |
| `stima` | `#8B5CF6` | stime e proposte nei grafici, area Previdenza |
| `area.previdenza` / `.protezione` / `.investimenti` / `.liquidita` | `#8B5CF6` / `#E5484D` / `#0A84FF` / `#30B15C` | Analisi 360 |
| `composizione` | `#0A84FF`, `#5AC8FA`, `#2563EB`, `#9FB3C2` | azionario, obbligazionario, gestione separata, liquidità |
| `fondoAlleanza` | `rgba(37,99,235,.13)` | fondo dell'etichetta Alleanza (non cambia in scuro) |
| `fondoIndipendente` | `rgba(176,110,18,.14)` | fondo dell'etichetta indipendente |
| `toast` | `rgba(15,36,51,.92)` | fondo del toast, testo bianco |
| `sala` | `rgba(6,14,20,.92)` | velo della presentazione |
| `mossaDelGiorno` | `#1D6FC4` | `.lbl` «La mossa del giorno» |
| `scadenza` | `#C25E00` | «tra 45 giorni» |
| `selezioneVoce` | `rgba(0,122,255,.13)` | voce selezionata in rubrica e barre laterali |
| `selezioneGiorno` | `rgba(0,122,255,.14)` | giorno scelto nel calendario |
| `avvisoFondo` / `avvisoBordo` | `rgba(224,138,0,.10)` / `rgba(224,138,0,.25)` | card «Da non dimenticare» |
| `semaforo` | `#FF5F57`, `#FEBC2E`, `#28C840` | semafori della finestra |
| `avatarDV` | gradiente `#7FA5D9 → #4B79B8` | avatar del consulente |
| `sfera` | radiale a (34%,28%): `#FFF 0`, `#D6ECF9 18%`, `#7FB9E6 48%`, `#3F79C0 78%`, `#2C4F9A 100%` | sfera di Ruby |
| `sferaMossa` | radiale a (34%,28%): `#FFF 0`, `#CFE6F6 22%`, `#78B2DB 58%`, `#3C76B0 100%` | sfera «MB» della mossa |
| `riflessoSfera` | conico: trasparente, bianco .45, trasparente 30%, `rgba(160,120,255,.35)`, trasparente 60%, `rgba(120,230,255,.4)`, trasparente | `:after` della sfera, fusione `overlay` |
| `colori impegni` | Giulia `#C45A75`, Marco `#4B79B8`, Laura `#7D63C4`, Andrea `#2C7A55`, Sofia `#B98A35`, formazione Alleanza `#2563EB`, attività `#7A8794`, riesame `#6B8199` | agenda (fondo = colore al 13%, `alpha 0x22`) |

**Carta (`Tema.Apple.Carta`, PDF e anteprime: sempre chiara, mai vetro)**: fondo `#FFFFFF`, testo `#14202B`, sottotitolo `#4A5964`, testo corrente `#33424D`, etichette `#5A6873`, piede `#7A8790`, filetti `#E3E8EC`, linee `#C9D3DA`, binari `#EEF2F5` / `#E6EEF7` / `#F6E3E4`, sopratitolo `#2563EB`, positivo `#2F7A4A`, ambra `#B45309`, rosso `#E5484D`, blu grafico `#0A84FF`.

### 1.3 Superfici (`Tema.Apple.Superficie`)

| Nome | Riempimento | Sfocatura dietro | Bordo | Ombra | Raggio |
|---|---|---|---|---|---|
| `vetro` (`.glass`: barra, dock, riquadri della scrivania, notifiche, pulsante del blocco) | `vetro` | 16, saturazione 1,4 | 1 `bordoVetro` | `ombraVetro` + filo interno | secondo l'elemento |
| `finestra` (`#win`) | `finestra` | 34, saturazione 1,3 | 1 `bordoVetro` | `ombraFinestra` | 24 |
| `card` | `card` | nessuna | 1 `separatore` | `ombraCard` (nelle app quasi sempre nessuna) | 22 |
| `tile` | `card` | nessuna | 1 `separatore` | nessuna | 18 |
| `pannello` (`.side`) | `pannello` | nessuna | 1 `separatore` | nessuna | 20 |
| `dettaglio` (`#det`) | `cardPiena` | nessuna | 1 `separatore` | `ombraDettaglio` | 22 → 28 |
| `carta` (`.paper`) | `#FFF` | nessuna | nessuno | `ombraCarta` | 0 |

Il vetro va fatto con i materiali già presenti in `Vetro.swift` / `Materiali.swift`: su macOS 26 il vetro nativo, sotto `#if compiler(>=6.2)` e `if #available(macOS 26.0, *)`; su macOS 13-25 il ripiego con `Material` più il riempimento. Nelle istantanee si usa il riempimento disegnato, senza sfocatura.

### 1.4 Ombre (`Tema.Apple.Ombra`)

In SwiftUI ogni strato CSS diventa un `.shadow(color:radius:x:y:)`. Il `radius` è circa la sfocatura CSS divisa per 2. Lo «spread» negativo non esiste: si ottiene riducendo l'alfa o con `OmbraPrecalcolata` (vedi `OmbraPrecalcolata.swift`).

| Nome | Chiaro | Scuro |
|---|---|---|
| `card` | `0 24 48 -28 rgba(8,40,60,.4)`, `0 2 8 -3 rgba(8,40,60,.1)` | `0 26 52 -26 rgba(0,0,0,.8)`, `0 3 10 -3 rgba(0,0,0,.35)` |
| `vetro` | `0 22 44 -24 rgba(8,40,60,.36)`, `0 3 10 -4 rgba(8,40,60,.12)`, inset `0 1 0` bianco .55 | `0 26 52 -24 rgba(0,0,0,.7)`, inset bianco .12 |
| `finestra` | `0 40 80 -24 rgba(8,40,60,.45)` (uguale in scuro) | — |
| `inclinata` (hover `.tilt`) | `0 40 60 -30 rgba(8,40,60,.5)`, `0 4 12 -4 rgba(8,40,60,.16)` (uguale in scuro) | — |
| `dettaglio` | `0 50 90 -30 rgba(8,40,60,.55)` (uguale in scuro) | — |
| `carta` | `0 20 50 -10 rgba(0,0,0,.25)` | — |
| `pillola` (segmentato) | `0 1 4 rgba(0,0,0,.14)` | — |
| `manopolaInterruttore` | `0 2 5 rgba(0,0,0,.25)` | — |
| `manopolaCursore` | `0 3 10 rgba(0,0,0,.28)` | — |
| `sfera` | inset `0 -4 10 rgba(10,30,80,.35)`, `0 4 12 -4 rgba(40,90,170,.6)`; respiro a metà ciclo: `0 10 30 -6 rgba(90,140,255,.7)` | — |

### 1.5 Raggi (`Tema.Apple.Raggio`)

| Nome | pt | Uso |
|---|---|---|
| `pillola` | 99 (`Capsule`) | pulsanti, chip, segmentati, interruttori, avatar, toast, campo di Ruby |
| `dettaglioAperto` | 28 | dettaglio a misura piena |
| `riquadro` | 26 | riquadri della scrivania, dock |
| `finestra` | 24 | finestra interna |
| `card` | 22 | card, notifiche, dettaglio chiuso, schede «Da fare», spunta |
| `pannello` | 20 | barre laterali, bolle di chat, anteprima dei prospetti |
| `tile` | 18 | tile |
| `voce` | 14 | voci di rubrica, voci delle notifiche, impegni, palco |
| `giorno` | 12 | caselle del calendario, blocchi mese, contenitore della composizione |
| `kpiCarta` | 10 | riquadri delle cifre sulla carta |
| `barra` | 9 | barre da 8, binario del cursore, puntini |
| `bolla piccola` | 6 | angolo stretto delle bolle (Ruby in basso a sinistra, utente in basso a destra), pezzi della composizione |

### 1.6 Spaziature e misure ricorrenti (`Tema.Apple.Misura`)

- Finestra: margine esterno 16, alta da y 42 (barra 34 + 8) fino a 100 dal fondo (spazio del dock). Barra del titolo 38, intestazione 54 (`padding 4 18 12`), contenuto a 12 dai bordi e a 92 dall'alto.
- Card: padding 22×26 (portafoglio), 22×24, 20×22, 18×20; riga d'impostazione 16×20; tile 14×16; barra laterale 14×12 (Ruby: `padding-top` 30); dettaglio 26×30, piede a 30 dai lati e 24 dal fondo, ✕ a 22/22.
- Spazi: griglie 14; cifre 12; colonne della scrivania 16; margini della scrivania 44; nastro 14; segmentato con padding 3 e voci 6×14; pulsante 7×14 (grande 10×18); etichetta del canale 3×9 con spazio 5 e pallino 6.
- Larghezze delle barre laterali: Clienti 250, Prospetti 290, Ruby 300, Impostazioni 260, Agenda 330.
- Controlli: interruttore 44×26 con manopola 20 (spostamento 3 → 21); cursore con binario 6 e manopola 28; frecce 32; pulsante d'invio 36; avatar 24 / 30 / 34 / 38 / 54 / 56 / 64 / 70.
- Dock: icona 50, voce larga 62, padding `8 10 5`, spazio 4, a 8 dal fondo; pallino 4.

### 1.7 Caratteri e scala tipografica (`Tema.Apple.Carattere`)

Il testo usa SF Pro Text (`.system(size:weight:)`); i titoli e i numeri usano SF Pro Display. In SwiftUI il sistema sceglie da solo Text o Display a partire da 20 pt, quindi basta `.system(size:weight:design: .default)`. Inter si usa solo sulla carta (già oggi su `Carta.swift`, se presente; altrimenti la carta resta in SF). La spaziatura delle lettere si rende con `.tracking(_)`. Le cifre tabellari si ottengono con `.monospacedDigit()`.

| Nome Swift | pt / peso / tracking | Note |
|---|---|---|
| `oraBlocco` | 128 / light / −5 | tabellari, interlinea 1 |
| `numeroGrande` (`.bignum`) | 62 / bold / −2,2 | tabellari, interlinea 1 |
| `giornoAgenda` | 76 / light | riquadro agenda della scrivania |
| `valoreCursore` | 46 / bold / −1,5 (44 in Analisi 360) | colore dell'obiettivo o dell'area |
| `centroAnelloGrande` | 44 / 42 / 36 / 32 / 24 / bold | secondo l'anello |
| `saluto` | 38 / bold / −1,2 | |
| `totaleScrivania` | 36 / bold / −1 | tabellari |
| `titoloCarta` | 36 / bold / −1, interlinea 1,05 | solo PDF |
| `titoloDettaglio` | 30 / 28 / 26 / bold / −0,6…−0,5 | |
| `nomeDossier` | 27 / bold / −0,6 | |
| `valore` (`.v`) | 26 / bold / −0,5 | tabellari |
| `titoloMossa` | 25 / bold / −0,5 | |
| `titoloGruppo` | 22 / bold / −0,5, interlinea 1,1 | gruppi del nastro; anche «Ciao, sono Ruby.» |
| `h2` | 21 / bold / −0,4 | |
| `meseAgenda` | 20 / bold | anche `.leg .n` |
| `perche` | 19 / bold / −0,3, interlinea 1,22 | schede «Da fare» |
| `fraseRuby` | 19 / semibold / −0,3, interlinea 1,3 | |
| `titoloFinestra` | 17 / bold | intestazione della finestra |
| `delta` | 15 / semibold | anche titoli delle righe d'impostazione (15 bold) |
| `corpoGrande` | 14,5 / regular, interlinea 1,45-1,55 | corpo della mossa, messaggi di Ruby, spiegazioni |
| `corpo` | 14 / regular | testo corrente nelle card |
| `barraTitolo` | 14 / semibold | |
| `voceLista` | 13,5 / regular | `.prep`, «Da fare oggi» |
| `barra` | 13 / semibold (orologio 500) | barra superiore, voci del segmentato, toast, notifiche |
| `pulsante` | 12,5 / semibold (grande 13,5) | |
| `secondario` (`.k`) | 12,5 / regular | `inchiostro2` |
| `etichetta` (`.lbl`) | 12 / semibold / +0,6, MAIUSCOLO | `inchiostro2` o colore dell'area |
| `sottotitolo` (`.sub`) | 12 / medium / +0,6, MAIUSCOLO | |
| `quando` | 12 / bold / +0,3, MAIUSCOLO | tono dell'urgenza |
| `canale` | 11,5 / semibold | etichette `.chA` / `.chI` |
| `asse` | 11 / regular | etichette dei grafici, `inchiostro3` |
| `dock` | 10,5 / medium | `inchiostroAcqua` |
| `badge` | 9 / bold | |

Nell'interfaccia le cifre usano sempre il formato italiano: punto per le migliaia, virgola per i decimali, meno tipografico `−` (U+2212), «12.345 €» con uno spazio prima del simbolo e «52%» senza spazio.

### 1.8 Tempi e curve (`Tema.Apple.Moto`)

Tre curve con nome:
- `Curva.molla` = `(0.34, 1.45, 0.64, 1)` (`--spring`, superamento del 6,6%);
- `Curva.uscita` = `(0.22, 1, 0.36, 1)` (`--out`);
- `Curva.quartica` = `1 − (1−t)^4` (numeri e `morphP`, solo in Swift).

Nella tabella, «ripiego molla» è la molla SwiftUI equivalente (`.spring(response:dampingFraction:)`): serve dove una bézier con y > 1 non si comporta bene (§5.3).

| Nome Swift | Durata | Curva | Altri parametri | Ripiego molla |
|---|---|---|---|---|
| `cascata` | 0,72 | uscita | passo 0,048; da y +18, scala 0,985, sfocatura 6, opacità 0; base finestra 0,14, scrivania 0,12, dentro un'app 0 | — |
| `cascataLaterale` (impegni) | 0,60 | uscita | da x +30; ritardo 0,12 + i·0,08 | — |
| `voceNotifica` | 0,40 | uscita | da x +20; ritardo 0,08 + i·0,07 | — |
| `pannelloNotifiche` | 0,38 | molla | da y −10, scala 0,97 | 0,38 / 0,65 |
| `numero` | 1,10 + min(i,6)·0,06 | quartica | parte da 0 | — |
| `numeroCambio` | 0,90 | quartica | da valore a valore (proposte, legenda) | — |
| `numeroSimulatore` | 1,00 | quartica | valori del simulatore all'apertura | — |
| `anello` | 1,40 | uscita | ritardo d + i·0,13 (d: finestra 0,32, dettaglio 0,12, cambio scheda o cliente 0,15, scrivania 0,30 dopo 0,30; predefinito 0,20) | — |
| `brillio` | 0,60 (filtro), tenuto 0,90 | ease | ombra 10 del colore dell'anello | — |
| `linea` | 1,50 | uscita | ritardo 0,15 + i·0,12 | — |
| `area` | 0,90 | ease | ritardo 0,60 | — |
| `barra` | 1,20 | uscita | ritardo 0,15 + i·0,09 | — |
| `morphProposte` | 0,90 | quartica | parametro p 0 → 1 | — |
| `segmentato` | 0,50 | molla | testo: colore in 0,30 | 0,50 / 0,65 |
| `interruttore` | 0,35 | molla | fondo in 0,30 | 0,35 / 0,65 |
| `pulsantePremuto` | 0,25 | molla | scala 0,95; hover luminosità 0,97 in 0,2 | 0,25 / 0,65 |
| `inclinazione` | 0,50 | molla | prospettiva 900; sollevamento −5; scala 1,02; ombra 0,4; riflesso 0,3 | 0,50 / 0,65 |
| `riquadroSopra` | 0,45 | molla | −3 in y | 0,45 / 0,65 |
| `suggerimentoSopra` | 0,25 | molla | −2 in y | 0,25 / 0,65 |
| `dettaglioApre` | 0,62 | `(0.32,1.22,0.5,1)` | raggio 22 → 28; contenuto: dopo 0,17 + 0,16, opacità in 0,35 | 0,62 / 0,80 |
| `dettaglioChiude` | 0,46 | `(0.32,1.08,0.5,1)` | contenuto via in 0,20 | 0,46 / 0,90 |
| `velo` | 0,45 | ease | sfocatura 0 → 10 | — |
| `finestraApre` | 0,60 | `(0.3,1.12,0.5,1)` | parte dall'icona del dock, scale x e y separate, opaca al 35% | 0,60 / 0,87 |
| `finestraChiude` | 0,48 | `(0.5,0,0.3,1)` | svanisce dopo il 60% | — |
| `cambioApp` | uscita 0,15 ease-in, entrata 0,20 lineare | — | uscita a scala 0,985 | — |
| `scrivaniaSotto` | 0,50 | ease | opacità 0,25 con una finestra aperta | — |
| `rimbalzoIcona` | 0,70 | ease-out | −16, 0, −7, 0 (passi uniformi) | — |
| `dock` | 0,70 | molla | sale da +140 (ritardo 0,20 dallo sblocco) | 0,70 / 0,65 |
| `ingrandimentoDock` | 0,14 | ease | s = 1 + 0,36·max(0, 1 − d/130) | — |
| `sblocco` | 0,65 | `(0.5,0,0.3,1)` | sale di 60, scala 1,04, sfocatura 8; barra in 0,60 | — |
| `blocco` | 0,50 | uscita | scende da −30 | — |
| `luceBlocco` | 2,60 ciclo | ease-in-out | attraversa nel 60% del ciclo | — |
| `toast` | 0,45 | molla | da y −20, tenuto 2,4 | 0,45 / 0,65 |
| `spuntaCerchio` / `spuntaSegno` | 0,50 / 0,35 (ritardo 0,35) | uscita | velo verde in 0,40 | — |
| `tiPreparo` | molla 0,35 per voce | molla | ritmo 0,22 + i·0,36; toast a 0,32 + n·0,36 | 0,35 / 0,65 |
| `fatto` | +0,60 anello; +1,15 la scheda si stringe; +0,56 viene tolta | molla | larghezza e margine 0,55, transform 0,50, opacità 0,40 | — |
| `nastro` | 0,70 | uscita | frecce ±500 | — |
| `cambioCliente` | uscita 0,14 ease-in (x +14) | — | poi cascata con base 0 | — |
| `cambioScheda` | uscita 0,13 lineare (y +6) | — | poi cascata con base 0 | — |
| `cambioGriglia` | uscita 0,14 lineare (scala 0,99) | — | — | — |
| `blocchiMese` | 0,50 | molla | da scala y 0,2; ritardo 0,20 + i·0,06 | 0,50 / 0,65 |
| `paginaEsce` / `paginaEntra` | 0,18 ease-in / 0,52 uscita | — | y ∓30 / ±40, scala 0,70 ↔ 0,68 | — |
| `salaApre` / `salaChiude` | velo 0,40 lineare, foglio 0,60 uscita (0,74 → 0,88) / 0,25 | — | — | — |
| `giroPagina` | 0,22 ease-in, poi 0,52 uscita | — | x −d·120, poi da +d·160; scala 0,85 | — |
| `backup` | 1,60 | `(0.4,0,0.2,1)` | ✓ a 1,70 con molla 0,5 da scala 0,3 | — |
| `sferaGira` / `sferaRespira` | 6 lineare / 4 ease-in-out | — | scala 1,045 a metà ciclo | — |
| `sferaPensa` | 0,90 × 2 | lineare | scala 1 → 1,1 → 1 | — |
| `bollaUtente` | 0,42 | molla | da y +14, scala 0,96 | 0,42 / 0,65 |
| `puntini` | 1,0 ciclo | — | sfasati di 0,15; a 30% del ciclo y −5 | — |
| `attesaRisposta` / `parola` | 0,90 / 0,038 per parola | — | — | — |
| `schedaCalcoli` | 0,50 | uscita | da y +10 | — |
| `domandaDaScrivania` | ritardo 0,70 | — | — | — |

Proposta di codice:

```swift
extension Tema { enum Apple {} }
extension Tema.Apple {
    enum Moto {
        enum Curva {
            static let molla   = (0.34, 1.45, 0.64, 1.0)
            static let uscita  = (0.22, 1.0, 0.36, 1.0)
            static func quartica(_ t: Double) -> Double { 1 - pow(1 - min(max(t, 0), 1), 4) }
        }
        static func bezier(_ c: (Double, Double, Double, Double), _ durata: Double) -> Animation {
            Movimenti.curva(.timingCurve(c.0, c.1, c.2, c.3, duration: durata))
        }
        enum Cascata {
            static let durata = 0.72, passo = 0.048, baseFinestra = 0.14, baseScrivania = 0.12
            static let spostamento: CGFloat = 18, scala: CGFloat = 0.985, sfocatura: CGFloat = 6
            static var animazione: Animation { bezier(Curva.uscita, durata) }
        }
        // … una voce per ogni riga della tabella
    }
}
```

---

## 2. Componenti: comportamento e API SwiftUI

### 2.0 Regole comuni a tutti i componenti

**Riduci movimento.** Si legge da `Movimenti.calmo` (il Mac) OR dall'interruttore «Riduci movimento» di Impostazioni (preferenza di Prisma da aggiungere, letta a caldo). In SwiftUI si espone come valore d'ambiente `\.prismaCalmo`. Il template riduce solo una parte delle animazioni (vedi `movimento/21*`, `22*`). Nel porting la regola si **estende a tutto**:
- numeri, cascate, linee, anelli, barre, blocchi mese, grafico che si allarga, finestra, dettaglio, blocco e sblocco: compaiono **già nello stato finale**, con al massimo una dissolvenza di 0,15 s (`Tema.Moto.dissolvenzaCalma`, che esiste già);
- molle (segmentato, interruttore, toast, «Ti preparo»): diventano una dissolvenza o uno spostamento lineare di 0,15 s, senza superamento;
- inclinazione, riflesso, sollevamento dei riquadri e ingrandimento del dock: **spenti**;
- sfera di Ruby: niente rotazione, respiro e pulsazione; resta il gradiente fermo;
- puntini «sta scrivendo»: fermi, all'opacità di 0,4;
- testo di Ruby: tutto insieme, dopo 0,05 s;
- «Segna come fatto»: spunta già disegnata, anello aggiornato senza brillio, scheda tolta con una dissolvenza;
- acqua: pioggia di forza 3 ogni 2,5 + rand·1,1 s, goccia al tocco di forza 10.

**Istantanee** (`Prisma --istantanee`, `\.modoIstantanea == true`): ogni componente si disegna **nello stato finale a riposo**, senza timer né `TimelineView`. I numeri mostrano il valore finale, gli anelli e le linee sono pieni, le cascate sono completate, la sfera è al fotogramma 0, il riflesso del pulsante del blocco è fuori vista, l'acqua è il fermo-immagine e non c'è nessun hover. Ogni componente animato riceve un parametro o un ambiente `fase` che le istantanee possono forzare (`.finale`); se servono, si possono aggiungere scene «a metà», come quelle del template, passando un `tempo` fisso.

**Tempo condiviso.** Le cascate e gli anelli partono da un istante comune per schermata. Proposta: un `OrologioIngresso` (`ObservableObject`, con `inizio: Date`) messo nell'ambiente dal contenitore che «monta» la schermata (finestra, dettaglio, scheda). Ogni componente calcola il proprio ritardo da `indice` e `base`, quindi non serve nessun `DispatchQueue` sparso. Si riavvia cambiando `id` alla schermata (cambio cliente, cambio scheda).

### 2.1 Numero che si conta — `NumeroCheConta`

- **Comportamento.** Parte sempre da 0 (o da `da`) e arriva al valore in `1,10 + min(i,6)·0,06` s con la quartica. Tutti i numeri della schermata partono insieme, senza ritardo: i primi 0,14-0,40 s restano coperti dalla cascata. Un nuovo valore riparte dal valore mostrato in quel momento (0,9 s). Le cifre sono tabellari.
- **API.** `NumeroCheConta(_ valore: Double, formato: FormatoCifra = .euro, indice: Int = 0, da: Double? = 0, durata: Double? = nil)`, con `FormatoCifra` = `.euro`, `.intero`, `.percentuale`, `.mesi` (virgola). Lo stile si applica fuori: `.font(Tema.Apple.Carattere.valore)`.
- **Implementazione.** Una `struct` `Animatable` che interpola un `Double`, oppure un `TimelineView(.animation)` acceso solo mentre conta. La formattazione è `FormatStyle` italiano (`Locale("it_IT")`) con il meno tipografico. **Non** si usa `contentTransition(.numericText)`: ha un effetto diverso ed esiste solo da macOS 14.
- **Riduci movimento e istantanee:** valore finale subito.
- **Riferimenti:** `movimento/01`, `03`; `posizioni-clienti/P01`, `P03`.

### 2.2 Entrata a cascata — `.entrataCascata(indice:base:)`

- **Comportamento.** Ogni blocco va da opacità 0, y +18, scala 0,985 e sfocatura 6 allo stato normale, in 0,72 s con la curva `uscita`. Il ritardo è `base + indice·0,048`. Durante il ritardo il blocco resta invisibile (`fill: backwards`). Gli indici seguono l'ordine del contenuto: dall'alto in basso, da sinistra a destra.
- **API.** `func entrataCascata(_ indice: Int, base: Double = Tema.Apple.Moto.Cascata.baseFinestra) -> some View`. In alternativa, un contenitore `Cascata { … }` che numera i figli con un `Layout` (macOS 13 ok) o con `_VariadicView`. Proposta: indici espliciti, più leggibili.
- **Varianti.** `.entrataLaterale(indice:)` (impegni, x +30) e `.entrataNotifica(indice:)` (x +20, 0,4 s).
- **Prestazioni.** `.blur(radius:)` su molte viste costa sul M1 da 8 GB. Si applica solo durante l'animazione (raggio 0 = nessun filtro: con `if raggio > 0` si toglie il modificatore) e con `.compositingGroup()` sul blocco.
- **Riferimenti:** `movimento/01-cascata-meta-260ms`, `19-scrivania-cascata-meta`; `posizioni-clienti/C08`; `analisi-agenda/A01`.

### 2.3 Anelli — `AnelliConcentrici` e `Anello`

- **Geometria.** Lo spessore predefinito è `misura·0,09`. Il passo tra gli anelli è `spessore·1,22`. Il raggio è `R_i = misura/2 − spessore/2 − i·passo`. Il binario è dello stesso colore al 15%. Le estremità sono arrotondate, il disegno parte da ore 12 in senso orario.
- **Comportamento.** Il riempimento cresce da 0 alla frazione in 1,4 s con la curva `uscita`, con ritardo `d + i·0,13`. Un nuovo valore anima dal valore attuale con la stessa curva (anche il cursore della previdenza lo «insegue»). Il brillio è un'ombra di raggio 10 nel colore dell'anello per 0,9 s.
- **API.**
  ```swift
  struct VoceAnello: Identifiable { let id: String; var valore: Double; var massimo: Double = 100; var colore: Color }
  AnelliConcentrici(voci: [VoceAnello], misura: CGFloat, spessore: CGFloat? = nil,
                    ritardo: Double = 0.32, brilla: String? = nil) { centro }
  Anello(frazione:, colore:, misura:, spessore:, ritardo:) { Text("52%") }   // singolo
  ```
  Si disegna con `Circle().trim(from: 0, to: frazioneAnimata).stroke(colore, style: StrokeStyle(lineWidth:, lineCap: .round)).rotationEffect(.degrees(-90))`.
- **Misure usate (misura/spessore).** Scrivania 118/12. Posizioni 190/16. Completezza 120/13. Obiettivi 150/15. Dettaglio obiettivo 220/22. Aree di Analisi 360 170/17. Previdenza e protezione 210/20. Backup 110/12. Carta «Obiettivo casa» 170/18 (fermo).
- **Riduci movimento e istantanee:** frazione finale subito, nessun brillio.
- **Riferimenti:** `movimento/02`, `11`, `15`; `shell/03`.

### 2.4 Linea che si disegna — `TracciatoGrafico`

- **Comportamento.** La linea si disegna da sinistra a destra in 1,5 s con la curva `uscita`, ritardo `0,15 + i·0,12`. L'area sotto e i punti compaiono in 0,9 s dopo 0,6 s.
- **Correzione del template.** Le linee di stima vanno tratteggiate anche dopo il disegno. In SwiftUI si usa `path.trim(from: 0, to: p).stroke(style: StrokeStyle(lineWidth:, lineJoin: .round, dash: [6, 6]))`, così il tratteggio resta.
- **API.** `TracciatoGrafico(punti: [CGPoint] (normalizzati 0…1), colore:, spessore:, tratteggio: [CGFloat]? = nil, area: Bool, indice: Int)`. Si compone in `GraficoAndamento` (già presente in `ComponentiAndamento.swift`: da estendere, non duplicare).
- **Riduci movimento e istantanee:** linea intera, area visibile.
- **Riferimenti:** `movimento/13`, `14` (il difetto); `posizioni-clienti/C17`, `C18`.

### 2.5 Grafico «In essere / Con le proposte» — `GraficoPortafoglio(progresso:)`

- Un solo parametro `p` (da 0 a 1) controlla tutto, interpolato in 0,9 s con la quartica:
  - l'asse x va da 11 a `11 + 6p` mesi e la storia si comprime a sinistra;
  - il massimo y va da 1130 a `1130 + 55p` (migliaia);
  - la fascia viola ha opacità `0,13·p`, bordo sopra `v + i·4,2` e sotto `v − i·3,6`;
  - la stima viola è tratteggiata `5 6`, spessore 2,4, opacità `p`;
  - il punto finale ha raggio 5 con bordo bianco 2,5;
  - l'etichetta «stima giugno 2027» è 12 semibold viola, allineata a destra, 8 a sinistra e 11 sopra il punto;
  - le etichette dei mesi sono una ogni 2 e diventano una ogni 3 quando `p > 0,5`, a scatto.
- Il grafico è grande 818×92. La linea della storia è `#0A84FF`, spessore 2,6. L'area è un gradiente `#0A84FF` da .22 a 0. I mesi sono a 11 pt, 15 pt sotto il grafico.
- **API.** `GraficoPortafoglio(storia: [Double], stima: [Double], progresso: Double)`, con `progresso` come `animatableData`. Si disegna con `Canvas` (una sola vista, leggero).
- **Riferimenti:** `posizioni-clienti/P02`, `P03`, `P04`; `movimento/03`, `04`.

### 2.6 Scheda che si inclina — `.inclinazione(massimo:)`

- **Comportamento.** Con `x, y` del puntatore normalizzati da 0 a 1:
  - rotazione X = `(0,5 − y)·m·0,8`°;
  - rotazione Y = `(x − 0,5)·m`°;
  - sollevamento y −5 e scala 1,02;
  - prospettiva 900.
- L'inseguimento del puntatore è smorzato con la molla da 0,5 s. All'uscita la scheda torna piatta con la stessa molla. Al passaggio l'ombra diventa `inclinata` (0,4 s). Il riflesso radiale 260×200 segue il puntatore (bianco .6 con fusione `softLight` in chiaro, .16 normale in scuro) e compare in 0,3 s. Le schede già «fatte» non si inclinano.
- **API.** `func inclinazione(massimo: Double = 10, raggio: CGFloat = Tema.Apple.Raggio.card) -> some View`. Usa `onContinuousHover` (macOS 13 ok) e `GeometryReader` per la posizione relativa.
- **Prospettiva esatta.** `rotation3DEffect(_:axis:anchor:anchorZ:perspective:)` ha una prospettiva normalizzata, non in punti. Per la prospettiva di 900 serve `projectionEffect(ProjectionTransform(CATransform3D))` con `m34 = −1/900`, applicata attorno al centro. È un `GeometryEffect` animabile su (rx, ry).
- **iPhone e iPad:** niente inclinazione al passaggio; al tocco, scala 0,98.
- **Riduci movimento e istantanee:** spenta.
- **Riferimenti:** `movimento/05`, `05b`; `posizioni-clienti/P05`, `C07`, `C20`; `analisi-agenda/A03`, `G07`; `shell/13` (riquadro −3).

### 2.7 Dettaglio che nasce dall'elemento — `PresentatoreDettaglio` e `.origineDettaglio(id:)`

- **Comportamento.**
  - L'elemento toccato si nasconde e al suo posto si apre un contenitore pieno (`cardPiena`, bordo, `ombraDettaglio`, raggio 22). Il contenitore anima posizione e misure verso un rettangolo W×H centrato nell'area contenuto della finestra (x = (larghezza − W)/2, y = 92 + (area − H)/2) e porta il raggio a 28, in 0,62 s con la curva `(0.32,1.22,0.5,1)`.
  - Il contenuto ha da subito la misura finale W×H, è ancorato in alto a sinistra e ritagliato. Compare con opacità 0 → 1 in 0,35 s, a partire da 0,33 s. A 0,17 s partono i numeri, gli anelli (ritardo 0,12), le linee e le barre del contenuto.
  - Il velo (`velo` + sfocatura 10) entra in 0,45 s.
  - Chiusura con ✕, Esc o un clic sul velo: il contenitore torna al rettangolo **attuale** dell'origine (rimisurato) in 0,46 s con `(0.32,1.08,0.5,1)`, il contenuto svanisce in 0,2 s, poi l'origine ricompare e parte una callback (es. «Segna come fatto»). La chiusura «subito» (cambio app, blocco, «Apri il dossier») avviene senza animazione. Si apre un solo dettaglio alla volta.
- **Misure W×H.** Predefinito 900×540; scheda «Da fare» 880×520; obiettivo 920×520; Previdenza e Protezione 940×540; Investimenti 900×480; Liquidità 900×440; impegno 860×500.
- **Implementazione.** **Non** `matchedGeometryEffect`: il contenuto non deve rifluire mentre il contenitore cresce. Si usa un rettangolo animabile (`AnimatablePair` di origine e misura, più il raggio) dentro uno spazio di coordinate `.named("finestra")`. L'origine si legge con `anchorPreference` o con un `GeometryReader` registrato per `id` in un `@StateObject RegistroOrigini`. Il contenuto è `.frame(width: W, height: H, alignment: .topLeading)` dentro un `.clipShape(RoundedRectangle(cornerRadius: raggioAnimato))`.
- **API.**
  ```swift
  .origineDettaglio(id: "task-marco")                       // sull'elemento toccabile
  PresentatoreDettaglio(stato: $dettaglio) { id in … }       // nella finestra, sopra il contenuto
  final class StatoDettaglio: ObservableObject {
      func apri(_ id: String, misura: CGSize = .init(width: 900, height: 540))
      func chiudi(subito: Bool = false, poi: (() -> Void)? = nil)
  }
  ```
- **Riduci movimento:** il contenitore appare già al centro, con una dissolvenza di 0,15 s e il contenuto subito visibile. **Istantanee:** il dettaglio aperto, a misura piena.
- **Riferimenti:** `movimento/06`, `06b`, `07`; `posizioni-clienti/P07`, `P08`, `C10`, `C11`; `analisi-agenda/A06`, `A16`, `G08`.

### 2.8 Segmentato a pillola — `SegmentatoPillola`

- **Aspetto.** Contenitore `chip` a capsula con padding 3. Voci 13 semibold con padding 6×14. Colore `inchiostro2`, `inchiostro` per la voce attiva (0,3 s). La pillola è `cardPiena` con ombra `pillola`. Si sposta e cambia larghezza in 0,5 s con la molla. Un clic sulla voce attiva non fa nulla.
- **API.** `SegmentatoPillola(selezione: Binding<T>, voci: [(T, String)], larghezzaPiena: Bool = false, icona: ((T) -> AnyView)? = nil)`. La variante con avatar serve ai clienti di Analisi 360; `larghezzaPiena` alla settimana dell'Agenda (7 voci di uguale larghezza).
- **Implementazione:** `matchedGeometryEffect(id: "pillola", in: ns)` (macOS 13 ok), con l'animazione `Tema.Apple.Moto.segmentato`.
- **Riferimenti:** `movimento/03`, `18`; `analisi-agenda/A04`, `G03`.

### 2.9 Interruttore — `StileInterruttoreApple: ToggleStyle`

- **Aspetto.** 44×26 a capsula. Spento `binario`, acceso `#34C759` (0,3 s). Manopola bianca 20 con ombra, x da 3 a 21 in 0,35 s con la molla.
- **API.** `Toggle(isOn:) { … }.toggleStyle(.apple)`.
- **Riferimenti:** `movimento/17`, `18`; `prospetti-impostazioni-ruby/i01`, `i02`.

### 2.10 Cursore — `CursoreApple`

- **Aspetto.** Binario 6 (raggio 9, `binario`), senza parte riempita. Manopola bianca 28 con ombra `manopolaCursore`, bianca anche in scuro. Nessuna animazione propria: i valori collegati cambiano subito, gli anelli collegati inseguono con la loro curva.
- **API.** `CursoreApple(valore: Binding<Double>, intervallo: ClosedRange<Double>, passo: Double)`. È una vista propria con `DragGesture`: lo `Slider` di macOS non si può ridisegnare. Si regola anche con le frecce della tastiera (accessibilità: `accessibilityAdjustableAction`).
- **Riferimenti:** `movimento/16`; `posizioni-clienti/C12`, `C13`, `C14`; `analisi-agenda/A08`, `A09`, `A10`, `A14`, `A15`.

### 2.11 Barra che si riempie — `BarraPiena`

- **Aspetto.** Alta 8, raggio 9, fondo `binario`. Il riempimento va da 0 alla frazione in 1,2 s con la curva `uscita`, ritardo `0,15 + i·0,09`.
- **API.** `BarraPiena(frazione:, colore:, indice:, altezza: 8)`.
- **Varianti.** `BarraCanali(alleanza: 47, indipendente: 53)` (larga 520, spazio 3, colori dei canali) e `BarraComposizione(pezzi:)` (alta 22, raggio 12, spazio 3, pezzi con raggio 6, ritardi 0,15 / 0,24 / 0,33 / 0,42).

### 2.12 Spunta che si disegna — `SpuntaDisegnata`

- **Aspetto.** Disegno 72×72: cerchio di raggio 30 con tratto 4 `#2FA35A`, da ore 12, in 0,5 s; segno `M23 37 l9 9 l17 −19` con tratto 5, estremità tonde, in 0,35 s dopo 0,35 s. Velo verde `rgba(47,163,90,.16)` sulla scheda in 0,4 s.
- **API.** `SpuntaDisegnata(progresso: Double)`, con due `trim`.
- **Riferimenti:** `movimento/10`; `posizioni-clienti/P11`.

### 2.13 Lista «Ti preparo» — `ListaTiPreparo`

- **Aspetto.** Righe 13,5 con padding 9 e filetto `separatore`. Cerchietto 20 con bordo 2 `binario`. Quando la voce è fatta il cerchietto si riempie di `#2FA35A`, scala a 1,08 e mostra la spunta bianca, con la molla di 0,35 s.
- **Ritmo.** Voce i a `0,22 + i·0,36` s; toast «Fascicolo per <nome> pronto in Prospetti» a `0,32 + n·0,36` s.
- **API.** `ListaTiPreparo(titolo: "Ti preparo", voci: [String], avviata: Bool, poi: () -> Void)`. Nell'app la lista deve riflettere lavoro vero: le voci si spuntano quando il motore ha davvero preparato il fascicolo. Il ritmo da 0,36 s è un minimo visivo.
- **Riferimenti:** `movimento/08`, `09`; `posizioni-clienti/P09`, `P10`; `analisi-agenda/G10`, `G11`.

### 2.14 «Segna come fatto» — sequenza `SequenzaFatto`

1. Il dettaglio si chiude (0,46 s).
2. t0: spunta e velo verde (§2.12).
3. t0 + 0,6: l'anello collegato sale di 1, la legenda conta in 0,9 s, l'anello brilla per 0,9 s e il testo diventa «<anello>: N su MAX.».
4. t0 + 1,15: la scheda si stringe (larghezza 0, margine −14, scala 0,85, opacità 0) e le altre scorrono al suo posto; toast «<nome>: fatto».
5. t0 + 1,71: la scheda viene tolta, i conteggi si aggiornano, un gruppo rimasto vuoto si chiude (larghezza 0 in 0,5 s) e il nastro si riallinea in 0,7 s.

- **Implementazione.** `withAnimation` più `Movimenti.dopo(_:)` per i passi successivi. Per far scorrere le altre schede, la scheda tolta passa a `frame(width: 0)` con la molla dentro un `HStack`, e poi esce dal modello.
- **Riferimenti:** `movimento/10`, `11`, `12`; `posizioni-clienti/P11`, `P12`, `P13`.

### 2.15 Toast — `.avvisoToast`

- **Aspetto.** Capsula `#0F2433` al 92% con testo bianco 13 e padding 9×16, centrata a 44 dall'alto della scena (10 sotto la barra). Entra da y −20 con la molla di 0,45 s, resta 2,4 s ed esce allo stesso modo.
- **API.** `StatoShell.avvisa(_ testo: String)` (un solo toast alla volta: il nuovo sostituisce il vecchio).
- **Riferimenti:** `posizioni-clienti/C16`; `analisi-agenda/A12`, `G06`; `prospetti-impostazioni-ruby/p07`, `p08`, `r01`.

### 2.16 Pulsante — `StilePulsanteApple: ButtonStyle`

- `.apple` (`cardPiena` con bordo `separatore`), `.applePrimario` (`#007AFF`, testo bianco), `grande: Bool` (padding 10×18, 13,5).
- Premuto: scala 0,95 con molla di 0,25 s. Hover: luminosità 0,97 (con `onHover`).
- `.appleVetro`: pulsanti della scrivania su `vetro` (Nuovo cliente, Cerca ovunque).

### 2.17 Etichetta del canale — `EtichettaCanale(canale:, compatta:)`

- Capsula 11,5 semibold con padding 3×9, pallino 6 nel colore del testo e spazio 5. Alleanza: fondo `rgba(37,99,235,.13)`, testo `canaleAlleanza`, «Alleanza» (con il logo Alleanza, come chiede CLAUDE.md). Indipendente: fondo `rgba(176,110,18,.14)`, testo `canaleIndipendente`; nella versione estesa la scritta è «Denis Vicenzoni · Consulenza finanziaria».
- Riusa e aggiorna il componente che esiste già: non se ne crea un secondo.

### 2.18 Sfera di Ruby — `SferaRuby(misura:, viva:, pensa:)`

- Gradiente radiale `sfera` con ombra `sfera`. Sopra, il riflesso conico (`AngularGradient`) con margine −30%, fusione `overlay`, che ruota in 6 s lineare.
- `viva`: respiro di 4 s (scala 1,045 e alone azzurro a metà ciclo).
- `pensa`: due pulsazioni da 1 a 1,1 in 0,9 s ciascuna, al posto del respiro.
- Misure: 24 (barra), 46 (riquadro), 120 (Ruby). La sfera «MB» della mossa usa `sferaMossa` (88, con le iniziali, senza respiro).
- Le animazioni vanno con `TimelineView(.animation(minimumInterval: 1/30))`, e solo quando la sfera è visibile: tre sfere sempre accese costano.
- **Riduci movimento e istantanee:** ferma.
- Sostituisce o affianca `SferaAcquaRuby.swift`: è una scelta da fare (vedi §5.1).

### 2.19 Puntini «sta scrivendo» — `PuntiniScrittura`

Tre cerchi da 7 pt (`inchiostro3`), distanziati di 4. Il ciclo dura 1 s, sfasato di 0,15 s tra un cerchio e l'altro: al 30% del ciclo il cerchio sale di 5 e ha opacità 1; per il resto del ciclo ha opacità 0,4.

### 2.20 Testo parola per parola — `TestoProgressivo(testo:, passo: 0.038)`

Le parole si aggiungono una alla volta, ogni 0,038 s, senza dissolvenza; a ogni passo la chat scorre in fondo. In Prisma il testo arriva in streaming da Qwen: il passo da 0,038 s fa da ritmo minimo di presentazione, non da finta scrittura.

### 2.21 Nastro orizzontale — `NastroSchede`

- Maschera ai bordi: 30 pt sfumati a sinistra e 60 a destra.
- Spostamento con un `offset` animato in 0,7 s con la curva `uscita`, frecce di ±500, rotella e trackpad (deltaX o deltaY), limiti `0…larghezzaContenuto − larghezzaVista`.
- Su macOS 13 manca `scrollPosition` (§5.3): si usa un offset proprio con `onScroll` via `NSEvent` monitor, oppure `ScrollView(.horizontal)` con `ScrollViewReader.scrollTo` per le frecce. Si sceglie l'offset proprio, che rende la curva esatta.

### 2.22 Blocchi dei mesi — `BlocchiMesi(mesi: Double, soglia: 6)`

12 blocchi con spazio 6, alti 90, raggio 12. Un mese pieno è `#30B15C`; il mese parziale ha un gradiente verde fino alla frazione; i mesi vuoti sono `binario`. Entrano da scala y 0,2 e opacità 0 con la molla di 0,5 s, ritardo `0,2 + i·0,06`, ancorati al centro.

### 2.23 Pagina che cambia — `.cambioPagina(direzione:)`

È una `transition` asimmetrica:
- uscita: scala da 0,70 a 0,68, y −dir·30, opacità 0, in 0,18 s ease-in;
- entrata: da scala 0,68, y +dir·40 a scala 0,70, in 0,52 s con la curva `uscita`.

In sala: `x ∓120` / `±160`, scala 0,85 ↔ 0,88, 0,22 s e poi 0,52 s. Su macOS 13 una transizione asimmetrica con ritardo funziona (`.asymmetric(insertion:removal:)` con `.animation` dentro la transizione da `.animation(_:)` su `AnyTransition`, ok da macOS 10.15).

### 2.24 Anello del backup — `AnelloAvanzamento`

L'anello 110/12 verde si riempie in 1,6 s con `(0.4,0,0.2,1)`. A 1,7 s compare la ✓ (da scala 0,3 con molla di 0,5 s). Nell'app l'anello segue l'avanzamento vero di `--prova-backup`/backup: 1,6 s è la durata minima mostrata.

---

## 3. Shell e scrivania

### 3.1 Livelli (dal basso)

Acqua < scrivania < finestra < velo e dettaglio (dentro la finestra) < barra = dock < notifiche < blocco < toast < sala della presentazione.

In SwiftUI è uno `ZStack` in `Shell/` con `zIndex` espliciti: `Tema.Apple.Livello.acqua = 0`, `scrivania 5`, `finestra 20`, `barra 50`, `dock 50`, `notifiche 60`, `blocco 90`, `toast 95`, `sala 96`.

### 3.2 Blocco (schermata di benvenuto)

**Riferimenti:** `shell/01-blocco`, `02-sblocco-260ms`, `14-blocca-200ms`.

- **Composizione.** Velo `veloBlocco` con sfocatura 3, colonna centrata in `inchiostroAcqua`, dall'alto:
  - logo vettoriale 40 a 70 dall'alto (`LogoPrisma`, spicchi a opacità 1 / .66 / .38);
  - ora `oraBlocco` 150 sotto («23:08», aggiornata ogni 15 s);
  - data 22 medium all'80%, 10 sotto;
  - pulsante di vetro «Tocca per entrare in Prisma» a 70 dal fondo (padding 12×22, 14 semibold), con il riflesso `luce` in ciclo da 2,6 s.
- **Sblocco** (clic ovunque):
  - il velo sale di 60, scala a 1,04, si sfoca di 8 e svanisce in 0,65 s con `(0.5,0,0.3,1)`;
  - nello stesso istante cade una goccia al centro dell'acqua (forza 90, raggio 6 celle) e la barra compare in 0,6 s;
  - a +0,2 s il dock risale da +140 con la molla di 0,7 s;
  - se non c'è un'app aperta, parte la cascata della scrivania (§3.6).
- **Blocco** (lucchetto, riposo del Mac, schermo spento, come oggi): il velo scende da −30 in 0,5 s con la curva `uscita`, la barra svanisce e il dock scende. Si chiudono dettaglio e sala.
- In chiaro all'avvio sotto il blocco c'è solo l'acqua; quando il blocco viene richiamato, sotto si vede la scrivania sfocata.

### 3.3 Barra superiore

**Riferimenti:** `shell/03`, `09`.

- Alta 34, con padding 12 ai lati, testo 13 semibold `inchiostroAcqua`. Non ha un fondo proprio: ogni gruppo è una capsula di `vetro`.
- **Sinistra:**
  - pillola logo 15 + «Prisma» (padding 5×11, spazio 7), che porta alla scrivania;
  - pillola con il nome dell'app in primo piano.
- **Centro:** orologio «lun 2 nov   HH:MM», peso 500, tabellare.
- **Destra** (spazio 6):
  - «⌕ Cerca ⌘K» (⌘K al 50%);
  - sfera di Ruby viva 24 in un tasto da 28;
  - campanella da 28 con badge «3» (`#FF3B30`, 9 bold, a −3/−4);
  - lucchetto da 28;
  - avatar «DV» da 28.
- Le icone emoji del template (🔔 🔒) diventano SF Symbols (`bell`, `lock`), come fa già `BarraSuperiore.swift`.

### 3.4 Dock

**Riferimenti:** `shell/03`, `06-dock-ingrandito`.

- **Composizione.** Capsula di vetro con raggio 26, padding `8 10 5`, spazio 4, a 8 dal fondo, voci allineate in basso. Le voci sono larghe 62 e hanno l'icona da 50, il nome in 10,5 medium e un pallino da 4 sotto la voce attiva (0,3 s).
- **Voci del template**, in ordine: Scrivania, Clienti, Posizioni, Analisi 360, Agenda, Prospetti, Ruby, Impostazioni. In Prisma restano le voci e le regole di `AppPrisma.delDock`: Posizioni subito dopo Clienti, e le app ospitate (Obiettivi, Documenti, Simulazioni, Confronti, Attività) non hanno una voce propria.
- **Ingrandimento.**
  - Si calcola `d = |x − centro voce|`, poi `s = 1 + 0,36·max(0, 1 − d/130)`.
  - L'icona diventa `50·s` (al massimo 68) e la voce `62·(1 + (s − 1)·0,7)`. La transizione è di 0,14 s e il dock cresce verso l'alto.
  - Anche la data dell'Agenda si ingrandisce:
    - «NOV» 8·s bold `#E5484D`, a `9 + 50(s−1)·0,2`;
    - il giorno 21·s medium `#222`, a `17 + 50(s−1)·0,34`.
  - Si fa con `onContinuousHover` sul dock e la x di ogni voce da `GeometryReader`.
  - È spento con Riduci movimento, nelle istantanee e su iPhone e iPad.
- **Rimbalzo** a ogni clic: y −16, 0, −7, 0 in 0,7 s ease-out (`keyframeAnimator` non c'è su macOS 13: si usa un `Animatable` con fase da 0 a 1 e una funzione a tratti).

### 3.5 Finestra

**Riferimenti:** `shell/07-finestra-apre-150ms`, `08-…-300ms`, `09-finestra-aperta`, `10-finestra-chiude-300ms`.

- **Struttura.**
  - Una finestra interna sola, a 16 dai lati, da y 42 a 100 dal fondo; nel palco del template misura 1408×758. È di vetro `finestra`, ha raggio 24 e l'ombra `finestra`.
  - Barra del titolo da 38 (padding 0×18):
    - semafori 12 (`#FF5F57`, che al passaggio mostra «×» `rgba(80,0,0,.7)`; `#FEBC2E` = chiudi; `#28C840` senza azione);
    - icona dell'app 20 (per l'Agenda il giorno in 10 semibold `#222` a 5 dall'alto);
    - titolo 14 semibold;
    - a destra una nota 13 medium `inchiostro2` (es. Ruby «Qwen sul Mac · tutto resta qui»).
  - Intestazione da 54: titolo 17 bold, sottotitolo MAIUSCOLO 12 medium, azioni a destra con spazio 6.
  - Contenuto a 12 dai bordi.
- **Titoli per app (titolo grande / sottotitolo):**
  - Clienti «Le tue relazioni.» / «Rubrica Prisma»
  - Posizioni «Il portafoglio.» / «35 clienti · aggiornato adesso»
  - Analisi 360 «Analisi 360.» / «Previdenza, protezione, investimenti, risparmio»
  - Agenda «Spazio alle relazioni.» / «Novembre 2026»
  - Ruby «Ruby» / «Assistente personale»
  - Prospetti «Prospetti e report.» / «Il dettaglio per te, l'essenziale per il cliente»
  - Impostazioni «Impostazioni.» / «Il tuo modo di lavorare»

  Il mese e il numero di clienti vanno calcolati dai dati, non scritti fissi.
- **Apertura dall'icona:**
  - la finestra parte dal rettangolo dell'icona nel dock, con scale x e y separate e opacità 0,2;
  - è opaca al 35% del tempo e arriva a misura piena in 0,6 s con `(0.3,1.12,0.5,1)`;
  - insieme la scrivania scende a opacità 0,25 (0,5 s) e smette di ricevere i clic;
  - il contenuto entra con una dissolvenza lineare di 0,2 s e la cascata (base 0,14);
  - numeri, anelli a 0,32, linee e barre partono insieme.

  In SwiftUI è uno `scaleEffect(x:y:anchor: .topLeading)` più un `offset`, animati con un `GeometryEffect` sui due rettangoli.
- **Cambio app con la finestra aperta:** il contenuto esce in 0,15 s ease-in (scala 0,985), poi entra la nuova app. La finestra resta ferma; cambiano titolo, icona e pallino del dock, e l'icona rimbalza.
- **Chiusura** (rosso, giallo, Esc, clic su Scrivania o sul logo): la finestra rientra nell'icona in 0,48 s con `(0.5,0,0.3,1)` e svanisce solo nell'ultimo 40%.
- **Clic durante un'animazione:** si ignorano finché la finestra non si ferma (`busy`).

### 3.6 Scrivania

**Riferimenti:** `shell/03-scrivania`, `13-riquadro-hover`, `movimento/19`, `20`.

- **Riquadri.** Sono di `vetro` con raggio 26 e padding 18×20. Al passaggio salgono di 3 con la molla di 0,45 s. Ognuno apre la propria app.
- **Disposizione** (palco 1440×900; margini 44, colonne a 16). In Prisma va resa con un `Layout` o una griglia proporzionale, non con coordinate fisse.
  1. **Saluto** a 44/48: «Buongiorno / Buon pomeriggio / Buonasera, Denis.» 38 bold (prima delle 13, prima delle 18, poi), sotto «Tutto il tuo lavoro, a portata di mano.» 15 `inchiostroAcqua2`.
  2. **Pulsanti di vetro** in alto a destra (a 44 dal bordo, 64 dall'alto, spazio 8): «Nuovo cliente», «Cerca ovunque».
  3. **La mossa del giorno** (larghezza piena, alta 148, padding 20×24, spazio 22):
     - sfera «MB» 88;
     - etichetta `#1D6FC4`;
     - titolo «Chiama Marco Bianchi» 25 bold;
     - corpo 14,5 `inchiostro2`, largo al massimo 720;
     - pulsanti «✦ Preparami l'incontro» (primario, grande) e «Apri il dossier».
  4. **Riga di tre riquadri alti 300:**
     - **Agenda di oggi** (560 di larghezza):
       - colonna da 120 con bordo destro: «Lunedì» `#E5484D`, «2» 76 light, «novembre»;
       - in basso «4 impegni oggi» (numero che conta) e «il prossimo alle 09:30»;
       - a destra «Prossimi incontri» con 4 righe a barra sinistra da 3 nel colore dell'evento.
     - **Portafoglio clienti** (384 di larghezza):
       - totale 36 bold che conta;
       - «in essere · 35 clienti seguiti»;
       - tre anelli concentrici 118/12 (32/35, 26/35, 9/15) e la legenda 12,5 con interlinea 2.
     - **Ruby:**
       - sfera viva 46, «Ruby», «Qwen sul Mac · pronto»;
       - frase 19 semibold;
       - suggerimenti a capsula (padding 8×14, 13 medium, `card`, sollevamento −2): un clic apre Ruby e manda la domanda dopo 0,7 s.
  5. **Riga di due riquadri alti 168:**
     - **Da fare oggi** (660 di larghezza): 3 righe 13,5 con interlinea 2, con «○» e cliente in `inchiostro3`.
     - **In scadenza entro 90 giorni:** due righe, ognuna con un blocco data largo 40 («DIC» 10 bold rosso, «17» 21 semibold), il testo e l'etichetta del canale.
- **Ingresso dopo lo sblocco:**
  - cascata degli 8 blocchi con base 0,12 (l'ultimo finisce a circa 1,18 s);
  - a +0,30 s i numeri iniziano a contare;
  - gli anelli partono a 0,60 / 0,73 / 0,86 s.
- **Ingresso senza animazione:** numeri subito, anelli a 0,20 / 0,33 / 0,46 s (§0, punto 3).
- **Clic sul fondo libero:** fa cadere una goccia sull'acqua (§3.7).

### 3.7 Acqua

**Riferimenti:** `shell/04-goccia-clic-350ms`, `05-…-1250ms`, `02-sblocco-260ms`.

- **Simulazione del template** (canvas 2D, non WebGL):
  - griglia d'onda a celle di 5 pt (290×182) con due buffer;
  - a ogni passo `h' = ((N + S + E + O)·0,5 − h_prec)·0,986`, a 50 passi al secondo (al massimo 2 per fotogramma);
  - luce `l = ((h[x+1] − h[x−1])·0,8 − (h[y+1] − h[y−1])·1,2)·k`, con k = 2,4 in chiaro e 1,6 in scuro;
  - riflesso `(l − 6)·2` quando l > 6;
  - colore = gradiente di base + l (blu + 0,8·l) + riflesso;
  - l'immagine viene ingrandita con interpolazione morbida.
- **Colori di base:**
  - chiaro: R 228−34t, G 239−22t, B 245−14t (da `#E4EFF5` a `#C2D9E7`);
  - scuro: R 14+6t, G 30+8t, B 42+10t (da `#0E1E2A` a `#142634`).
- **Gocce:**
  - avvio: 40 gocce (forza 8, raggio 1) e 30 passi già calcolati;
  - pioggia: forza 9 ogni 0,7 + rand·1,1 s;
  - clic: forza 32, raggio 3;
  - sblocco: forza 90, raggio 6.
- **«L'acqua della scrivania» spento:** l'immagine si congela.
- **Porting.** Le regole di CLAUDE.md restano tutte valide: Metal, fuori dal thread principale, CVDisplayLink, ferma quando la finestra non si vede, 20 fps in risparmio energetico, fermo-immagine nelle istantanee, stessa acqua su iPhone e iPad. Cambia solo il **modello visivo**: la griglia d'onda 290×182 (52 mila celle) va in un kernel di calcolo Metal (o su CPU nella coda propria: 52k celle × 50 passi = 2,6 M operazioni al secondo, trascurabili). L'ombreggiatura sta nel fragment shader che campiona la texture d'altezza con filtro lineare. Si veda la decisione 2 in fondo.

### 3.8 Notifiche

**Riferimenti:** `shell/11-notifiche-150ms`, `12-notifiche`.

- **Pannello.** Di vetro, largo 360, raggio 22, padding 14, a 12 dal bordo destro e 40 dall'alto. Intestazione «Notifiche» 15 bold e «3 nuove».
- **Voci.** Padding 10, raggio 14, fondo `card`, distanza 8 tra una voce e l'altra, testo 13 con interlinea 1,4. Pallino 8 rosso, arancio o blu; nome in grassetto e testo `inchiostro2`. Un clic chiude il pannello e apre l'app collegata.
- **Apertura:** il pannello scende da y −10, scala 0,97, in 0,38 s con la molla; le voci entrano da x +20 in 0,4 s con la curva `uscita`, ritardo 0,08 + i·0,07.
- **Chiusura:** immediata (seconda pressione, clic altrove, Esc, scelta di una voce). Nel porting si propone un'uscita di 0,14 s, come `Tema.Moto.Pannelli.notificheUscita` di oggi.

### 3.9 Toast

Vedi §2.15. È uno solo per tutta la shell, sopra il blocco e sotto la sala.

### 3.10 Tastiera

- Esc chiude nell'ordine: sala → dettaglio → notifiche → finestra.
- ← → girano le pagine solo in sala.
- ⌘K apre la Ricerca: in Prisma è quella vera (`ComponentiRicerca.swift`), non il toast del template.
- Su macOS 13 `onKeyPress` non c'è: si usa il monitor `NSEvent` già presente nella shell, o `.keyboardShortcut` sui pulsanti nascosti.

---

## 4. Le app, schermata per schermata

Le cartelle dei riferimenti si abbreviano così: **PC** = `shots/posizioni-clienti/`, **AA** = `shots/analisi-agenda/`, **PIE** = `shots/prospetti-impostazioni-ruby/`, **MO** = `shots/movimento/`.

### 4.1 Posizioni (il fulcro)

**Area del contenuto:** 1384×654.

**4.1.1 Schermata principale** — PC `P01` (entrata), `P02` (a riposo); MO `02`.

- **Card del portafoglio** (870×296, padding 22×26):
  - **Testata:** `.lbl` «Portafoglio clienti» e il segmentato «In essere | Con le proposte».
  - **Totale:** `numeroGrande` 62 (1.124.350 €).
  - **Delta**, a destra, staccato di 7 pt dal fondo: verde 15 semibold «+38.200 € da gennaio» e, sotto, «35 clienti · 6 proposte aperte».
  - **Barra dei canali** (520): Alleanza 47 / indipendente 53, ritardi 0,15 e 0,24. Sotto: etichetta Alleanza + 529.950 €, etichetta indipendente + 594.400 € (numeri che contano).
  - **Grafico** 818×92 (§2.5) a 26 dal bordo sinistro e 30 dal fondo.
- **«Lo stato del tuo lavoro»** (498×296, padding 22×24):
  - anelli 190/16:
    - «Clienti in regola» 32/35 `#30B15C`;
    - «Riesami dell'anno» 26/35 `#0A84FF`;
    - «Proposte concluse» 9/15 `#8B5CF6`;
    - partono a 0,32 / 0,45 / 0,58 s.
  - legenda: pallino 10, nome 14, numero 20 bold che conta, «su 35» 13; righe separate da filetti;
  - testo «Chiudi le cose da fare qui sotto: gli anelli si riempiono.».
- **Nastro «Da fare, in ordine di tempo»** (§2.21), a y 314:
  - testata: `.h2` e il conteggio «8 cose · 3 oggi»; frecce da 32;
  - gruppi larghi 112 («Oggi», «Questa settimana», «Questo mese», «Più avanti»), titolo 22 bold e conteggio;
  - schede 232×270, raggio 22, fondo `card`, ombra `card`, inclinazione 10. Ogni scheda ha:
    - una fascia superiore di 4 pt nel tono (rosso, arancio o verde);
    - «quando» 12 bold MAIUSCOLO nel tono;
    - «perché» 19 bold;
    - le etichette dei canali;
    - il cliente: avatar 34, nome 13,5 bold, patrimonio 12.
- **Canale.** Ogni scheda e ogni posizione mostra sempre l'etichetta del canale. È una regola di CLAUDE.md, e il template la rispetta.

**4.1.2 «Con le proposte»** — PC `P03` (a 420 ms), `P04`; MO `03`, `04`.
- Il totale conta da 1.124.350 a 1.170.914 € in 0,9 s.
- Il delta diventa viola: «+46.564 € con le 6 proposte aperte» e, sotto, «se le proposte vanno in porto · stima a giugno 2027».
- Il grafico si allarga (§2.5). Il ritorno a «In essere» fa il percorso inverso.

**4.1.3 Nastro che scorre** — PC `P06`. Freccia › = +500, con la curva `uscita` in 0,7 s.

**4.1.4 Scheda al passaggio** — PC `P05`; MO `05`, `05b`.

**4.1.5 Dettaglio della scheda** (880×520) — PC `P07` (a 250 ms), `P08` (Marco), `P14` (Giulia); MO `07`.
- **Testata:** avatar 54, `.lbl` nel tono («OGGI»), nome 26 bold; a destra le etichette dei canali, con 56 pt di margine per la ✕.
- **Perché** 22 bold (al massimo 760) e spiegazione 14,5 `inchiostro2`.
- **Colonna sinistra** (1,1):
  - tre `.v` che contano: Patrimonio, Capitale assicurato, Proposte aperte;
  - grafico 440×110 nel colore del cliente, con area al 12% e linea 2,5; etichette «dic 2025» e «oggi».
- **Colonna destra:** «Ti preparo» (§2.13).
- **Piede:** «Preparami l'incontro» (primario, grande), «Segna come fatto» (grande), «Apri il dossier» (solo per i clienti con dossier) e, a destra, «Le cifre vengono dai motori di Prisma».
- **Interazioni:**
  - «Preparami» → PC `P09`, `P10`; MO `08`, `09`.
  - «Segna come fatto» → §2.14; PC `P11`, `P12`, `P13`; MO `10`, `11`, `12`.
  - «Apri il dossier» chiude il dettaglio subito e passa a Clienti › Panoramica sul cliente giusto (PC `C01`).
- **In Prisma** le cifre arrivano dai motori: `MotorePosizioni` e gli altri `Motori/`.

### 4.2 Clienti

**4.2.1 Rubrica e dossier** — PC `C02` (dal dock), `C01` (da «Apri il dossier»).
- **Rubrica** (barra laterale 250, padding 14×12):
  - `.lbl` «Rubrica» con il numero dei clienti;
  - ricerca a capsula `chip` (padding 8×14, 13, «⌕  Cerca nome o progetto») che filtra a ogni tasto su nome e motto, senza animazione (PC `C03`);
  - voci (padding 9×8, raggio 14, spazio 10): avatar 38, nome 14 bold, motto 12 troncato. Hover `chip`, selezione `rgba(0,122,255,.13)` in 0,25 s;
  - in fondo «+ 30 clienti di prova» (in Prisma: il comando di Impostazioni).
- **Dossier** (card senza ombra a 266 da sinistra, padding 22×24):
  - avatar 56, «Dossier personale» 11, nome 27 bold, motto · età · professione 13,5;
  - a destra i canali, «Analisi 360» e «Prospetti» (primario);
  - quattro tile 258×76 (spazio 12): Patrimonio netto, Capitale assicurato, Premi annui, Proposte aperte (numero + «· 3.100 €» 15 semibold);
  - segmentato «Panoramica · Obiettivi · Nel tempo · Famiglia»;
  - contenuto della scheda a 236 dall'alto.
- **Cambio cliente** — PC `C04` (a 80 ms), `C05` (a 400 ms): uscita a x +14 in 0,14 s ease-in, poi cascata con base 0; le cifre ricontano da 0 e gli anelli partono a 0,15. La scheda attiva resta quella scelta.
- **Cambio scheda:** uscita a y +6 in 0,13 s lineare, poi cascata, numeri e anelli a 0,15.

**4.2.2 Panoramica** — PC `C02`, `C06` (Marco 84%, arancio), `C23` (Andrea 60%), `C07` (hover sul prossimo incontro).
- Griglia `1,25fr 1fr` con spazio 14.
- **«Dati per l'analisi»** (padding 20×22):
  - percentuale 22 bold, verde da 85 in su, altrimenti arancio;
  - anello 120/13 con «completi» al centro;
  - elenco dei dati mancanti, ognuno con «Completa». Il template non fa nulla; in Prisma il pulsante apre la scheda del dato (`ComponentiCompletezza.swift`).
- **«Da ricordare»:** nota 15 con interlinea 1,5.
- **«Prossimo incontro»** (inclinazione 5): data 21 bold, titolo 14, «Apri in Agenda ›». Tutta la card apre l'Agenda.

**4.2.3 Obiettivi** — PC `C08` (a 330 ms), `C09`, `C22` (card «nuovo obiettivo»); MO `01`, `15`.
- **Elenco.** Tre colonne con spazio 14, inclinazione 10, padding 22, contenuto centrato:
  - anello 150/15 nel colore dell'obiettivo (`#0A84FF`, `#8B5CF6`, `#30B15C`) con la percentuale 32 bold;
  - nome 20 bold;
  - «20.800 € di 40.000 €» e «550 € al mese · arriva a <mese anno>»;
  - «Prova un altro versamento ›».
- **Posto libero.** Con meno di 3 obiettivi compare una card tratteggiata «＋ Un nome al futuro: nuovo obiettivo». In Prisma questa card apre la creazione dell'obiettivo.
- **Dettaglio dell'obiettivo** (920×520) — PC `C10`, `C11`, `C12`, `C13`, `C14`, `C15`, `C16`; MO `06`, `06b`, `16`:
  - `.lbl` nel colore e nome 30 bold;
  - anello 220/22 con percentuale 44 e «oggi»;
  - «Già messi da parte» e «Obiettivo» (`.v` che contano);
  - «Versamento mensile» con valore 46 bold nel colore;
  - cursore da 0 a `round(v·2,4/10)·10`, passo 10;
  - «Arriva a <mese anno>» 17 e lo scarto in `.k`;
  - piede: «Salva nel dossier» (primario: chiude e mostra il toast), «Annulla» e la nota sul rendimento.
- **In Prisma:**
  - data e scarto vengono dal motore degli obiettivi con il rendimento scelto, non da un fisso 0%;
  - l'anello del dettaglio **segue il cursore**: mostra la copertura a scadenza (vedi §4.9);
  - a 0 € la frase è «Con 0 € al mese non ci arriva», e lo scarto coerente.

**4.2.4 Nel tempo** — PC `C17` (a 700 ms), `C18`; MO `13`, `14`.
- Card intera con `.lbl` «Il patrimonio, tre anni indietro e due avanti» e legenda «━ com'era» `#0A84FF`, «┅ stima con le proposte» `#8B5CF6`.
- Grafico 1040×330:
  - passato: 36 mesi su 600 pt, area `#0A84FF` .2 e linea 2,8;
  - futuro: 25 mesi su 400 pt, fascia viola .13 e linea 2,6 **tratteggiata 6 6**, anche a disegno finito;
  - griglia di 4 linee con i valori «NNNk» 11 a destra;
  - verticale «oggi» tratteggiata 2 4, «oggi» 12 bold, «nov 2023» e «nov 2028».
- In Prisma la stima viene dai motori (oggi il template usa +5,5% l'anno, fisso).

**4.2.5 Famiglia** — PC `C19`, `C20` (hover), `C21` (nessun familiare).
- Griglia di `max(2, familiari + 1)` colonne.
- Titolare: avatar 70 **visibile e centrato** (nel template manca: §4.9), nome 19 bold, «45 anni · titolare del dossier».
- Familiari (inclinazione 6): avatar 70, nome 19 bold, «Moglie · 43 anni» e la capsula della scopertura (12 semibold, padding 4×10), con testo nel tono e fondo nel tono al 12%:
  - rosso «Nessuna protezione»;
  - arancio «Non è beneficiario»;
  - verde «Coperto…».
- Senza familiari: «Nessun familiare nel dossier.».

### 4.3 Analisi 360

**4.3.1 Griglia delle quattro aree** — AA `A01` (a 300 ms), `A02` (Giulia), `A03` (hover), `A05-cliente-1…4`.
- **Testata:** a destra il segmentato dei clienti con avatar 24 (padding 4/12/4/4, spazio 6, alto 38).
- **Griglia 2×2** con spazio 14. Ogni area misura circa 684×319, padding 24×26 e inclinazione 5. Contiene:
  - anello 170/17 nel colore dell'area, con al centro 36 bold (24 se il testo è più lungo di 5 caratteri);
  - `.lbl` nel colore;
  - titolo 26 bold «{grande} {testo}»;
  - descrizione 14,5 (al massimo 380);
  - collegamento 13 semibold «Prova il simulatore ›» oppure «Vedi il dettaglio ›».
- **Testi delle aree:** vedi la relazione (`spec-analisi-agenda.md` §1). I mesi si scrivono sempre con la virgola.
- **Cambio cliente** — AA `A04` (a 260 ms): la pillola scorre, la griglia esce in 0,14 s lineare (scala 0,99), poi cascata con base 0 e anelli a 0,15.
- Nel template mancano TFR, scenari e confronto, che sono tra gli strumenti di Analisi 360 in Prisma. Vanno resi nello stesso linguaggio: una quinta card o una riga «Strumenti» sotto la griglia, da decidere con l'utente.

**4.3.2 Previdenza** (940×540) — AA `A06` (a 250 ms), `A07`, `A08` (900 €), `A09` (450 €), `A10` (0 €), `A11` (salva, a 200 ms), `A12` (toast), `A23`, `A24` (Ruby).
- **Testata:** `.lbl` viola «PREVIDENZA · Nome Cognome» e il titolo 28 bold «Quanto mettere da parte per la pensione».
- **Anello** 210/20 con la percentuale 42 e «del divario».
- **Cifre in alto:** tre `.v` che contano, «Pensione pubblica stimata», «Desiderata», «Divario al mese» (viola).
- **Versamento:** «Versamento mensile nel fondo pensione» con il valore 44 bold viola, e il cursore da 0 a 900 a passi di 10.
- **Risultati:** tre `.v`, «Rendita in più al mese», «Capitale a {età} anni», «Risparmio fiscale l'anno» (verde). All'apertura contano in 1,0 s.
- **Piede:**
  - «Salva come proposta» chiude il dettaglio e mostra il toast «Proposta salvata nel dossier di …»;
  - «Chiedi a Ruby di spiegarlo» chiude subito il dettaglio, apre Ruby e manda la domanda dopo 0,7 s;
  - una riga di ipotesi.
- **Cursore:** i numeri cambiano subito, l'anello insegue in 1,4 s.
- **In Prisma** le formule vengono da `MotoreAnalisi`/TFR, non dal fattore del template, e la riga delle ipotesi elenca le ipotesi vere del motore.

**4.3.3 Protezione** (940×540) — AA `A13`, `A14`, `A15`, `A16` (chiusura a 150 ms).
- Struttura come la Previdenza, in rosso, con il titolo «Se domani non ci fosse il suo reddito».
- Anello con «protetto».
- Due `.v`: «Capitale che servirebbe», «Già assicurato».
- «Capitale da aggiungere con una temporanea caso morte», con il valore 44 rosso e il cursore da 0 a `ceil(need·1,1/10.000)·10.000`, passo 10.000.
- «Premio stimato l'anno» e «Al mese».
- Piede: solo «Salva come proposta», più la nota sul premio indicativo.
- In Prisma c'è anche qui «Chiedi a Ruby di spiegarlo», per coerenza con la Previdenza.

**4.3.4 Investimenti** (900×480) — AA `A17` (a 500 ms), `A18`, `A22` (Marco).
- `.lbl` blu e il titolo «Come lavorano i suoi risparmi».
- Barra di composizione (§2.11).
- Quattro tile con pallino 10 e percentuale `.v` che conta.
- Riga in basso: «Coerenza con il profilo», «Profilo di rischio» e «Costo medio l'anno». In Prisma il costo viene dalle posizioni, non dall'1,4% fisso.
- Ogni pezzo della composizione distingue il canale quando la posizione è Alleanza oppure indipendente: è da decidere se con una sottobarra o in legenda.

**4.3.5 Risparmio e liquidità** (900×440) — AA `A19` (a 600 ms), `A20`, `A21` (Marco).
- `.lbl` verde e il titolo, **accordato al genere** del cliente: «Quanti mesi può stare tranquillo/a senza entrate».
- Blocchi dei mesi (§2.22) con «1 mese», «soglia consigliata: 6 mesi» (verde) e «12 mesi».
- «Mesi di spese da parte» con la virgola e «Spese mensili», che vengono dai dati del cliente.

### 4.4 Agenda

**4.4.1 Mese e giornata** — AA `G01` (cambio app a 400 ms), `G02` (oggi), `G03` (martedì a 250 ms), `G04`, `G05-giorno-2…5` (`G05-giorno-5` = vuoto), `G06` (toast), `G07` (hover).
- **Testata:** «＋ Nuovo impegno» (primario). In Prisma apre la creazione dell'impegno; nel template non fa nulla.
- **Barra laterale** (330, padding 18×18):
  - «Novembre» 20 bold e «2026»;
  - calendario a 7 colonne con spazio 4: intestazioni 11 semibold `inchiostro3`, caselle 38×36 con raggio 12, tabellari, hover `chip` in 0,25 s;
  - oggi su `#E5484D` con testo bianco bold; il giorno scelto su `rgba(0,122,255,.14)` in bold;
  - puntino 4 `#007AFF` a 4 dal fondo (bianco su oggi);
  - card «QUESTA SETTIMANA» con tre `.v` che contano (calcolati, non fissi);
  - card «DA NON DIMENTICARE» su fondo arancio al 10% con bordo al 25%.
- **Colonna principale** (dopo i 346 della barra laterale):
  - settimana a pillola larga quanto la colonna (alta 34, 7 voci di uguale larghezza);
  - `.h2` con la data e «N impegni» oppure «giornata libera»;
  - giornata in una card senza ombra:
    - righe di 46 pt per ora (dalle 8 alle 19), linee `separatore`;
    - ore 11,5 tabellari a 16 dal bordo, **sullo stesso fondo della giornata** (§4.9);
    - impegni (inclinazione 3) a 72 dal bordo sinistro e 16 dal destro, a `(inizio−8)·46 + 16`, alti `max(40, durata·46 − 4)`, raggio 14, padding 8×12, bordo sinistro 4 nel colore e fondo nel colore al 13%;
    - entrata da destra (§2.2);
  - linea rossa dell'ora alta 2 con pallino 10, che **avanza ogni minuto** (`TimelineView(.everyMinute)`) e si nasconde fuori dall'orario;
  - giornata vuota: «☀︎» 40 e «Nessun impegno. Un buon giorno per i riesami.».
- **In Prisma:**
  - tutti i giorni sono navigabili, non solo dal 2 all'8;
  - le attività (cose da fare) stanno nel mese e nel giorno, come chiede CLAUDE.md: vanno mostrate nella giornata (es. una fascia «Da fare» sopra le ore) con lo stesso linguaggio.

**4.4.2 Traccia dell'impegno** (860×500) — AA `G08` (a 250 ms), `G09`, `G10` (a 650 ms), `G11`, `G12` (presenta), `G13` (attività senza cliente), `G14` (dossier).
- **Testata:**
  - avatar 54, oppure un cerchio nel colore con «✓» se l'impegno non ha cliente;
  - `.lbl` «{TIPO} · {giorno}»;
  - titolo 26 bold;
  - `.k` 14 «{Cliente} · 09:30 – 10:15 · In studio».
- **Corpo:**
  - «PUNTI DA TOCCARE», in righe `.prep`;
  - a destra (300, solo con cliente) due tile: «Patrimonio netto» e «Dati per l'analisi» con `BarraPiena` (verde da 85 in su, arancio sotto).
- **Piede:** «Preparami l'incontro», «Apri il dossier» e «Presenta al cliente». In Prisma «Presenta» apre il prospetto **del cliente dell'impegno**.

### 4.5 Prospetti

**4.5.1 Elenco e anteprima** — PIE `p01`, `p02` (a 120 ms), `p03` (a 380 ms), `p04`, `p05`, `p06`, `p07`, `p08`.
- **Testata:** «▶︎ Presenta all'incontro» e «Salva PDF» (primario).
- **Barra laterale** (290):
  - cliente con avatar 30. Nel template è fisso; in Prisma si sceglie, e il prospetto vale per il cliente scelto;
  - «PER L'INCONTRO» con le voci (padding 11×12): «Un anno insieme · 2026 / Report per il cliente · nuovo», «Check-up», «Obiettivo casa», «Protezione»;
  - card «Fascicolo dell'incontro» con «Componi il fascicolo».
- **Anteprima:** fondo `chip` con raggio 20 e la carta 600×848 in scala 0,7, in alto al centro. La pagina cambia al clic, con la transizione del §2.23.
- **Funzioni vere in Prisma:**
  - la carta si genera con i motori dei prospetti (`MotoreProspetti`, `Carta.swift`, `ComponentiCarta.swift`);
  - «Salva PDF» scrive un PDF su carta bianca;
  - il fascicolo permette di scegliere i report.
- **L'anteprima che cambia scorrendo**, che era stata chiesta, nel template non c'è. Proposta: lo scorrimento con rotella o trackpad sull'anteprima passa alla pagina seguente o precedente, con la stessa transizione e una soglia di 60 pt.

**4.5.2 La carta** — PIE `p15-un-anno-insieme-carta-1x` (1:1), `p01`, `p04`, `p05`, `p06`.
- Valori in §1.2 «Carta» e nella relazione (`spec-prospetti-impostazioni-ruby.md` §1.3-1.4).
- I quattro modelli fissi: «Un anno insieme», «Check-up», «Obiettivo casa», «Protezione».
- Il canale è in testa: oggi c'è «DENIS VICENZONI · CONSULENZA FINANZIARIA», e per Alleanza servono il logo e il blu.
- Le avvertenze in 9 pt a piè di pagina.

**4.5.3 Sala della presentazione** — PIE `p09` (a 250 ms), `p10`, `p11` (a 150 ms), `p12` (a 500 ms), `p13`, `p14`.
- Velo `rgba(6,14,20,.92)` sopra tutto e foglio in scala 0,88.
- Comandi in basso a 24: frecce `rgba(255,255,255,.12)` da 32, «1 di 4» 13 (larghezza minima 90), «Chiudi» bianco.
- Movimenti: §1.8 `salaApre`, `giroPagina`, `salaChiude`.
- Sotto la sala opaca l'acqua si ferma (regola di CLAUDE.md).

### 4.6 Impostazioni

**Riferimenti:** PIE `i01`…`i09`.

- **Barra laterale** (260): «Aspetto», «Archivio e backup», «Ruby», «Profilo». Cambiando sezione riparte la cascata con base 0.
- **Titolo della sezione:** `.h2` (margini 4 sopra e 14 sotto).
- **Righe:** card senza ombra con padding 16×20 e distanza 10 tra una riga e l'altra; titolo 15 bold e `.k`; il controllo a destra.
- **Aspetto** (`i01`, `i02`, `i09`):
  - segmentato Chiaro / Scuro / Automatico. In Prisma Automatico **segue davvero il Mac**, a caldo, come oggi (`AspettoInterfaccia.automatico`);
  - «L'acqua della scrivania» (interruttore = sfondo fermo, regola che esiste già);
  - «Riduci movimento» (nuovo, §2.0);
  - «Dimensione del testo»: Normale / Grande / Molto grande. Nel template mostra solo un toast; in Prisma va una scala dei caratteri (1,0 / 1,12 / 1,25) applicata ai token di §1.7, oppure va rimandata, da decidere.
- **Archivio e backup** (`i03`, `i04`, `i05`, `i06`):
  - card con l'anello del backup (§2.24), «Nessun backup ancora» / «Backup creato adesso» e «Crea backup»;
  - righe «Backup automatico settimanale» (ultime 8 copie), «Dove salvare» con «Scegli…» e «Ripristina…»: in Prisma tutte funzionanti, come oggi;
  - la frase di fine backup elenca il contenuto vero: «Clienti, agenda, posizioni, documenti e impostazioni di Ruby».
- **Ruby** (`i07`): «Motore · Qwen sul Mac · qwen3.5:4b con Ollama, solo indirizzi locali» con lo stato reale (pallino verde «Pronto» o un altro stato); «iPhone e iPad» (ponte cifrato); «Scorciatoia ⌥ Spazio» per la mini Ruby, che in Prisma esiste (`VistaMiniRuby.swift`, `TemaMiniRuby.swift`).
- **Profilo** (`i08`): avatar 64 «DV», «Denis Vicenzoni», «Consulente finanziario» e le due righe con le etichette dei canali.

### 4.7 Ruby

**Riferimenti:** PIE `e01`…`e10`; AA `A23`, `A24`.

- **Colonna sinistra** (300, centrata, 30 dall'alto):
  - sfera 120 viva;
  - «Ciao, sono Ruby.» 22 bold e «Mettiamo in ordine le idee.» 14;
  - card di stato con «Qwen sul Mac · pronto» e «I numeri li calcola Prisma, io li racconto.»: lo stato è reale (pronto oppure non pronto, e in quel caso Ruby non risponde);
  - card «OGGI» con gli impegni del giorno (13,5, interlinea 1,9).
- **Chat** (a 316 da sinistra; area a 40 dai lati, 10 dall'alto, 120 dal fondo):
  - messaggi larghi al massimo 640, 14,5 con interlinea 1,55, distanza 14;
  - bolle di Ruby su `chip`, padding 14×18, raggi 20/20/20/6, intestazione 12 semibold «Ruby» oppure «Ruby · Calcoli di Prisma» (modalità lavoro, numeri dai motori);
  - bolle dell'utente `#007AFF` con testo bianco, padding 10×16, raggi 20/20/6/20, allineate a destra.
- **Suggerimenti** (a 66 dal fondo, capsule 13 medium): restano visibili.
- **Campo** a capsula (`cardPiena`, ombra `card`, padding 6/6/6/18): testo 14,5 con il segnaposto «Chiedi una sintesi, un incontro, uno scenario…» e il pulsante d'invio tondo da 36 «↑».
- **Sequenza di una domanda:**
  1. la bolla dell'utente entra (molla di 0,42 s);
  2. compaiono i puntini e la sfera pulsa;
  3. arriva il testo in streaming (§2.20);
  4. la scheda di calcolo entra (0,5 s, curva `uscita`).
- **Schede di calcolo:**
  - eventi del giorno, in tile con bordo sinistro da 4;
  - tabella dello scenario a 3 colonne `1,2fr 1fr 1fr`, con la colonna dello scenario in viola 700;
  - tre tile con `.v` 22.

  Sono **modelli grafici fissi** riempiti con le cifre dei motori (regola di CLAUDE.md: i calcoli li fa l'app).
- **Modalità.** Il template non distingue lavoro e conversazione. In Prisma serve un selettore: un segmentato a pillola «Lavoro / Conversazione» nella testata accanto a «✎ Nuova conversazione».
- **Apertura da destra:** il gesto da destra a sinistra sulla scrivania apre Ruby come oggi.

### 4.8 Ricerca

Nel template è solo un toast (PIE `r01`). In Prisma resta la Ricerca vera (`ComponentiRicerca.swift`, `MisureSpotlight.swift`), restilizzata con i token Apple:
- pannello di `vetro` con raggio 22, largo 640, centrato a 120 dall'alto;
- entrata come il pannello delle notifiche (0,38 s con la molla, da y −10 e scala 0,97);
- risultati come le voci della rubrica, raggruppati per app, con la selezione `rgba(0,122,255,.13)`.

### 4.9 Errori del template da non copiare

1. La stima di «Nel tempo» diventa continua: va **tratteggiata** (§2.4).
2. L'avatar del titolare in Famiglia è invisibile (doppio attributo `style`).
3. Con il cursore dell'obiettivo a 0 €, la data dice «mai» e lo scarto dice «Come oggi»: va reso coerente.
4. L'anello del dettaglio dell'obiettivo non segue il cursore: deve seguirlo.
5. «Completa» in Panoramica, «Nuovo impegno», «Scegli…», «Ripristina…», «Salva nel dossier» e «Apri in Simulazioni» di Ruby sono inerti: in Prisma vanno collegati.
6. «tranquilla» è fisso al femminile: va accordato al genere.
7. I mesi escono con il punto («3.5»): ci vuole la virgola.
8. Le tracce dell'agenda hanno cifre scritte a mano («circa 427 €» mentre la formula dà 420): le cifre vengono solo dai motori.
9. Con le formule del template, Laura avrebbe bisogno di circa 1.760 €/mese, oltre il massimo del cursore (900). Il massimo va calcolato dal fabbisogno, ad esempio `max(900, ceil(fabbisogno·1,2/50)·50)`.
10. «Presenta al cliente» apre sempre Giulia.
11. I contatori della settimana sono fissi.
12. La linea dell'ora non avanza.
13. In scuro le etichette delle ore hanno un fondo diverso da quello della giornata.
14. In Prospetti il cliente è fisso.
15. «Automatico» legge l'aspetto del Mac una volta sola.
16. Il blocco non rispetta Riduci movimento; il template riduce solo una parte delle animazioni (§2.0).
17. Le formule semplificate (previdenza al 3% composto diviso 300, premio `v·0,0012·età/37`, costo 1,4% e spese 2.300 € fissi) **non** vanno usate.

---

## 5. Differenze da Prisma di oggi

### 5.1 Differenze di progetto e di regole

| Tema | Template «stile Apple» | Prisma oggi (CLAUDE.md e codice) | Da fare |
|---|---|---|---|
| Identità grafica | `Design/template-apple.html` | Liquid Glass (`Design/tema-liquid-glass.html`) è la fonte ufficiale dal 27 ottobre 2026 | L'utente deve confermare che il template Apple è la nuova fonte; poi si aggiorna CLAUDE.md (sezione Grafica) |
| Finestre | una sola finestra interna riusata, che esce e rientra nell'icona | più finestre interne con l'effetto genio (`MotoreGenio`, `CurveGenio.swift`, `GenioImbuto.swift`), ingrandimento, spazi | Si adotta l'apertura e chiusura dall'icona (§3.5) come movimento predefinito; il genio resta come ripiego o si toglie, da decidere |
| Acqua | canvas 2D, griglia d'onda 290×182, luce dal gradiente | Metal «pioggia leggera» (`SfondoAcqua*.swift`), già approvata | Si porta il modello d'onda dentro il Metal di oggi, senza toccare le regole di arresto e rallentamento |
| Sfera di Ruby | radiale + riflesso conico che gira, respiro di 4 s | `SferaAcquaRuby.swift` (sfera d'acqua) | CLAUDE.md: «Ruby ha un solo simbolo: la sfera luminosa». Va scelta una sola sfera |
| Dock | 8 voci | `AppPrisma.delDock` con le app ospitate | Si mantiene l'ordine di Prisma (Clienti, Posizioni, …) e le icone `Design/Icone/` |
| Aspetto | si cambia solo da Impostazioni; Automatico letto una volta | `AspettoInterfaccia` con `NSAppearance` dinamico | Si tiene Prisma |
| Riduci movimento | in parte | `Movimenti.calmo` (sistema) | Si aggiunge l'interruttore di Prisma e si estende la regola (§2.0) |
| Istantanee | — | `\.modoIstantanea`, `Prisma --istantanee`, branch `anteprime` | Ogni componente nuovo ha lo stato finale; si aggiungono le scene del template (stessi nomi delle PNG di riferimento) |
| Dati | fittizi, formule semplificate | motori in `Motori/` | Solo motori |
| Modalità di Ruby | una | lavoro e conversazione | Aggiungere il selettore (§4.7) |
| Funzioni che il template non ha | — | Obiettivi e Documenti nel dossier, Simulazioni, Confronti, TFR, Attività, mini Ruby, ponte con iPhone e iPad | Vanno restilizzate con i token Apple senza perderle; servono schermate nuove coerenti |
| iPhone e iPad | — | `Design/iphone.html`, `Sources/Prisma/iOS/` | Si applicano i token di §1, niente inclinazione al passaggio, dock compatto |

### 5.2 Token diversi da quelli di `Tema` di oggi (`Tema.swift`)

| Token | Prisma oggi | Template Apple |
|---|---|---|
| rosso / arancio / verde | `#FF3B30` / `#FF9500` / `#34C759` | `#E5484D` / `#E08A00` / `#2FA35A` (`#FF3B30` resta solo per il badge, `#34C759` per l'interruttore) |
| accento in scuro | `#0A84FF` | `#007AFF` fisso |
| canale Alleanza in scuro | `#5B8CFF` | `#6B95FF` |
| canale indipendente in scuro | `#BF8430` | `#D0954A` |
| fondo dei canali | colore calcolato sul chip (17% / 19%) | `rgba(37,99,235,.13)` / `rgba(176,110,18,.14)` fissi |
| inchiostro 1/2/3 chiaro | .86 / .56 / .36 | .87 / .55 / .34 |
| inchiostro 1/2/3 scuro | .94 / .64 / .42 | .94 / .62 / .38 |
| separatore | .09 / .10 | .08 / .09 |
| selezione | accento .17 | `rgba(0,122,255,.13)` |
| inchiostro sullo sfondo, scuro, secondario | bianco .68 | bianco .66 |
| notifiche (moto) | molla 0,3 / 1, spostamento 24 | molla bézier 0,38, y −10, scala 0,97 |
| apertura finestra | molla 0,3 / 1, scala 0,2 | bézier `(0.3,1.12,0.5,1)` 0,6 dall'icona |

Proposta: i nuovi valori vivono in `Tema.Apple`. Le schermate si spostano una alla volta, e alla fine `Tema.Colore` diventa un alias di `Tema.Apple.Colore`, così non restano due fonti. Nessun valore sparso nel codice (regola di CLAUDE.md).

### 5.3 macOS 13: cosa manca in SwiftUI e il ripiego

| API | Disponibile da | Uso nel porting | Ripiego su macOS 13 |
|---|---|---|---|
| `contentTransition(.numericText())` | macOS 14 | numeri | Non serve: `NumeroCheConta` con `Animatable` o `TimelineView` (§2.1) |
| `onContinuousHover` | macOS 13 ✓ | inclinazione, dock | — |
| `matchedGeometryEffect` | macOS 11 ✓ | pillola del segmentato | — (per il dettaglio si usa un rettangolo animabile, §2.7) |
| `sensoryFeedback` | macOS 14 | conferma «fatto», backup | `NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, …)` dietro `#if os(macOS)`; su iOS 17 `sensoryFeedback` va bene |
| `phaseAnimator` / `keyframeAnimator` | macOS 14 | rimbalzo dell'icona, respiro, pulsazione, puntini | `Animatable` con fase 0…1 e funzione a tratti, oppure `TimelineView(.animation)` |
| `withAnimation(…, completion:)` / `completionCriteria` | macOS 14 | sequenze («fatto», sblocco, giro pagina) | `Movimenti.dopo(durata)` (esiste già) |
| `Animation.spring(duration:bounce:)` e il tipo `Spring` | macOS 14 | molle | `.spring(response:dampingFraction:)` (valori in §1.8) |
| `Animation.timingCurve` con y fuori da 0…1 | macOS 10.15, ma il comportamento con il superamento va verificato | `--spring`, apertura del dettaglio | Prova in un'istantanea a metà; se SwiftUI limita y, si usa la molla equivalente di §1.8 o una bézier propria con `Animatable` |
| `UnitCurve` / `.timingCurve(UnitCurve)` | macOS 14 | — | `timingCurve(c0x,c0y,c1x,c1y)` |
| `visualEffect { }` | macOS 14 | riflesso e inclinazione dalla geometria | `GeometryReader` + `GeometryEffect` |
| `scrollPosition` / `scrollTargetBehavior` / `scrollTransition` | macOS 14 | nastro | Offset proprio animato (§2.21) |
| `onScrollGeometryChange` | macOS 15 | — | — |
| `onKeyPress` | macOS 14 | Esc, ← → | Monitor `NSEvent` locale (già usato nella shell) |
| `.focusable(interactions:)` | macOS 14 | — | `.focusable()` |
| `@Observable` | macOS 14 | stato | `ObservableObject` + `@Published` |
| `onChange(of:initial:_:)` a due valori | macOS 14 | — | `onChange(of:perform:)` |
| `.transition(.blurReplace)` | macOS 14 | cambio di contenuto | `.asymmetric` con un `ViewModifier` proprio di opacità, offset e sfocatura |
| `containerRelativeFrame` | macOS 14 | griglie | `GeometryReader` o il protocollo `Layout` (macOS 13 ✓) |
| `Layout` | macOS 13 ✓ | scrivania, griglie, nastro | — |
| `MeshGradient` | macOS 15 | — | non serve |
| `AngularGradient`, `RadialGradient`, `.blendMode(.softLight/.overlay)` | ✓ | sfera, riflesso | — |
| `rotation3DEffect(perspective:)` | ✓ (prospettiva normalizzata) | inclinazione | `projectionEffect` con `CATransform3D.m34 = −1/900` per la prospettiva di 900 |
| `Shape.trim`, `StrokeStyle(dash:)` | ✓ | anelli, linee, spunta | — |
| `.blur(radius:)` | ✓ | cascata, sblocco | Attivo solo durante l'animazione (memoria e GPU del M1 da 8 GB) |
| `TimelineView(.animation)`, `Canvas` | macOS 12 ✓ | numeri, sfera, grafici | — |
| `Text(…).monospacedDigit()`, `.tracking`, `.fontDesign` | macOS 12-13 ✓ | cifre e tipografia | — |
| `Slider` personalizzabile | no | cursore | Vista propria (§2.10) |
| Vetro nativo (`glassEffect`) | macOS 26 | vetro | `#if compiler(>=6.2)` + `if #available(macOS 26.0, *)`, ripiego con `Material` (regola di CLAUDE.md) |
| `scrollClipDisabled` | macOS 14 | ombre delle schede nel nastro | Padding interno (il template usa padding 10×28) |
| `inspector` | macOS 14 | — | non serve |

iOS ha come minimo il 17, quindi su iPhone e iPad tutte queste API esistono. Il codice comune però deve compilare per macOS 13: si usano i ripieghi ovunque, oppure `if #available` solo dove il guadagno è chiaro.

### 5.4 Ordine di lavoro proposto (un branch e una PR per passo, ognuna con la build verde)

1. `TemaApple.swift` e `TemaAppleMoto.swift` (§1), più l'ambiente `\.prismaCalmo` e l'interruttore «Riduci movimento».
2. Componenti di base (§2.1-2.17), con le scene delle istantanee a stato finale.
3. Shell: finestra unica dall'icona, dock con ingrandimento, blocco, notifiche, toast.
4. Acqua: modello d'onda nel Metal (§3.7), e la prova che si fermi o rallenti come oggi.
5. Posizioni, poi Clienti, Analisi 360, Agenda, Prospetti, Impostazioni, Ruby, Ricerca.
6. Pagina delle anteprime aggiornata e confronto con le PNG del template.
