# Valutazione

Casi di prova con il risultato atteso, per misurare la qualità di Vera e confrontare i motori. Mai dati veri di clienti.

## La palestra della trattativa (`palestra.json`)
Dieci casi per la valutazione manuale della palestra (Design/template-luce-specifica.md §5.3.5), con un profilo inventato (52 anni, impiegato, teme i soldi bloccati e il rischio dei mercati). I testi sono **di prova**: l'utente li approva o li riscrive.

Per ogni caso: la difficoltà, l'obiezione del cliente, la risposta del consulente, il giudizio più alto che le regole di Prisma concedono (`regoleMassimo`) e cosa ci si aspetta da Qwen (`atteso`).

- **La parte automatica**: `Prisma --prova-vera` (`ProvaPalestraVera`) legge il file dal pacchetto e controlla che le regole di Prisma diano proprio `regoleMassimo` per ognuno dei dieci casi.
- **La parte a mano**, sul Mac con Qwen pronto: Studio › Palestra › «Profilo inventato» con età, lavoro e timori del file, la difficoltà del caso; alla prima obiezione si scrive la risposta del caso nel campo libero. Poi si compila `esito`: il giudizio di Qwen, quello mostrato (mai più alto di `regoleMassimo`), se la replica resta nel ruolo del cliente, se è comparsa una cifra inventata, una nota. L'obiezione di Qwen non sarà identica a quella del file: conta che sia dello stesso tipo.
- Dieci casi su dieci con il giudizio mostrato ≤ `regoleMassimo`, nessuna cifra inventata arrivata sullo schermo e almeno nove repliche nel ruolo: la palestra è pronta.
