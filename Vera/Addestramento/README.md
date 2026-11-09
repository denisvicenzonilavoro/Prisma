# Vera su misura · l'addestramento fuori dal Mac

«Vera su misura» (Vera/BRIEF.md, fase 5, funzione 22) insegna a Qwen il tuo modo di lavorare con gli esempi che hai
approvato con 👍 e le lezioni delle tue correzioni. L'addestramento è l'unica cosa che non si fa sul Mac (8 GB non
bastano): si fa ogni tanto, su una GPU gratuita in cloud, con questo notebook.

## Cosa esce dal Mac, e come

- Esce solo il **pacchetto** che prepari tu in Prisma (Vera › Vera su misura › «Esporta questi esempi»), dopo aver
  guardato l'anteprima: gli esempi resi anonimi dal codice (nomi, indirizzi, email, telefoni, codici fiscali, numeri di
  documenti e date di nascita diventano segnaposto come `[Cliente]` e `[Indirizzo]`), il manifesto e questo notebook.
- Prisma **non invia niente**: salva uno zip dove scegli tu, e sei tu a caricarlo su Colab o Kaggle.
- Le domande dell'**esame** non sono nel pacchetto: restano sul Mac.
- In attesa del tuo sì (domanda 2 del riepilogo della fase 5), questa uscita non è ancora un'eccezione approvata in CLAUDE.md.

## Passo per passo

1. In Prisma prepara il pacchetto e salvalo (es. `vera-su-misura-2026-11-08.zip`).
2. Apri `vera-su-misura.ipynb` su [Google Colab](https://colab.research.google.com) o Kaggle e scegli una GPU
   (Colab: Runtime › Cambia tipo di runtime › T4 GPU).
3. Carica lo zip del pacchetto con il nome `pacchetto.zip` (o i file `addestramento.jsonl` e `manifest.json`).
4. Esegui le celle in ordine: installa Unsloth, carica il modello di partenza in 4 bit, aggiunge LoRA, addestra sulle
   risposte approvate, scrive `rapporto.json` (l'errore a ogni passo) ed esporta il modello in GGUF `q4_k_m`.
5. Scarica `vera-su-misura.zip` (circa 3 GB: il file `.gguf` e `rapporto.json`).
6. In Prisma: Vera › Vera su misura › «Importa il modello addestrato». Prisma controlla il file, lo copia in Ollama
   (solo all'indirizzo del Mac, 127.0.0.1) e fa l'esame: le stesse domande alla Vera di oggi e a quella nuova, un modello
   alla volta. La nuova Vera prende il posto di quella di oggi **solo se supera l'esame**; «Torna alla Vera di prima»
   rimette la versione precedente in un clic.

In alternativa al notebook: `python addestra.py <cartella-del-pacchetto>` su un computer con GPU NVIDIA.

## Valori da verificare alla prima prova vera

- Il nome del modello di partenza per Unsloth (nel manifesto, `modelloUnsloth`): Prisma scrive `unsloth/Qwen3.5-4B`
  per `qwen3.5:4b`, **da verificare** su Hugging Face.
- La versione di Unsloth da fissare in `pip install`.
- I valori di avvio: LoRA r 16, alpha 16, 2 epoche, learning rate 2e-4, batch 2 con accumulo 4.
- I segni del modello di chat per `train_on_responses_only` (`<|im_start|>user` / `<|im_start|>assistant` per Qwen).
- Che Ollama accetti il template copiato dal modello di partenza (o un `renderer`/`parser` interno).
