#!/usr/bin/env python3
# Vera su misura: l'addestramento fuori dal Mac (Unsloth, LoRA, esportazione GGUF q4_k_m).
# Uso: python addestra.py <cartella-del-pacchetto>
# Il pacchetto lo prepara Prisma (Vera › Vera su misura › «Esporta questi esempi»): contiene solo esempi resi anonimi
# e approvati dal consulente. Questo script non contiene dati. I valori di avvio (r, alpha, epoche, lr) sono quelli
# consigliati da Unsloth: da confermare alla prima prova vera.
import json
import os
import sys
import time
import zipfile


def main(cartella):
    with open(os.path.join(cartella, "manifest.json"), encoding="utf-8") as f:
        manifesto = json.load(f)
    modello_partenza = manifesto["modelloUnsloth"]
    lunghezza = int(manifesto.get("lunghezzaMassima", 4096))
    nome = manifesto["nomeModello"]

    from unsloth import FastLanguageModel
    from unsloth.chat_templates import train_on_responses_only
    from datasets import load_dataset
    from trl import SFTTrainer, SFTConfig
    from transformers import TrainerCallback

    model, tokenizer = FastLanguageModel.from_pretrained(
        model_name=modello_partenza, max_seq_length=lunghezza, load_in_4bit=True)
    model = FastLanguageModel.get_peft_model(
        model, r=16, lora_alpha=16, lora_dropout=0,
        target_modules=["q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj"],
        use_gradient_checkpointing="unsloth")

    dati = load_dataset("json", data_files=os.path.join(cartella, "addestramento.jsonl"), split="train")
    dati = dati.map(lambda e: {"text": tokenizer.apply_chat_template(e["messages"], tokenize=False)})

    passi = []

    class Registro(TrainerCallback):
        def on_log(self, args, state, control, logs=None, **kwargs):
            if logs and "loss" in logs:
                passi.append({"passo": state.global_step, "errore": float(logs["loss"])})

    inizio = time.time()
    trainer = SFTTrainer(
        model=model, tokenizer=tokenizer, train_dataset=dati,
        args=SFTConfig(dataset_text_field="text", max_seq_length=lunghezza, num_train_epochs=2,
                       learning_rate=2e-4, per_device_train_batch_size=2, gradient_accumulation_steps=4,
                       logging_steps=1, output_dir="uscita", report_to="none"),
        callbacks=[Registro()])
    # Solo le risposte insegnano (le istruzioni e le domande no): i segni del modello di chat vanno verificati con il
    # modello di partenza scelto
    trainer = train_on_responses_only(trainer, instruction_part="<|im_start|>user\n", response_part="<|im_start|>assistant\n")
    trainer.train()

    rapporto = {"versione": 1, "passi": passi, "esempi": len(dati), "modelloDiPartenza": manifesto["modelloDiPartenza"],
                "minuti": round((time.time() - inizio) / 60), "nomeModello": nome}
    with open("rapporto.json", "w", encoding="utf-8") as f:
        json.dump(rapporto, f, ensure_ascii=False)

    model.save_pretrained_gguf("vera-su-misura", tokenizer, quantization_method="q4_k_m")
    gguf = [os.path.join("vera-su-misura", n) for n in os.listdir("vera-su-misura") if n.endswith(".gguf")]
    with zipfile.ZipFile("vera-su-misura.zip", "w", zipfile.ZIP_STORED) as z:
        for g in gguf:
            z.write(g, os.path.basename(g))
        z.write("rapporto.json")
    print("Fatto: scarica vera-su-misura.zip e importalo in Prisma (Vera › Vera su misura).")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Uso: python addestra.py <cartella-del-pacchetto>")
        sys.exit(1)
    main(sys.argv[1])
