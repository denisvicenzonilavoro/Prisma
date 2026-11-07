Leggi la frase di un consulente finanziario italiano e capisci se è uno scenario «E se…?» su un cliente: cosa succederebbe se cambiasse qualcosa (l'età della pensione, il versamento al mese, un capitale in più o in meno, il rendimento, la durata, la copertura). Rispondi solo con un oggetto JSON, senza altro testo, con questi campi:

- scenario: true se la frase è uno scenario su un cliente; false se è un'altra domanda.
- cliente: il cliente come è scritto nella frase («Marco», «Bianchi»); "" se non è nominato (allora vale il cliente attivo del CONTESTO).
- area: previdenza (pensione, fondo pensione, PIP, TFR), investimenti (capitale investito, portafoglio, mercati), risparmio (piano di accumulo, obiettivo, casa, studi dei figli), protezione (caso morte, TCM, sostegno alla famiglia); "nessuna" se non si capisce.
- etaPensione: l'età a cui va in pensione nello scenario. Se la frase dice «due anni prima» o «due anni dopo», ricavala dall'età di pensione del CONTESTO.
- versamentoMensile: il nuovo versamento al mese, in euro.
- variazioneVersamento: solo se la frase dice di quanto cambia il versamento al mese («100 € in più» → 100, «50 € in meno» → -50).
- smetteDiVersare: true se smette di versare o sospende i versamenti.
- capitale: un capitale in più (positivo: un'eredità, un premio, un versamento aggiuntivo) o in meno (negativo: un ritiro, un riscatto, una spesa), in euro. In protezione è il capitale caso morte in più o in meno.
- rendimento: il rendimento annuo in percentuale («al 2%» → 2).
- durata: gli anni dell'orizzonte («per 10 anni», «tra 15 anni»); in protezione gli anni di sostegno alla famiglia.
- mancanti: i dati indispensabili che mancano: "cliente" se non c'è né nella frase né nel CONTESTO, "area" se non si capisce, "cambiamento" se non si capisce cosa cambia.

Regole:
- Scrivi solo i campi numerici che la frase dice (o che ricavi dall'età di pensione del CONTESTO). Se un dato non c'è, non scriverlo: non inventare.
- Importi come numeri, senza simboli né punti delle migliaia: «50 mila euro» → 50000, «1.500 €» → 1500.
- Non fare conti sui soldi e non stimare risultati: i calcoli li fa Prisma.

Esempi:
Frase: E se Marco va in pensione a 63 anni e smette di versare?
{"scenario":true,"cliente":"Marco","area":"previdenza","etaPensione":63,"smetteDiVersare":true,"mancanti":[]}
Frase: Cosa succede se Laura mette altri 20.000 € negli investimenti per 10 anni al 4%?
{"scenario":true,"cliente":"Laura","area":"investimenti","capitale":20000,"durata":10,"rendimento":4,"smetteDiVersare":false,"mancanti":[]}
Frase: E se versasse 100 € in più al mese?
{"scenario":true,"cliente":"","area":"nessuna","variazioneVersamento":100,"smetteDiVersare":false,"mancanti":["area"]}
Frase: Cos'è un PIP?
{"scenario":false,"cliente":"","area":"nessuna","smetteDiVersare":false,"mancanti":[]}
