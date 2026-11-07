# Prisma ovunque — prova di fattibilità

*4 novembre 2026 · studio sul codice di /home/user/Prisma-o6, nessun file del repository modificato*

**Obiettivo.** iPhone e iPad tengono una copia propria e cifrata dei dati e ci lavorano anche a Mac spento. Lo scambio passa da un file cifrato in una cartella di iCloud Drive scelta dall'utente: niente contenitore iCloud dell'app, niente CloudKit, niente server. iCloud Drive vede solo byte cifrati con una chiave che Apple non conosce.

**Verdetto in una riga:** **fattibile, con limiti** (latenza di iCloud non controllabile, nessuna notifica affidabile a app chiusa, riscelta della cartella dopo una reinstallazione o un cambio di ID Apple). Nessuno di questi limiti blocca il progetto. Quasi tutto il necessario esiste già nel codice: cifratura, zip senza `Process`, copia coordinata da iCloud su iOS, salvataggio atomico.

---

## 0. Cosa c'è oggi nel codice (punto di partenza)

| Pezzo | Dove | Stato oggi | Utile per «ovunque» |
|---|---|---|---|
| Cifratura dei backup protetti | `Dati/CifraturaBackup.swift` | Formato `PRISMACF` v1: PBKDF2-HMAC-SHA256 (600.000 iterazioni, sale di 16 byte per file) → HKDF (chiave dati e chiave di verifica) → AES-256-GCM a segmenti da 1 MiB. Intestazione e indice/«ultimo» autenticati come dati associati: un file troncato o riordinato non si apre. Funziona a flusso, senza tenere tutto in memoria | Sì, così com'è per l'istantanea del Mac. Serve una variante che accetti la chiave già derivata (vedi §3) |
| Zip | `Backup.swift`, `ScrittoreZip`, `LettoreZip` | Sul Mac `/usr/bin/ditto`; su iOS (niente `Process`) `ScrittoreZip`/`LettoreZip`, che leggono anche gli zip di ditto | Sì: iOS sa già scrivere uno zip |
| Password dei backup | `Dati/PortachiaviBackup.swift` | Portachiavi di login del Mac (servizio «Prisma backup»). Il portachiavi «data protection» è escluso apposta: con la firma ad-hoc dà -34018 | Sul Mac sì. Su iOS non c'è ancora nessun uso del Portachiavi |
| Cartella dei backup (Mac) | `ImpostazioniArchivio.scegliCartella()` → `StatoShell.scegliCartellaBackup` | `NSOpenPanel`, poi si salva **il percorso in chiaro** (`impostazioni.backup.cartella = url.path`): nessun segnalibro | Va bene perché l'app non è sandboxed. Per «ovunque» conviene un segnalibro normale (§1.1) |
| Apertura dei backup (iOS) | `iOS/AperturaBackup.swift`, `StatoMobile.copiaDiLavoro` | `.fileImporter` (selettore di **file**, non di cartelle) → `startAccessingSecurityScopedResource()` (un `false` è tollerato) → `NSFileCoordinator(...).coordinate(readingItemAt:options:.withoutChanges)`, che scarica da iCloud Drive un file non ancora sul dispositivo → copia in `tmp/` → `StatoShell.ripristina` | Sì: lo stesso schema, aperto su una **cartella** e con un segnalibro persistente |
| Protezione dell'archivio su iOS | `Archivio.preparaCartelle`, `opzioniScrittura` | `isExcludedFromBackup` (niente backup iCloud del dispositivo) e `FileProtectionType.complete`, scrittura `.atomic + .completeFileProtection` | Sì: la copia locale su iPhone è già protetta |
| Firma e entitlements | `.github/workflows/build.yml` (`codesign --force --deep --sign -`), `Supporto/iOS/assembla.sh` (`codesign --force --sign - --timestamp=none`) | **Nessun file di entitlements**, né sul Mac né su iOS. Mac: firma ad-hoc, **senza sandbox**. iOS: AltStore o Sideloadly rifirmano con l'ID Apple gratuito | Mac: libero accesso al disco, con i soli limiti di TCC. iOS: sandbox standard, nessun entitlement iCloud, che **non serve** (§2) |
| Info.plist iOS | `Supporto/iOS/Info.plist` | `LSSupportsOpeningDocumentsInPlace = false`, `UIFileSharingEnabled = false`, UTI `local.prisma.backup` (`.cifrato`) | Restano così: la cartella si apre con il selettore, non serve esporre i Documenti dell'app |
| Ponte di Ruby | `Ruby/PonteRuby.swift`, `ServerPonteRuby.swift` | Rete locale, Bonjour, ChaChaPoly con la chiave ricavata dal codice di abbinamento (HKDF), buste con tolleranza d'orologio | Non serve allo scambio, ma dà un'idea in più: a Mac acceso e sulla stessa rete, il Mac può chiedere all'iPhone «prendi subito la nuova istantanea» (§5) |
| Modifiche da iOS | `StatoShell` è condiviso | iOS usa lo stesso `StatoShell` del Mac e salva il proprio `archivio.json`. Alcune funzioni rispondono «solo sul Mac per ora» (7 punti) | La base per scrivere su iPhone c'è già. Manca il **giornale** delle modifiche |
| Date di modifica | `Nota.aggiornataIl`, `aggiornatoIl` in un solo modello di `Modelli.swift` | Quasi tutte le entità hanno un `id` stabile, ma **non** hanno una data o una versione di modifica | Il giornale le rende superflue: niente migrazione di tutte le entità (§4) |

---

## 1. Mac: scrivere il file cifrato in iCloud Drive

### 1.1 Cartella scelta con NSOpenPanel e segnalibro
- **L'app non è sandboxed.** Il workflow firma ad-hoc senza entitlements, quindi `com.apple.security.app-sandbox` è assente. L'URL di `NSOpenPanel` si usa direttamente e `startAccessingSecurityScopedResource()` non serve (restituisce `false` senza conseguenze).
- **Segnalibro con security scope: no.** `.withSecurityScope` richiede la sandbox e l'entitlement `com.apple.security.files.bookmarks.app-scope`. Fuori dalla sandbox non serve, e la sua risoluzione può fallire.
- **Segnalibro normale: sì, consigliato.** `url.bookmarkData(options: [])`, salvato in `impostazioni.ovunque.segnalibroMac`, con il percorso tenuto accanto come ripiego. Il segnalibro segue la cartella se l'utente la rinomina o la sposta dentro iCloud Drive; il percorso in chiaro, come oggi per i backup, no. Alla risoluzione: se `bookmarkDataIsStale`, si rigenera.
- **TCC (privacy di macOS).** Su macOS 14 e successivi, un'app che legge in `~/Library/Mobile Documents/` (iCloud Drive) può far comparire la domanda «Prisma vuole accedere ai file di iCloud Drive». La scelta esplicita con `NSOpenPanel` vale come consenso. Ma la **firma ad-hoc cambia a ogni build**: dopo un aggiornamento di Prisma il Mac può chiedere di nuovo il permesso, come già succede con il Portachiavi (vedi il commento di `PortachiaviBackup`). Il segnalibro normale non aggira TCC. Se l'accesso viene negato, Prisma lo dice e propone «Scegli di nuovo la cartella», che rinnova il consenso. Da provare a mano sul Mac di Denis (macOS 27).
- Si mantiene il controllo già presente in `scegliCartellaBackup`: la cartella non può stare dentro `Archivio.cartella`. Si aggiunge un controllo nuovo: la cartella non può essere quella dei backup, per non mescolare la rotazione dei backup con i file della sincronizzazione.

### 1.2 Scrittura atomica senza scontrarsi con il demone di iCloud
1. Si prepara tutto in locale, in `FileManager.temporaryDirectory` (mai dentro iCloud Drive, dove anche i file provvisori verrebbero caricati): zip (ditto) → `CifraturaBackup` → `istantanea.cifrato.tmp`.
2. Si sostituisce dentro una scrittura coordinata:
   ```swift
   NSFileCoordinator(filePresenter: nil).coordinate(writingItemAt: destinazione, options: .forReplacing, error: &e) { url in
       _ = try FileManager.default.replaceItemAt(url, withItemAt: provvisorio)   // o moveItem se non esiste
   }
   ```
   `.forReplacing` è il segnale che `fileproviderd` (il demone di iCloud Drive) e gli altri lettori coordinati si aspettano. Un lettore vede o il file vecchio intero o quello nuovo intero. Anche se iCloud consegnasse un file a metà, l'autenticazione dei segmenti GCM (indice e segno «ultimo») lo farebbe rifiutare come `backupDanneggiato`, senza danni.
3. Le scritture si raggruppano: un'istantanea nuova solo se l'archivio è cambiato e al massimo ogni N minuti (proposta: 10), più una all'uscita da Prisma e una quando il Mac va a riposo. È lo stesso aggancio che già blocca Prisma quando il Mac va a riposo. Ogni scrittura carica su iCloud l'intero file.

### 1.3 Rilevare i cambiamenti (i giornali scritti da iPhone e iPad)
- **`NSMetadataQuery` no.** Gli ambiti `NSMetadataQueryUbiquitousDocumentsScope`/`…DataScope` coprono solo il contenitore iCloud dell'app e richiedono l'entitlement `com.apple.developer.icloud-container-identifiers`, che con la firma ad-hoc non è possibile. Un `NSMetadataQuery` con ambito su un percorso qualsiasi interroga Spotlight. Funziona solo se Spotlight indicizza iCloud Drive, ha ritardi variabili ed è inaffidabile: va escluso.
- **`NSFilePresenter`: in parte.** Su una cartella fuori dal contenitore lo si può registrare. Riceve sicuramente le modifiche coordinate dello stesso processo. Quelle che arrivano da `fileproviderd` (download di una versione nuova) di solito vengono notificate, ma Apple non lo garantisce per le cartelle fuori dal contenitore. Non va usato come unica fonte.
- **Scelta proposta per il Mac: FSEvents** (`FSEventStreamCreate` sulla cartella, latenza di 2 s, su una coda propria e fuori dal thread principale). Sul Mac iCloud Drive è una vera cartella del disco, e ogni file che `fileproviderd` scarica o sostituisce produce un evento. In più si fa un controllo all'avvio, al risveglio e quando la finestra torna attiva: si confrontano `contentModificationDate` e la dimensione di ogni `giornale-*.cifrato`. Il costo è trascurabile per la batteria e la memoria (M1 da 8 GB).

### 1.4 File non ancora scaricati
- Fino a macOS 13 iCloud Drive lasciava dei segnaposto `.nome.icloud`. **Da macOS 14 (File Provider, «FPFS») non ci sono più**: un file non scaricato è un file «dataless» con il suo nome vero. Prisma gira su macOS 13+ (target del pacchetto) e deve gestire entrambi i casi.
  - Nell'elenco: si riconosce sia `.<nome>.icloud` sia `URLResourceValues.ubiquitousItemDownloadingStatus != .current`.
  - Per scaricare: `try FileManager.default.startDownloadingUbiquitousItem(at:)`. Per iCloud Drive funziona anche fuori dal contenitore, ma va provato su macOS 27. Poi la lettura coordinata (`coordinate(readingItemAt:)`), che materializza il file e aspetta che arrivi: è lo stesso meccanismo che `StatoMobile.copiaDiLavoro` già usa su iOS.
  - La lettura si fa sempre fuori dal thread principale e con un tempo massimo. Se scade, Prisma mostra «In attesa di iCloud».
- Consiglio da dare all'utente: tasto destro sulla cartella nel Finder → «Mantieni scaricato» (macOS 15+), così «Ottimizza spazio» non toglie i file dal disco.

---

## 2. iOS con firma gratuita (AltStore / Sideloadly)

### 2.1 Aprire una cartella
- `UIDocumentPickerViewController(forOpeningContentTypes: [.folder])` (iOS 14+; `asCopy` è `false` di default con questo inizializzatore). In SwiftUI si può usare lo stesso `.fileImporter(allowedContentTypes: [.folder])`, già presente in `AperturaBackup` per i file, ed evitare di scrivere un `UIViewControllerRepresentable`. Il minimo dell'app è iOS 17, quindi entrambe le strade sono disponibili.
- L'URL restituito ha un **security scope**: `startAccessingSecurityScopedResource()` sulla cartella dà accesso anche ai file che contiene (lettura, creazione e sostituzione), finché si chiama `stop…`. L'accesso va aperto per ogni sessione di lavoro e chiuso alla fine: le aperture non chiuse consumano risorse del kernel.
- **Segnalibro persistente:** `try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)`. Su iOS il segnalibro di un URL con security scope lo conserva implicitamente: `.withSecurityScope` esiste solo su macOS. Lo si salva nelle impostazioni del dispositivo e lo si risolve con `URL(resolvingBookmarkData:bookmarkDataIsStale:)`. Se è `stale`, lo si rigenera subito, dentro l'accesso aperto.
- **Serve l'entitlement iCloud? No.** L'app non parla con iCloud: parla con l'estensione File Provider di iCloud Drive attraverso il selettore. È lo stesso modello che usano Pages, Working Copy o qualunque app con firma gratuita che apre cartelle di iCloud Drive o di Dropbox. `NSFileCoordinator` sugli URL del File Provider scarica il file se manca. Oggi `copiaDiLavoro` lo fa già per i backup; il messaggio «Se è su iCloud Drive, aspetta che sia scaricato e riprova» copre il caso dell'iPhone offline.
- **Rilevare i cambiamenti su iOS.** FSEvents non c'è e `NSMetadataQuery` è escluso come sul Mac. `NSFilePresenter` sulla cartella del File Provider funziona solo mentre l'app è aperta, e non sempre. Proposta: un controllo quando l'app torna attiva (`scenePhase == .active`), un pulsante «Aggiorna» e, ad app aperta, un controllo ogni 60 s di `contentModificationDate` e `ubiquitousItemDownloadingStatus` dell'istantanea (una lettura di attributi, non del file). Con la firma gratuita non esistono notifiche push né un aggiornamento in background affidabile: a app chiusa non arriva niente, ed è un limite accettato.

### 2.2 Limiti dei profili gratuiti
| Limite | Effetto su «ovunque» |
|---|---|
| Firma valida **7 giorni**, AltStore o Sideloadly la rinnovano | Il rinnovo è un **aggiornamento sul posto**: stesso identificativo, stesso team (l'ID Apple), stesso contenitore. Restano l'archivio locale, il giornale non ancora unito, il segnalibro della cartella e gli elementi del Portachiavi. Da verificare a mano: alcune versioni di AltStore aggiungono il Team ID al bundle ID (`local.prisma.XXXXXXXXXX`). Se succede una volta sola, all'installazione, non cambia niente nei rinnovi successivi |
| Firma scaduta (non rinnovata) | L'app non si apre, ma i dati restano sul dispositivo. Dopo il rinnovo si riparte. Il giornale non unito sopravvive |
| App cancellata e reinstallata, oppure ID Apple cambiato | Contenitore nuovo, o Team ID diverso e quindi gruppo del Portachiavi diverso. Si perdono segnalibro, chiave e giornale non unito. Bisogna riscegliere la cartella e riscrivere la passphrase. **Rischio vero: le modifiche fatte sull'iPhone e non ancora arrivate al Mac.** Per ridurlo, il giornale si scrive nella cartella di iCloud **subito**, non solo nell'archivio locale (§4) |
| Massimo 3 app attive e 10 App ID a settimana | Nessun effetto diretto. Prisma resta una sola app |
| Nessun entitlement a pagamento (iCloud, push, App Groups condivisi) | Non servono: è proprio il motivo per cui si passa da una cartella scelta e non dal contenitore iCloud |

---

## 3. Cifratura

### 3.1 Dalla passphrase alla chiave
- Si usa **lo stesso schema dei backup protetti**: PBKDF2-HMAC-SHA256 con 600.000 iterazioni, poi HKDF per le sottochiavi, poi AES-256-GCM a segmenti. La passphrase è normalizzata (NFC, `precomposedStringWithCanonicalMapping`), come in `derivaChiave`.
- Differenza necessaria: oggi ogni backup ha un **sale suo**, quindi una chiave sua, e PBKDF2 si ripete a ogni apertura (circa 0,3-0,8 s su un iPhone recente; è sopportabile, ma non a ogni controllo). Per «ovunque»:
  - si crea un **sale dello spazio** una volta, alla prima attivazione sul Mac, e lo si scrive in chiaro in `prisma-ovunque.json`, nella cartella, insieme a versione, iterazioni e verifica (16 byte, come in `Intestazione`);
  - chiave madre = PBKDF2(passphrase, sale dello spazio). Da questa, con HKDF e usi distinti (`"PrismaOV v1 · istantanea"`, `"PrismaOV v1 · giornale <dispositivo>"`, `"PrismaOV v1 · verifica"`), si ricavano le chiavi dei file;
  - ogni file mantiene il formato `PRISMACF` con un **valore di `algoritmo` nuovo** (2 = «chiave dello spazio»). Il campo sale dell'intestazione resta casuale e diventa l'`info` di HKDF, così ogni file ha comunque una chiave diversa. È una modifica piccola a `CifraturaBackup`: un `cifra(_:in:chiave:)` accanto a `cifra(_:in:password:)`. I backup v1 restano apribili come oggi.
- Si cifrano anche i nomi interni (lo zip è dentro il cifrato). In chiaro restano solo i nomi dei file nella cartella (`istantanea.cifrato`, `giornale-<idDispositivo>.cifrato`), che non dicono nulla dei clienti.

### 3.2 Dove si tiene la chiave
- **iPhone/iPad:** nel Portachiavi si salva la **chiave madre derivata** (32 byte), non la passphrase, con `kSecClassGenericPassword`, `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` e `kSecAttrSynchronizable = false`. La chiave non va nel backup iCloud né su altri dispositivi e si legge solo a telefono sbloccato. Con la firma gratuita il Portachiavi funziona: AltStore e Sideloadly inseriscono `application-identifier` e `keychain-access-groups` con il Team ID. Il problema -34018 riguarda il Mac ad-hoc, non l'iOS firmato con l'ID Apple. È comunque da provare sul dispositivo vero, perché la CI usa solo il simulatore. In alternativa, o in più, si può chiedere Face ID con `SecAccessControlCreateWithFlags(.userPresence)`.
- **Mac:** stessa scelta di `PortachiaviBackup`: Portachiavi di login, servizio nuovo «Prisma ovunque». Dopo un aggiornamento ad-hoc il Mac può chiedere il permesso una volta.
- La chiave non va mai nell'archivio né nelle impostazioni. L'archivio finisce nei backup e nell'istantanea.

### 3.3 Se la si perde
- **Persa sull'iPhone** (reinstallazione, cambio di ID Apple, nuovo telefono): basta riscrivere la passphrase. Il file in iCloud si riapre.
- **Passphrase dimenticata del tutto:** il file in iCloud diventa illeggibile per chiunque, Apple compresa: è il prezzo della cifratura vera. Ma **non si perdono dati**: il Mac ha l'archivio in chiaro sul suo disco (e i backup). Si sceglie una passphrase nuova, che genera un sale nuovo, e il Mac riscrive l'istantanea; gli iPhone la riaprono con la passphrase nuova. Si perdono solo le modifiche dell'iPhone non ancora unite, a meno che l'iPhone abbia ancora la vecchia chiave nel Portachiavi. In quel caso, «Cambia passphrase» sull'iPhone ricifra il suo giornale. La schermata va scritta onestamente: «Senza passphrase questo file non si apre più. I dati restano sul Mac.»
- **Cambio volontario della passphrase:** si fa dal Mac. Sale nuovo, istantanea nuova, `prisma-ovunque.json` nuovo con una «generazione» + 1. Gli iPhone vedono la generazione cambiata e chiedono la passphrase nuova; prima di scaricare l'istantanea ricifrano e caricano il giornale ancora in sospeso.

---

## 4. Modifiche senza Mac: il giornale

### 4.1 Struttura della cartella (un solo scrittore per file)
```
iCloud Drive/Prisma ovunque/            ← scelta dall'utente
  prisma-ovunque.json                    in chiaro: versione, generazione, sale, iterazioni, verifica, nessun dato
  istantanea.cifrato                     scritta SOLO dal Mac: archivio completo + «visto fino a» di ogni dispositivo
  giornale-<idDispositivo>.cifrato       scritto SOLO da quel dispositivo: le sue operazioni non ancora confermate
```
**Ogni file ha un solo scrittore.** È la regola che elimina alla radice quasi tutti i conflitti di iCloud: due dispositivi non sostituiscono mai lo stesso file.

### 4.2 Formato dell'operazione (JSON dentro il cifrato)
```json
{
  "id": "op-6f1c…",                 // UUID: rende l'unione idempotente (un'op vista due volte si applica una volta)
  "dispositivo": "iphone-3a9e",     // id stabile del dispositivo, generato alla prima attivazione
  "lamport": 418,                   // orologio logico: max(visto) + 1
  "seq": 57,                        // numero progressivo del dispositivo (per «visto fino a»)
  "data": "2026-11-04T10:12:33Z",   // solo per l'utente e per ordinare a parità di lamport, mai per decidere
  "base": 12,                       // generazione dell'istantanea su cui l'iPhone lavorava
  "entita": "nota", "entitaId": "nota-1a2b3c4d",
  "tipo": "crea | modificaCampo | elimina",
  "campo": "testo",                 // solo per modificaCampo
  "prima": "…", "dopo": "…"         // valore visto dall'iPhone e valore nuovo (per i conflitti a 3 vie)
}
```
- **Orologio: Lamport + valore «prima».** Basta così, non serve un vector clock: c'è un solo punto di unione, il Mac, e ogni dispositivo scrive solo il proprio giornale. Il vettore «visto fino a» (`dispositivo → seq`) sta nell'istantanea e fa da ricevuta: quando l'iPhone vede che il Mac ha unito fino a `seq` 57, toglie dal giornale le operazioni fino a quella.
- Il giornale è **append-only** nella sostanza: il file si riscrive intero, cifrato, ma si aggiungono solo operazioni e non se ne cambia nessuna. È piccolo (pochi KB) e si scrive nella cartella di iCloud a ogni modifica, con un raggruppamento di 5 s. Così sopravvive anche se il telefono si perde dopo.
- Sul dispositivo il giornale vive anche nell'archivio locale (`archivio.json` + `giornale.json`, con protezione completa), per lavorare offline.

### 4.3 Unione sul Mac
1. Il Mac legge tutti i `giornale-*.cifrato` e scarta le operazioni già viste (id e `seq` ≤ «visto fino a»).
2. Le ordina per (`lamport`, `dispositivo`).
3. Per ogni `modificaCampo` confronta il valore **attuale sul Mac** con `prima`:
   - se sono uguali, il Mac non ha toccato quel campo: si applica `dopo`;
   - se sono diversi ma l'attuale è già uguale a `dopo`: niente da fare;
   - se sono diversi e diversi da `dopo`: **conflitto** (stessa entità e stesso campo modificati in due posti) → finisce nella coda «Da decidere», con i due valori, le date e il dispositivo. **Si chiede sempre all'utente**, non si sceglie in silenzio. Finché non decide, vale il valore del Mac.
4. `crea` con un id già esistente si scarta (idempotenza). `elimina` di un'entità modificata sul Mac dopo la `base` diventa un conflitto («L'iPhone l'ha eliminata, il Mac l'ha cambiata»).
5. Si salva l'archivio e si scrive l'istantanea nuova con la generazione + 1 e il «visto fino a» aggiornato.
6. L'iPhone scarica l'istantanea e **riapplica sopra** le proprie operazioni con `seq` maggiore di quello visto, cioè quelle fatte nel frattempo. Così non perde il lavoro in corso.

Per farlo non si aggiungono date di modifica a tutte le entità. Serve un modo generico per leggere e scrivere un campo per nome: una tabella esplicita dei campi sincronizzabili per ogni tipo, scritta a mano. Niente riflessione, che sarebbe lenta e fragile. È la parte di codice più lunga del progetto.

### 4.4 Cosa si sincronizza
| Si scrive da iPhone/iPad (giornale) | Solo lettura sul telefono (arriva con l'istantanea) | Non si sincronizza |
|---|---|---|
| Note del taccuino (`Nota`: creare, modificare titolo e testo, fissare, eliminare) | Clienti: anagrafica, profilo, consensi (correggere un dato sensibile da telefono porta più rischi che vantaggi) | Conversazioni con Ruby e la sua memoria (restano sul dispositivo in cui sono nate. Ruby sul telefono usa comunque Qwen del Mac) |
| Attività (`Attivita`: creare, completare, cambiare scadenza o priorità) | Posizioni già confermate, prospetti, valutazioni, Analisi 360, simulazioni | Trascrizioni del copilota (già facoltative sul Mac) e qualsiasi audio (mai salvato) |
| Appuntamenti (creare e spostare) | Parcelle, track record (`raccomandazioni` è immutabile per definizione), schede di adeguatezza | Impostazioni del dispositivo (aspetto, segnalibro, chiave, codice del ponte) |
| Dati raccolti dal cliente: campi del profilo dei bisogni, eventi della linea della vita (`EventoLineaVita`) | Messaggi per i clienti (si preparano sul Mac) | Documenti PDF/originali dei clienti nella prima versione (pesano. Il telefono vede i dati estratti, che stanno nell'archivio). Più avanti: solo quelli aperti di recente, o scelti a mano |
| Schede del copilota (`SessioneCopilota`: le schede riconosciute e il loro stato, il verbale, le attività create) | | Backup (hanno la loro cartella e la loro rotazione) |
| **Posizioni inquadrate** (da Inquadra e capisci: arrivano come *bozza da confermare sul Mac*, mai come posizione definitiva. I calcoli e il canale Alleanza/indipendente li conferma il Mac) | | |

Le cose create sul telefono nascono marcate «da iPhone» e il Mac le mostra in un riquadro «Arrivato da iPhone» nella giornata. È coerente con il principio dell'app di analisi: il telefono raccoglie, il Mac verifica e calcola.

---

## 5. Rischi e limiti

| Rischio | Quanto pesa | Mitigazione |
|---|---|---|
| **Dimensione dell'istantanea** | `archivio.json` è JSON con `prettyPrinted`: con 30-50 clienti reali si stimano pochi MB, che compressi e cifrati diventano meno di 1-2 MB. Con i Documenti si sale a decine o centinaia di MB | Prima versione **senza** `Documenti/` e senza `Ruby/`. Codifica senza `prettyPrinted` per l'istantanea. iOS legge a flusso (CifraturaBackup lavora già a segmenti da 1 MiB), quindi nessun picco di memoria |
| **iCloud duplica i file in conflitto** («istantanea 2.cifrato») | Basso grazie a un solo scrittore per file. Può comunque succedere: due Mac con lo stesso spazio, l'iPhone reinstallato con lo stesso id, l'orologio di iCloud confuso | All'elenco si cercano `<nome> <n>.cifrato`. Per i giornali: si leggono **tutte** le copie, che grazie agli id delle operazioni si uniscono senza doppioni, poi si eliminano. Per l'istantanea: vince la generazione più alta scritta *dentro* il file (non la data del file); le altre vanno in `Conflitti/` e si avvisa. `NSFileVersion.unresolvedConflictVersionsOfItem` va provato sul File Provider, senza contarci |
| **Latenza** | iCloud Drive carica e scarica in secondi o minuti. In risparmio energetico, con dati cellulari disattivati per iCloud Drive o con poca rete, anche ore | Interfaccia sincera: «Istantanea del Mac: oggi alle 10:12 · 2 modifiche in attesa di arrivare al Mac». Pulsante «Aggiorna». A Mac acceso e sulla stessa rete, il ponte già cifrato (`ServerPonteRuby`) può avvisare l'iPhone che c'è un'istantanea nuova: è solo un segnale, i dati passano sempre dal file |
| **Batteria e memoria** | FSEvents sul Mac costa poco. PBKDF2 una volta per sessione, poi la chiave dal Portachiavi. Scritture raggruppate | Mai controlli continui a schermo spento. Su iOS nessun lavoro in background. Sul Mac (8 GB) zip e cifratura a flusso, come per i backup |
| **Orologi diversi** | Lamport e `seq` decidono. La `data` serve solo all'utente | Nessuna decisione presa in base all'ora |
| **Privacy e regole del progetto** | CLAUDE.md dice «tutto resta in locale» e «mai inviati a servizi esterni». Il file in iCloud è un'eccezione, anche se già oggi la cartella dei backup può stare su iCloud Drive | Funzione **spenta di default** e attivata solo con una scelta esplicita, che spieghi cosa va in iCloud (solo byte cifrati) e cosa no. Passphrase solo dell'utente. Si consiglia la Protezione avanzata dei dati di iCloud. La decisione finale è dell'utente e va aggiornata in CLAUDE.md |
| **TCC e firma ad-hoc sul Mac** | Possibile richiesta di permesso dopo ogni aggiornamento | Messaggio chiaro e pulsante «Scegli di nuovo la cartella» |
| **iPhone perso o reinstallato prima dell'unione** | Le modifiche non unite si perdono solo se il giornale non era ancora arrivato a iCloud | Giornale scritto nella cartella entro 5 s da ogni modifica. Indicatore «in attesa» visibile |
| **Due Mac** | Fuori progetto | `prisma-ovunque.json` registra l'id del Mac proprietario. Un secondo Mac apre solo in lettura |

### Cosa non si può provare in CI e come si prova invece
- **Non si prova in CI:** iCloud vero (account, `fileproviderd`, file «dataless», duplicati generati da Apple, latenza), le domande di TCC, il selettore di cartelle su un dispositivo vero, il Portachiavi con la firma di AltStore o Sideloadly, il rinnovo a 7 giorni. Il simulatore della CI non ha un account iCloud e non ha la firma vera.
- **Si prova in CI, con una nuova `Prisma --prova-ovunque`** (accanto a `--prova-backup`, nello stesso stile delle `ProvaBackup*.swift`). Due archivi in due cartelle temporanee (il «Mac» e l'«iPhone») e una terza cartella locale al posto di iCloud Drive, dietro un piccolo protocollo `CartellaCondivisa` (elenca, leggi coordinato, sostituisci coordinato). In produzione lo realizza la cartella vera; nella prova, una cartella locale che può anche **fingere** iCloud: ritardi, file «non scaricato», copia `nome 2`, file troncato. Casi da coprire:
  1. andata e ritorno: istantanea Mac → iPhone → nota e attività create → giornale → unione → istantanea nuova → l'iPhone vede le proprie modifiche confermate e svuota il giornale;
  2. idempotenza: lo stesso giornale unito due volte dà lo stesso archivio;
  3. conflitto sullo stesso campo: va nella coda «Da decidere» e il valore del Mac resta;
  4. campi diversi della stessa entità: nessun conflitto;
  5. `elimina` contro una modifica: conflitto;
  6. duplicato `giornale-x 2.cifrato`: unito senza doppioni;
  7. passphrase sbagliata (`passwordErrata`), file troncato o riordinato (`backupDanneggiato`), generazione cambiata;
  8. riapplicazione delle operazioni dell'iPhone dopo un'istantanea nuova;
  9. nessuna nota o attività in chiaro nella cartella condivisa (si cerca un testo noto nei byte).
  Va eseguita sia sul Mac sia nel simulatore iOS (`Supporto/iOS/prove.sh`), dove si prova anche la scrittura con `ScrittoreZip`.
- **A mano, una volta, sul Mac e sull'iPhone di Denis**, con una lista di 10 passi: scelta della cartella, prima istantanea, iPhone in modalità aereo con nota scritta, ritorno in rete, unione, rinnovo con AltStore, nuovo controllo del segnalibro e della chiave.

---

## 6. Conclusione

**Fattibile: sì, con limiti.**

Gli ostacoli tecnici sembravano tre e nessuno blocca davvero:
- l'iPhone con firma gratuita **può** aprire una cartella di iCloud Drive senza entitlement, con il selettore, il security scope e il segnalibro;
- il Mac non sandboxed può scriverci, con la coordinazione e FSEvents;
- la cifratura esiste già.

I limiti veri:
- nessun avviso a app chiusa su iPhone;
- latenza decisa da iCloud;
- cartella e passphrase da riscegliere dopo una reinstallazione o un cambio di ID Apple;
- possibili richieste di TCC dopo gli aggiornamenti ad-hoc del Mac;
- un'eccezione esplicita alla regola «niente cloud», da far decidere all'utente.

### Piano proposto
1. **Cifratura a chiave dello spazio:** `CifraturaBackup` con `algoritmo = 2` (chiave madre da PBKDF2 con il sale dello spazio, chiavi dei file con HKDF). Portachiavi su iOS (`WhenUnlockedThisDeviceOnly`, non sincronizzabile) e su Mac («Prisma ovunque»).
2. **`CartellaCondivisa`:** segnalibro (normale sul Mac, con security scope su iOS), lettura e sostituzione coordinate, file non scaricati (`.icloud` e «dataless»), FSEvents sul Mac e controllo all'attivazione su iOS.
3. **Istantanea dal Mac** (archivio senza Documenti e Ruby, con la generazione e «visto fino a»), scritta in modo raggruppato. Sull'iPhone sostituisce l'apertura manuale del backup: `AperturaBackup` diventa «Collega la cartella di Prisma ovunque».
4. **Giornale per dispositivo** (Lamport, `seq`, `prima`/`dopo`) per note, attività, appuntamenti, dati raccolti, copilota e bozze di posizioni inquadrate. Unione sul Mac con la coda «Da decidere» per i conflitti.
5. **`Prisma --prova-ovunque` nel workflow** (Mac e simulatore iOS) con due archivi e una cartella locale che finge iCloud. Poi una prova a mano di 10 passi sui dispositivi veri.
6. **Interfaccia e regole:** funzione spenta di default, stato sempre visibile («ultima istantanea», «modifiche in attesa»), Documenti in una fase successiva, CLAUDE.md aggiornato con l'eccezione approvata dall'utente.
