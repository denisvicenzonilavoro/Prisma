### Fluidità · commit 212c81f

Tempi del thread principale. Mediana e massimo = aggiornamento (mediana e massimo su 3 giri, 2 con le app pesanti, dopo un giro di riscaldamento) + un disegno per azione. Aggiornamento = azione, run loop e impaginazione; disegno = cacheDisplay completo; prima volta = aggiornamento del giro di riscaldamento; corpi = body rivalutati delle viste che leggono StatoShell (con Observation, al posto degli objectWillChange di prima); avvisi StatoFinestre = proprietà osservate di StatoFinestre cambiate (shell, dock, barra, pannelli) durante l'azione.

| Scenario | Azione | Mediana | Massimo | Aggiornamento | Disegno | Prima volta | Corpi rivalutati | Avvisi StatoFinestre |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| 5 clienti | avvio (stato, dati e primo disegno) | 667 ms | 1937 ms | 667 ms | — | — | — | — |
| 5 clienti | apri Clienti | 703 ms | 759 ms | 703 ms | — | 1790 ms | 25 | 3 |
| 5 clienti | chiudi Clienti | 162 ms | 164 ms | 162 ms | — | 155 ms | 6 | 2 |
| 5 clienti | apri Posizioni | 499 ms | 509 ms | 499 ms | — | 857 ms | 16 | 3 |
| 5 clienti | chiudi Posizioni | 141 ms | 146 ms | 141 ms | — | 135 ms | 6 | 2 |
| 5 clienti | apri Analisi 360 | 468 ms | 514 ms | 468 ms | — | 660 ms | 12 | 3 |
| 5 clienti | chiudi Analisi 360 | 96 ms | 105 ms | 96 ms | — | 108 ms | 6 | 2 |
| 5 clienti | apri Incontri | 292 ms | 305 ms | 292 ms | — | 389 ms | 10 | 3 |
| 5 clienti | chiudi Incontri | 101 ms | 144 ms | 101 ms | — | 119 ms | 6 | 2 |
| 5 clienti | apri Agenda | 514 ms | 534 ms | 514 ms | — | 592 ms | 8 | 3 |
| 5 clienti | chiudi Agenda | 132 ms | 136 ms | 132 ms | — | 124 ms | 6 | 2 |
| 5 clienti | apri Messaggi | 222 ms | 253 ms | 222 ms | — | 272 ms | 14 | 3 |
| 5 clienti | chiudi Messaggi | 99 ms | 104 ms | 99 ms | — | 95 ms | 6 | 2 |
| 5 clienti | apri Pratiche | 221 ms | 234 ms | 221 ms | — | 278 ms | 11 | 3 |
| 5 clienti | chiudi Pratiche | 89 ms | 96 ms | 89 ms | — | 82 ms | 6 | 2 |
| 5 clienti | apri Prospetti e report | 464 ms | 511 ms | 464 ms | — | 561 ms | 12 | 3 |
| 5 clienti | chiudi Prospetti e report | 116 ms | 123 ms | 116 ms | — | 109 ms | 6 | 2 |
| 5 clienti | apri Sala | 336 ms | 489 ms | 336 ms | — | 336 ms | 13 | 3 |
| 5 clienti | chiudi Sala | 118 ms | 121 ms | 118 ms | — | 110 ms | 7 | 2 |
| 5 clienti | apri Biblioteca | 176 ms | 183 ms | 176 ms | — | 251 ms | 11 | 3 |
| 5 clienti | chiudi Biblioteca | 106 ms | 114 ms | 106 ms | — | 114 ms | 6 | 2 |
| 5 clienti | apri Mercato | 193 ms | 193 ms | 193 ms | — | 223 ms | 19 | 3 |
| 5 clienti | chiudi Mercato | 102 ms | 103 ms | 102 ms | — | 99 ms | 6 | 2 |
| 5 clienti | apri Studio | 281 ms | 285 ms | 281 ms | — | 311 ms | 10 | 3 |
| 5 clienti | chiudi Studio | 106 ms | 111 ms | 106 ms | — | 111 ms | 6 | 2 |
| 5 clienti | apri Vera | 387 ms | 389 ms | 387 ms | — | 428 ms | 13 | 3 |
| 5 clienti | chiudi Vera | 131 ms | 141 ms | 131 ms | — | 104 ms | 6 | 2 |
| 5 clienti | apri Impostazioni | 283 ms | 292 ms | 283 ms | — | 427 ms | 9 | 3 |
| 5 clienti | chiudi Impostazioni | 115 ms | 117 ms | 115 ms | — | 130 ms | 6 | 2 |
| 5 clienti | passa all'app sotto (2 aperte) | 51 ms | 51 ms | 51 ms | — | 72 ms | 4 | 2 |
| 5 clienti | riduci Posizioni | 87 ms | 93 ms | 87 ms | — | 86 ms | 4 | 3 |
| 5 clienti | ripristina Posizioni | 85 ms | 86 ms | 85 ms | — | 80 ms | 4 | 3 |
| 5 clienti | riduci a finestra Clienti | 350 ms | 362 ms | 350 ms | — | 398 ms | 5 | 3 |
| 5 clienti | ingrandisci Clienti | 224 ms | 229 ms | 224 ms | — | 230 ms | 5 | 2 |
| 5 clienti | blocca (schermata di benvenuto) | 49 ms | 49 ms | 49 ms | — | 90 ms | 7 | 2 |
| 5 clienti | sblocca | 27 ms | 29 ms | 27 ms | — | 27 ms | 5 | 2 |
| 5 clienti | apri il centro notifiche | 109 ms | 127 ms | 109 ms | — | 136 ms | 11 | 1 |
| 5 clienti | chiudi il centro notifiche | 27 ms | 29 ms | 27 ms | — | 32 ms | 0 | 1 |
| 5 clienti | apri la ricerca (⌘K) | 300 ms | 393 ms | 300 ms | — | 123 ms | 4 | 1 |
| 5 clienti | chiudi la ricerca (⌘K) | 31 ms | 81 ms | 31 ms | — | 92 ms | 0 | 1 |
| 5 clienti | aspetto scuro | 762 ms | 804 ms | 762 ms | — | 911 ms | 6 | 0 |
| 5 clienti | aspetto chiaro | 756 ms | 760 ms | 756 ms | — | 870 ms | 6 | 0 |
| 5 clienti | modifica una nota (un tasto) | 4 ms | 6 ms | 4 ms | — | 4 ms | 0 | 0 |
| 5 clienti | annulla la modifica | 5 ms | 6 ms | 5 ms | — | 3 ms | 0 | 0 |
| 5 clienti | mostra la scrivania | 262 ms | 266 ms | 262 ms | — | 287 ms | 8 | 4 |
| 5 clienti | riapri le app (2) | 269 ms | 284 ms | 269 ms | — | 254 ms | 8 | 6 |
| 5 clienti | sposta Clienti (un passo) | 29 ms | 30 ms | 29 ms | — | 23 ms | 4 | 1 |
| 5 clienti | Luce · apri la Sala | 279 ms | 300 ms | 279 ms | — | 281 ms | 11 | 3 |
| 5 clienti | Luce · chiudi la Sala | 73 ms | 82 ms | 73 ms | — | 77 ms | 5 | 2 |
| 5 clienti | Luce · apri il prisma di luce | 270 ms | 278 ms | 270 ms | — | 343 ms | 13 | 3 |
| 5 clienti | Luce · chiudi il prisma di luce | 317 ms | 338 ms | 317 ms | — | 307 ms | 8 | 2 |
| 5 clienti | Luce · apri Pratiche | 196 ms | 198 ms | 196 ms | — | 200 ms | 9 | 3 |
| 5 clienti | Luce · chiudi Pratiche | 60 ms | 61 ms | 60 ms | — | 59 ms | 4 | 2 |
| 5 clienti | apri gli spazi di lavoro | 132 ms | 134 ms | 132 ms | — | 150 ms | 1 | 1 |
| 5 clienti | chiudi gli spazi di lavoro | 36 ms | 39 ms | 36 ms | — | 36 ms | 0 | 1 |
| 5 clienti | apri «Le tue app aperte» | 64 ms | 64 ms | 64 ms | — | 89 ms | 5 | 1 |
| 5 clienti | chiudi «Le tue app aperte» | 25 ms | 26 ms | 25 ms | — | 25 ms | 0 | 1 |
| 200 clienti | avvio (stato, dati e primo disegno) | 1455 ms | 1600 ms | 1455 ms | — | — | — | — |
| 200 clienti | apre 4 app pesanti (prima volta) | 3791 ms | 3791 ms | 3791 ms | — | — | 38 | 12 |
| 200 clienti | chiudi Clienti | 118 ms | 129 ms | 118 ms | — | 108 ms | 5 | 2 |
| 200 clienti | apri Clienti | 715 ms | 746 ms | 715 ms | — | 979 ms | 24 | 3 |
| 200 clienti | chiudi Posizioni | 117 ms | 127 ms | 117 ms | — | 124 ms | 5 | 2 |
| 200 clienti | apri Posizioni | 673 ms | 723 ms | 673 ms | — | 618 ms | 10 | 3 |
| 200 clienti | apri Analisi 360 | 494 ms | 503 ms | 494 ms | — | 505 ms | 12 | 3 |
| 200 clienti | chiudi Analisi 360 | 90 ms | 91 ms | 90 ms | — | 89 ms | 6 | 2 |
| 200 clienti | apri Incontri | 247 ms | 256 ms | 247 ms | — | 258 ms | 10 | 3 |
| 200 clienti | chiudi Incontri | 87 ms | 88 ms | 87 ms | — | 90 ms | 6 | 2 |
| 200 clienti | chiudi Agenda | 119 ms | 131 ms | 119 ms | — | 99 ms | 5 | 2 |
| 200 clienti | apri Agenda | 542 ms | 552 ms | 542 ms | — | 579 ms | 7 | 3 |
| 200 clienti | apri Messaggi | 386 ms | 422 ms | 386 ms | — | 653 ms | 14 | 3 |
| 200 clienti | chiudi Messaggi | 100 ms | 103 ms | 100 ms | — | 97 ms | 6 | 2 |
| 200 clienti | apri Pratiche | 217 ms | 228 ms | 217 ms | — | 797 ms | 11 | 3 |
| 200 clienti | chiudi Pratiche | 79 ms | 81 ms | 79 ms | — | 66 ms | 6 | 2 |
| 200 clienti | chiudi Prospetti e report | 104 ms | 108 ms | 104 ms | — | 96 ms | 5 | 2 |
| 200 clienti | apri Prospetti e report | 472 ms | 480 ms | 472 ms | — | 483 ms | 11 | 3 |
| 200 clienti | apri Sala | 353 ms | 362 ms | 353 ms | — | 348 ms | 13 | 3 |
| 200 clienti | chiudi Sala | 104 ms | 110 ms | 104 ms | — | 112 ms | 7 | 2 |
| 200 clienti | apri Biblioteca | 190 ms | 200 ms | 190 ms | — | 220 ms | 11 | 3 |
| 200 clienti | chiudi Biblioteca | 93 ms | 102 ms | 93 ms | — | 88 ms | 6 | 2 |
| 200 clienti | apri Mercato | 181 ms | 183 ms | 181 ms | — | 192 ms | 19 | 3 |
| 200 clienti | chiudi Mercato | 103 ms | 108 ms | 103 ms | — | 119 ms | 6 | 2 |
| 200 clienti | apri Studio | 333 ms | 341 ms | 333 ms | — | 314 ms | 10 | 3 |
| 200 clienti | chiudi Studio | 106 ms | 115 ms | 106 ms | — | 101 ms | 6 | 2 |
| 200 clienti | apri Vera | 368 ms | 392 ms | 368 ms | — | 373 ms | 13 | 3 |
| 200 clienti | chiudi Vera | 124 ms | 125 ms | 124 ms | — | 116 ms | 6 | 2 |
| 200 clienti | apri Impostazioni | 283 ms | 284 ms | 283 ms | — | 330 ms | 9 | 3 |
| 200 clienti | chiudi Impostazioni | 100 ms | 108 ms | 100 ms | — | 85 ms | 6 | 2 |
| 200 clienti | passa all'app sotto (4 aperte) | 86 ms | 90 ms | 86 ms | — | 90 ms | 6 | 2 |
| 200 clienti | riduci Posizioni | 165 ms | 170 ms | 165 ms | — | 123 ms | 6 | 3 |
| 200 clienti | ripristina Posizioni | 153 ms | 158 ms | 153 ms | — | 159 ms | 6 | 3 |
| 200 clienti | riduci a finestra Clienti | 384 ms | 402 ms | 384 ms | — | 463 ms | 7 | 3 |
| 200 clienti | ingrandisci Clienti | 268 ms | 274 ms | 268 ms | — | 289 ms | 7 | 2 |
| 200 clienti | blocca (schermata di benvenuto) | 67 ms | 71 ms | 67 ms | — | 83 ms | 7 | 2 |
| 200 clienti | sblocca | 43 ms | 44 ms | 43 ms | — | 46 ms | 5 | 2 |
| 200 clienti | apri il centro notifiche | 155 ms | 155 ms | 155 ms | — | 167 ms | 12 | 1 |
| 200 clienti | chiudi il centro notifiche | 50 ms | 54 ms | 50 ms | — | 51 ms | 0 | 1 |
| 200 clienti | apri la ricerca (⌘K) | 362 ms | 452 ms | 362 ms | — | 132 ms | 4 | 1 |
| 200 clienti | chiudi la ricerca (⌘K) | 53 ms | 57 ms | 53 ms | — | 140 ms | 0 | 1 |
| 200 clienti | aspetto scuro | 1027 ms | 1032 ms | 1027 ms | — | 949 ms | 7 | 0 |
| 200 clienti | aspetto chiaro | 1071 ms | 1139 ms | 1071 ms | — | 1231 ms | 7 | 0 |
| 200 clienti | modifica una nota (un tasto) | 5 ms | 5 ms | 5 ms | — | 5 ms | 0 | 0 |
| 200 clienti | annulla la modifica | 5 ms | 5 ms | 5 ms | — | 5 ms | 0 | 0 |
| 200 clienti | mostra la scrivania | 359 ms | 366 ms | 359 ms | — | 364 ms | 10 | 4 |
| 200 clienti | riapri le app (4) | 393 ms | 397 ms | 393 ms | — | 370 ms | 10 | 12 |
| 200 clienti | sposta Clienti (un passo) | 34 ms | 35 ms | 34 ms | — | 29 ms | 6 | 1 |
| 200 clienti | Luce · apri la Sala | 300 ms | 304 ms | 300 ms | — | 369 ms | 13 | 3 |
| 200 clienti | Luce · chiudi la Sala | 93 ms | 97 ms | 93 ms | — | 102 ms | 7 | 2 |
| 200 clienti | Luce · apri il prisma di luce | 260 ms | 278 ms | 260 ms | — | 243 ms | 15 | 3 |
| 200 clienti | Luce · chiudi il prisma di luce | 370 ms | 370 ms | 370 ms | — | 356 ms | 10 | 2 |
| 200 clienti | Luce · apri Pratiche | 230 ms | 238 ms | 230 ms | — | 230 ms | 11 | 3 |
| 200 clienti | Luce · chiudi Pratiche | 80 ms | 80 ms | 80 ms | — | 92 ms | 6 | 2 |
| 200 clienti | apri gli spazi di lavoro | 182 ms | 182 ms | 182 ms | — | 147 ms | 1 | 1 |
| 200 clienti | chiudi gli spazi di lavoro | 56 ms | 56 ms | 56 ms | — | 58 ms | 0 | 1 |
| 200 clienti | apri «Le tue app aperte» | 111 ms | 115 ms | 111 ms | — | 145 ms | 9 | 1 |
| 200 clienti | chiudi «Le tue app aperte» | 42 ms | 44 ms | 42 ms | — | 34 ms | 0 | 1 |

Disegno non disponibile sul server di build: misurato solo l'aggiornamento.
Memoria: all'inizio: 116 MB residenti, 103 MB di impronta · 5 clienti, dopo l'avvio: 210 MB residenti, 216 MB di impronta · 5 clienti, dopo il giro delle app: 271 MB residenti, 217 MB di impronta · 5 clienti, alla fine (shell aperta): 371 MB residenti, 304 MB di impronta · dopo lo scenario con 5 clienti (shell chiusa): 285 MB residenti, 189 MB di impronta · 200 clienti, dopo l'avvio: 338 MB residenti, 288 MB di impronta · 200 clienti, dopo il giro delle app: 397 MB residenti, 292 MB di impronta · 200 clienti, alla fine (shell aperta): 423 MB residenti, 315 MB di impronta · dopo lo scenario con 200 clienti (shell chiusa): 368 MB residenti, 244 MB di impronta.

Memoria alla fine: 368 MB residenti, 244 MB di impronta · durata della prova: 148.9 s.
