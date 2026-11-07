# Formato delle domande per l'esame OCF («prisma-domande-ocf», versione 1)

Le domande per l'allenamento (**Studio › Esame OCF**) le importa il consulente nel suo archivio locale, da un file **CSV** o **JSON**. Prisma ne contiene solo sette **di esempio**, scritte apposta (`Sources/Prisma/Risorse/ocf-esempio.json`): nessun testo è copiato da manuali o da quiz ufficiali. Il file non contiene mai dati dei clienti.

Prima di salvare si vede un riepilogo, per esempio:

> 240 domande nuove · 12 aggiornate · 3 uguali · 3 righe scartate: riga 12 (manca la risposta corretta), …

Le domande entrano nell'archivio (`DatiPrisma.ocf`, versione 26) e quindi nel backup. Reimportare lo stesso file non crea doppioni. Una domanda con lo stesso `id` e un contenuto diverso si aggiorna, e lo storico delle risposte resta.

Codice:
- `Dati/EsameOCF.swift`: materie, domande, risposte, archivio;
- `Motori/ImportaOCF.swift`: importazione;
- `Motori/MotoreOCF.swift`: ripasso, preparazione, caso vero;
- `Motori/TestiOCF.swift`: testi.

Prove: `Motori/ProvaCalcoliOCF.swift` e `Dati/ProvaBackupFamiglieOCF.swift`.

## CSV

- Va bene da Excel o Numbers.
- Codifica UTF-8 (anche con BOM) oppure Latin-1.
- Separatore `;`, `,` o tabulazione.
- La prima riga è l'intestazione. Le colonne si riconoscono dal nome, in qualunque ordine.

Esempio minimo:

```
id;materia;domanda;a;b;c;d;corretta;spiegazione;fonte;caso
MAT-1;Matematica finanziaria;100 € al 10% composto per 2 anni diventano:;120 €;121 €;110 €;200 €;B;100 × 1,1 × 1,1 = 121 €.;Appunti;
```

| Colonna (nomi accettati) | Obbligatoria | Regola |
|---|---|---|
| `id` (`codice`) | no | codice stabile. Se manca, Prisma lo ricava da materia e testo, così reimportare non crea doppioni |
| `materia` | sì | il codice o il nome della materia, senza badare a maiuscole e accenti; una materia che non c'è ancora si aggiunge (si vede nel riepilogo) |
| `domanda` (`testo`) | sì | testo; con `;` dentro va tra virgolette |
| `a` `b` `c` `d` (`risposta a`…) | sì | le quattro risposte, non vuote e diverse tra loro |
| `corretta` (`giusta`, `soluzione`) | sì | `A`-`D` (anche minuscole) oppure `1`-`4` |
| `spiegazione` | no | mostrata dopo la risposta |
| `fonte` (`appunti`, `riferimento`) | no | manuale, norma, pagina; se manca, il nome del file |
| `caso` | no | il tipo di caso dei clienti (vedi sotto); un valore sconosciuto si ignora |

La riga 1 è l'intestazione; le righe vuote non contano.

## JSON

Esempio minimo:

```json
{
  "formato": "prisma-domande-ocf",
  "versione": 1,
  "fonte": "I miei appunti",
  "materie": [
    { "id": "matematica", "nome": "Matematica finanziaria" },
    { "id": "previdenza", "nome": "Previdenza", "caso": "previdenzaComplementare" }
  ],
  "domande": [
    {
      "id": "MAT-1",
      "materia": "matematica",
      "testo": "100 € al 10% composto per 2 anni diventano:",
      "risposte": ["120 €", "121 €", "110 €", "200 €"],
      "corretta": 1,
      "spiegazione": "100 × 1,1 × 1,1 = 121 €.",
      "fonte": null,
      "caso": null
    }
  ]
}
```

- `formato` e `versione` sono obbligatori.
- `materie` è facoltativo: dichiara nomi e caso delle materie nuove.
- `corretta` è l'**indice da 0** (0 = A … 3 = D) oppure la lettera (`"B"`).
- Il numero di una domanda scartata conta le domande dell'elenco, da 1.

## Il tipo di caso (`caso`)

Collega una domanda (o una materia) a un esempio vero dell'archivio. Prisma propone l'esempio con il nome del cliente; se non trova niente, il pulsante non compare.

| `caso` | Esempio cercato (in essere, non scaduto) |
|---|---|
| `gestioneSeparata` | polizza rivalutabile di Ramo I |
| `multiramo` | polizza multiramo |
| `fondo` | fondo, ETF o titoli |
| `previdenzaComplementare` | PIP o fondo pensione |
| `casoMorte` | temporanea caso morte |
| `protezioneDanni` | infortuni, invalidità, salute, LTC, casa, RC |
| `kid` | un KID tra i documenti dei clienti |

Ordine di scelta:
1. il cliente attivo;
2. poi la posizione di valore più alto (per la protezione, il capitale assicurato più alto);
3. per i KID, il più recente.

Il caso della domanda prevale su quello della materia.

## Errori

**Righe scartate.** La riga si scarta e il motivo compare nel riepilogo, per esempio:
- materia mancante;
- domanda vuota;
- meno o più di quattro risposte;
- una risposta vuota («manca la risposta C»);
- due risposte uguali;
- risposta corretta mancante o non valida;
- id ripetuto nel file;
- in JSON, una domanda illeggibile.

**File rifiutato.** Tutto il file si rifiuta e l'archivio resta com'era quando:
- il file è illeggibile o il JSON non è valido;
- il formato non è riconosciuto;
- la versione manca o non è riconosciuta;
- nel CSV mancano colonne obbligatorie («Nell'intestazione del CSV mancano le colonne: c, d, corretta.»);
- il file non contiene domande.

## Ripasso e preparazione

**Ripasso.** Per giorni di calendario, a intervalli di 1, 3, 7, 14 e 30 giorni:
- una risposta sbagliata riporta la domanda a 1 giorno;
- una giusta, alla data del ripasso o dopo, la fa salire di un passo, fino a 30 giorni;
- una giusta prima della data non cambia niente;
- una domanda nuova giusta al primo colpo parte da 3 giorni.

**Preparazione.**
- Per materia: la quota di domande giuste all'ultima risposta, con almeno 5 domande risposte.
- Complessiva: la media delle materie che hanno una percentuale.
- Fasce: verde da 70, arancio da 55, rossa sotto.

**Domande di oggi.**
1. Prima quelle del ripasso scaduto, dalla più in ritardo.
2. Poi le nuove, 10 al giorno: a rotazione, cominciando dalla materia più debole.
