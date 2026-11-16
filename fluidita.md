### Fluidità · commit 700aa08

Tempi del thread principale. Mediana e massimo = aggiornamento (mediana e massimo su 3 giri, 2 con le app pesanti, dopo un giro di riscaldamento) + un disegno per azione. Aggiornamento = azione, run loop e impaginazione; disegno = cacheDisplay completo; prima volta = aggiornamento del giro di riscaldamento; corpi = body rivalutati delle viste che leggono StatoShell (con Observation, al posto degli objectWillChange di prima); avvisi StatoFinestre = proprietà osservate di StatoFinestre cambiate (shell, dock, barra, pannelli) durante l'azione.

| Scenario | Azione | Mediana | Massimo | Aggiornamento | Disegno | Prima volta | Corpi rivalutati | Avvisi StatoFinestre |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| 5 clienti | avvio (stato, dati e primo disegno) | 303 ms | 1075 ms | 303 ms | — | — | — | — |
| 5 clienti | apri Clienti | 245 ms | 281 ms | 245 ms | — | 489 ms | 24 | 3 |
| 5 clienti | chiudi Clienti | 55 ms | 56 ms | 55 ms | — | 105 ms | 6 | 2 |
| 5 clienti | apri Posizioni | 419 ms | 510 ms | 419 ms | — | 441 ms | 15 | 3 |
| 5 clienti | chiudi Posizioni | 47 ms | 57 ms | 47 ms | — | 45 ms | 6 | 2 |
| 5 clienti | apri Analisi 360 | 140 ms | 158 ms | 140 ms | — | 175 ms | 11 | 3 |
| 5 clienti | chiudi Analisi 360 | 40 ms | 48 ms | 40 ms | — | 49 ms | 6 | 2 |
| 5 clienti | apri Incontri | 106 ms | 107 ms | 106 ms | — | 207 ms | 14 | 3 |
| 5 clienti | chiudi Incontri | 35 ms | 41 ms | 35 ms | — | 36 ms | 6 | 2 |
| 5 clienti | apri Agenda | 149 ms | 209 ms | 149 ms | — | 150 ms | 15 | 3 |
| 5 clienti | chiudi Agenda | 53 ms | 77 ms | 53 ms | — | 49 ms | 6 | 2 |
| 5 clienti | apri Messaggi | 129 ms | 147 ms | 129 ms | — | 156 ms | 16 | 3 |
| 5 clienti | chiudi Messaggi | 52 ms | 72 ms | 52 ms | — | 37 ms | 6 | 2 |
| 5 clienti | apri Pratiche | 94 ms | 113 ms | 94 ms | — | 171 ms | 13 | 3 |
| 5 clienti | chiudi Pratiche | 43 ms | 57 ms | 43 ms | — | 51 ms | 6 | 2 |
| 5 clienti | apri Prospetti e report | 99 ms | 105 ms | 99 ms | — | 168 ms | 10 | 3 |
| 5 clienti | chiudi Prospetti e report | 45 ms | 46 ms | 45 ms | — | 39 ms | 6 | 2 |
| 5 clienti | apri Sala | 89 ms | 93 ms | 89 ms | — | 122 ms | 16 | 3 |
| 5 clienti | chiudi Sala | 36 ms | 40 ms | 36 ms | — | 37 ms | 7 | 2 |
| 5 clienti | apri Biblioteca | 56 ms | 62 ms | 56 ms | — | 115 ms | 10 | 3 |
| 5 clienti | chiudi Biblioteca | 33 ms | 39 ms | 33 ms | — | 35 ms | 6 | 2 |
| 5 clienti | apri Mercato | 84 ms | 85 ms | 84 ms | — | 120 ms | 35 | 3 |
| 5 clienti | chiudi Mercato | 36 ms | 42 ms | 36 ms | — | 37 ms | 6 | 2 |
| 5 clienti | apri Studio | 73 ms | 91 ms | 73 ms | — | 114 ms | 12 | 3 |
| 5 clienti | chiudi Studio | 42 ms | 42 ms | 42 ms | — | 34 ms | 6 | 2 |
| 5 clienti | apri Vera | 89 ms | 92 ms | 89 ms | — | 133 ms | 15 | 3 |
| 5 clienti | chiudi Vera | 32 ms | 41 ms | 32 ms | — | 47 ms | 6 | 2 |
| 5 clienti | apri Impostazioni | 95 ms | 104 ms | 95 ms | — | 155 ms | 8 | 3 |
| 5 clienti | chiudi Impostazioni | 32 ms | 40 ms | 32 ms | — | 37 ms | 6 | 2 |
| 5 clienti | passa all'app sotto (2 aperte) | 40 ms | 46 ms | 40 ms | — | 163 ms | 8 | 2 |
| 5 clienti | riduci Posizioni | 110 ms | 117 ms | 110 ms | — | 160 ms | 8 | 3 |
| 5 clienti | ripristina Posizioni | 112 ms | 144 ms | 112 ms | — | 156 ms | 8 | 3 |
| 5 clienti | riduci a finestra Clienti | 75 ms | 101 ms | 75 ms | — | 102 ms | 4 | 3 |
| 5 clienti | ingrandisci Clienti | 52 ms | 58 ms | 52 ms | — | 48 ms | 4 | 2 |
| 5 clienti | blocca (schermata di benvenuto) | 17 ms | 18 ms | 17 ms | — | 51 ms | 7 | 2 |
| 5 clienti | sblocca | 11 ms | 20 ms | 11 ms | — | 13 ms | 5 | 2 |
| 5 clienti | apri il centro notifiche | 111 ms | 114 ms | 111 ms | — | 120 ms | 1 | 1 |
| 5 clienti | chiudi il centro notifiche | 22 ms | 25 ms | 22 ms | — | 22 ms | 0 | 1 |
| 5 clienti | apri la ricerca (⌘K) | 97 ms | 203 ms | 97 ms | — | 106 ms | 5 | 1 |
| 5 clienti | chiudi la ricerca (⌘K) | 27 ms | 36 ms | 27 ms | — | 29 ms | 0 | 1 |
| 5 clienti | aspetto scuro | 405 ms | 434 ms | 405 ms | — | 480 ms | 9 | 0 |
| 5 clienti | aspetto chiaro | 386 ms | 455 ms | 386 ms | — | 413 ms | 9 | 0 |
| 5 clienti | modifica una nota (un tasto) | 33 ms | 36 ms | 33 ms | — | 38 ms | 1 | 0 |
| 5 clienti | annulla la modifica | 39 ms | 40 ms | 39 ms | — | 37 ms | 1 | 0 |
| 5 clienti | mostra la scrivania | 208 ms | 211 ms | 208 ms | — | 200 ms | 9 | 4 |
| 5 clienti | riapri le app (2) | 186 ms | 205 ms | 186 ms | — | 189 ms | 9 | 6 |
| 5 clienti | sposta Clienti (un passo) | 9 ms | 12 ms | 9 ms | — | 31 ms | 4 | 1 |
| 5 clienti | Luce · apri la Sala | 88 ms | 116 ms | 88 ms | — | 103 ms | 15 | 3 |
| 5 clienti | Luce · chiudi la Sala | 40 ms | 43 ms | 40 ms | — | 120 ms | 6 | 2 |
| 5 clienti | Luce · apri il prisma di luce | 77 ms | 86 ms | 77 ms | — | 137 ms | 17 | 3 |
| 5 clienti | Luce · chiudi il prisma di luce | 162 ms | 170 ms | 162 ms | — | 125 ms | 15 | 2 |
| 5 clienti | Luce · apri Pratiche | 111 ms | 116 ms | 111 ms | — | 98 ms | 12 | 3 |
| 5 clienti | Luce · chiudi Pratiche | 47 ms | 50 ms | 47 ms | — | 56 ms | 5 | 2 |
| 5 clienti | apri gli spazi di lavoro | 76 ms | 86 ms | 76 ms | — | 188 ms | 1 | 1 |
| 5 clienti | chiudi gli spazi di lavoro | 17 ms | 18 ms | 17 ms | — | 16 ms | 0 | 1 |
| 5 clienti | apri il menu delle app | 17 ms | 25 ms | 17 ms | — | 66 ms | 1 | 1 |
| 5 clienti | chiudi il menu delle app | 8 ms | 9 ms | 8 ms | — | 8 ms | 0 | 1 |
| 5 clienti | apri «Le tue app aperte» | 31 ms | 35 ms | 31 ms | — | 40 ms | 5 | 1 |
| 5 clienti | chiudi «Le tue app aperte» | 14 ms | 17 ms | 14 ms | — | 9 ms | 0 | 1 |
| 200 clienti | avvio (stato, dati e primo disegno) | 1026 ms | 1035 ms | 1026 ms | — | — | — | — |
| 200 clienti | apre 4 app pesanti (prima volta) | 931 ms | 931 ms | 931 ms | — | — | 229 | 12 |
| 200 clienti | chiudi Clienti | 56 ms | 59 ms | 56 ms | — | 58 ms | 8 | 2 |
| 200 clienti | apri Clienti | 210 ms | 210 ms | 210 ms | — | 177 ms | 17 | 3 |
| 200 clienti | chiudi Posizioni | 58 ms | 58 ms | 58 ms | — | 34 ms | 8 | 2 |
| 200 clienti | apri Posizioni | 251 ms | 256 ms | 251 ms | — | 261 ms | 14 | 3 |
| 200 clienti | apri Analisi 360 | 66 ms | 69 ms | 66 ms | — | 85 ms | 12 | 3 |
| 200 clienti | chiudi Analisi 360 | 51 ms | 60 ms | 51 ms | — | 58 ms | 9 | 2 |
| 200 clienti | apri Incontri | 394 ms | 400 ms | 394 ms | — | 455 ms | 17 | 3 |
| 200 clienti | chiudi Incontri | 98 ms | 101 ms | 98 ms | — | 104 ms | 9 | 2 |
| 200 clienti | chiudi Agenda | 84 ms | 90 ms | 84 ms | — | 60 ms | 8 | 2 |
| 200 clienti | apri Agenda | 335 ms | 375 ms | 335 ms | — | 371 ms | 212 | 3 |
| 200 clienti | apri Messaggi | 156 ms | 158 ms | 156 ms | — | 230 ms | 16 | 3 |
| 200 clienti | chiudi Messaggi | 47 ms | 48 ms | 47 ms | — | 48 ms | 6 | 2 |
| 200 clienti | apri Pratiche | 184 ms | 203 ms | 184 ms | — | 371 ms | 13 | 3 |
| 200 clienti | chiudi Pratiche | 49 ms | 58 ms | 49 ms | — | 45 ms | 6 | 2 |
| 200 clienti | chiudi Prospetti e report | 33 ms | 35 ms | 33 ms | — | 40 ms | 5 | 2 |
| 200 clienti | apri Prospetti e report | 55 ms | 65 ms | 55 ms | — | 60 ms | 8 | 3 |
| 200 clienti | apri Sala | 56 ms | 57 ms | 56 ms | — | 49 ms | 16 | 3 |
| 200 clienti | chiudi Sala | 37 ms | 39 ms | 37 ms | — | 42 ms | 6 | 2 |
| 200 clienti | apri Biblioteca | 91 ms | 95 ms | 91 ms | — | 130 ms | 10 | 3 |
| 200 clienti | chiudi Biblioteca | 48 ms | 49 ms | 48 ms | — | 58 ms | 6 | 2 |
| 200 clienti | apri Mercato | 116 ms | 133 ms | 116 ms | — | 152 ms | 35 | 3 |
| 200 clienti | chiudi Mercato | 40 ms | 40 ms | 40 ms | — | 51 ms | 6 | 2 |
| 200 clienti | apri Studio | 116 ms | 133 ms | 116 ms | — | 100 ms | 12 | 3 |
| 200 clienti | chiudi Studio | 45 ms | 50 ms | 45 ms | — | 37 ms | 6 | 2 |
| 200 clienti | apri Vera | 126 ms | 130 ms | 126 ms | — | 125 ms | 15 | 3 |
| 200 clienti | chiudi Vera | 53 ms | 57 ms | 53 ms | — | 57 ms | 6 | 2 |
| 200 clienti | apri Impostazioni | 115 ms | 119 ms | 115 ms | — | 110 ms | 8 | 3 |
| 200 clienti | chiudi Impostazioni | 50 ms | 53 ms | 50 ms | — | 48 ms | 6 | 2 |
| 200 clienti | passa all'app sotto (4 aperte) | 49 ms | 54 ms | 49 ms | — | 60 ms | 12 | 2 |
| 200 clienti | riduci Posizioni | 77 ms | 79 ms | 77 ms | — | 70 ms | 9 | 3 |
| 200 clienti | ripristina Posizioni | 77 ms | 78 ms | 77 ms | — | 89 ms | 9 | 3 |
| 200 clienti | riduci a finestra Clienti | 52 ms | 55 ms | 52 ms | — | 94 ms | 9 | 3 |
| 200 clienti | ingrandisci Clienti | 44 ms | 45 ms | 44 ms | — | 50 ms | 6 | 2 |
| 200 clienti | blocca (schermata di benvenuto) | 40 ms | 41 ms | 40 ms | — | 47 ms | 7 | 2 |
| 200 clienti | sblocca | 26 ms | 28 ms | 26 ms | — | 24 ms | 5 | 2 |
| 200 clienti | apri il centro notifiche | 168 ms | 192 ms | 168 ms | — | 197 ms | 1 | 1 |
| 200 clienti | chiudi il centro notifiche | 45 ms | 47 ms | 45 ms | — | 42 ms | 0 | 1 |
| 200 clienti | apri la ricerca (⌘K) | 126 ms | 191 ms | 126 ms | — | 73 ms | 5 | 1 |
| 200 clienti | chiudi la ricerca (⌘K) | 56 ms | 61 ms | 56 ms | — | 67 ms | 0 | 1 |
| 200 clienti | aspetto scuro | 419 ms | 436 ms | 419 ms | — | 436 ms | 11 | 0 |
| 200 clienti | aspetto chiaro | 415 ms | 479 ms | 415 ms | — | 417 ms | 11 | 0 |
| 200 clienti | modifica una nota (un tasto) | 6 ms | 7 ms | 6 ms | — | 7 ms | 0 | 0 |
| 200 clienti | annulla la modifica | 6 ms | 7 ms | 6 ms | — | 6 ms | 0 | 0 |
| 200 clienti | mostra la scrivania | 181 ms | 190 ms | 181 ms | — | 313 ms | 13 | 4 |
| 200 clienti | riapri le app (4) | 158 ms | 179 ms | 158 ms | — | 153 ms | 13 | 12 |
| 200 clienti | sposta Clienti (un passo) | 30 ms | 31 ms | 30 ms | — | 58 ms | 6 | 1 |
| 200 clienti | Luce · apri la Sala | 64 ms | 72 ms | 64 ms | — | 84 ms | 19 | 3 |
| 200 clienti | Luce · chiudi la Sala | 56 ms | 65 ms | 56 ms | — | 60 ms | 9 | 2 |
| 200 clienti | Luce · apri il prisma di luce | 133 ms | 142 ms | 133 ms | — | 1018 ms | 19 | 3 |
| 200 clienti | Luce · chiudi il prisma di luce | 209 ms | 224 ms | 209 ms | — | 261 ms | 17 | 2 |
| 200 clienti | Luce · apri Pratiche | 119 ms | 127 ms | 119 ms | — | 131 ms | 14 | 3 |
| 200 clienti | Luce · chiudi Pratiche | 63 ms | 66 ms | 63 ms | — | 57 ms | 7 | 2 |
| 200 clienti | apri gli spazi di lavoro | 80 ms | 81 ms | 80 ms | — | 90 ms | 1 | 1 |
| 200 clienti | chiudi gli spazi di lavoro | 37 ms | 39 ms | 37 ms | — | 35 ms | 0 | 1 |
| 200 clienti | apri il menu delle app | 28 ms | 34 ms | 28 ms | — | 48 ms | 1 | 1 |
| 200 clienti | chiudi il menu delle app | 16 ms | 18 ms | 16 ms | — | 18 ms | 0 | 1 |
| 200 clienti | apri «Le tue app aperte» | 51 ms | 56 ms | 51 ms | — | 60 ms | 9 | 1 |
| 200 clienti | chiudi «Le tue app aperte» | 29 ms | 32 ms | 29 ms | — | 26 ms | 0 | 1 |

Disegno non disponibile sul server di build: misurato solo l'aggiornamento.
Memoria: all'inizio: 137 MB residenti, 115 MB di impronta · 5 clienti, dopo l'avvio: 250 MB residenti, 234 MB di impronta · 5 clienti, dopo il giro delle app: 310 MB residenti, 225 MB di impronta · 5 clienti, alla fine (shell aperta): 518 MB residenti, 302 MB di impronta · dopo lo scenario con 5 clienti (shell chiusa): 433 MB residenti, 195 MB di impronta · 200 clienti, dopo l'avvio: 480 MB residenti, 288 MB di impronta · 200 clienti, dopo il giro delle app: 577 MB residenti, 306 MB di impronta · 200 clienti, alla fine (shell aperta): 587 MB residenti, 313 MB di impronta · dopo lo scenario con 200 clienti (shell chiusa): 534 MB residenti, 219 MB di impronta.

Memoria alla fine: 534 MB residenti, 219 MB di impronta · durata della prova: 88.0 s.
