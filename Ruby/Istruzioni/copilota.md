Leggi un pezzo della trascrizione di un incontro tra un consulente finanziario italiano e il suo cliente (solo testo, riconosciuto sul dispositivo). Trova le cose che servono al dossier e rispondi solo con un oggetto JSON, senza altro testo: {"schede": [ ... ]}. Ogni scheda ha:

- tipo: "obiettivo" (qualcosa che il cliente vuole fare o comprare, con un tempo o una cifra), "polizza" (una polizza o un piano che ha già con un'altra compagnia, una banca o un altro intermediario; mai Alleanza), "profilo" (un timore o una preferenza sul rischio), "evento" (un evento della vita: matrimonio, figlio, casa, studi, eredità, anno sabbatico, pensione), "attivita" (una cosa che il consulente dice che farà).
- frase: la frase esatta del pezzo da cui nasce la scheda, copiata parola per parola.
- area (obiettivo e profilo): casa, famiglia, lavoro, pensione, salute, patrimonio; "nessuna" se non si capisce. Per un timore senza area vale l'ultimo obiettivo del CONTESTO.
- importo: la cifra in euro detta nella frase (obiettivo: quanto serve; polizza: il premio). importi: un elenco di cifre («450, 550 e 650 euro» → [450, 550, 650]).
- frequenza: mensile, trimestrale, semestrale, annuale, unica; "nessuna" se non è detta.
- anniDaOggi: «tra tre anni» → 3. anno e mese: «a giugno del 2027» → anno 2027, mese 6.
- tipoPolizza: vita intera, TCM, temporanea caso morte, infortuni, LTC, fondo pensione, PIP, unit linked, multiramo… compagnia: il nome detto; "" se dice solo «un'altra compagnia».
- propensione (profilo): "prudente" per «non voglio rischiare», «senza perdere», «mi fa paura»; "nessuna" negli altri casi. È un'annotazione, non il profilo MiFID.
- evento: matrimonio, casa, figlio, studi, eredita, annoSabbatico, pensione, altro.
- attivita: per le attività, cosa fare in poche parole, all'infinito («Preparare il confronto»).

Regole:
- Scrivi solo le cifre che la frase dice: niente cifre inventate, niente conti, niente stime. Una scheda con un numero che non è nella frase viene scartata.
- Importi come numeri, senza simboli né punti delle migliaia: «40.000 euro» → 40000, «40 mila» → 40000.
- Nessuna scheda per le domande del consulente e per i saluti. Se nel pezzo non c'è niente, rispondi {"schede": []}.
- Una cosa detta due volte («tra tre anni… anzi tra quattro») è una sola scheda con l'ultimo valore.

Esempi:
Pezzo: Vorremmo comprare casa tra tre anni, ci servono circa 40.000 euro di anticipo.
{"schede":[{"tipo":"obiettivo","frase":"Vorremmo comprare casa tra tre anni, ci servono circa 40.000 euro di anticipo","area":"casa","importo":40000,"anniDaOggi":3}]}
Pezzo: Sì, ho una vita intera con un'altra compagnia, pago circa 90 euro al mese.
{"schede":[{"tipo":"polizza","frase":"Sì, ho una vita intera con un'altra compagnia, pago circa 90 euro al mese","tipoPolizza":"vita intera","compagnia":"","importo":90,"frequenza":"mensile"}]}
Pezzo: Lei ha già qualche polizza?
{"schede":[]}
