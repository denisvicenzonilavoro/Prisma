import Foundation

/// Prova dei motori Mistral (dentro `Prisma --prova-vera`): la scelta automatica per compito, il ripiego sul modello del
/// Mac finché non c'è il computer dell'IA, il Profondo solo di notte, lo stato dei modelli e la memoria per l'interfaccia,
/// le impostazioni nell'archivio e il passaggio da Qwen a Ministral 3.
enum ProvaMotoriMistral {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        scelta(controlla)
        stati(controlla)
        impostazioni(controlla)
        computerIA(controlla)
    }

    /// Tappa 2: il computer dell'IA dello studio, raggiunto con il ponte cifrato.
    private static func computerIA(_ controlla: (Bool, String) -> Void) {
        let vera = ImpostazioniVera()
        let studio = StatoComputerIA(nome: "Mac Studio", indirizzo: "http://192.168.1.30:47620", memoriaGB: 512, prismaGB: 1,
                                     installati: ["mistral-small4", "Mistral-Large3"], inMemoria: ["mistral-small4": 72])
        let kid = SceltaMotori.scegli(.kid, vera: vera, memoriaMac: 8, installati: [vera.modello], computerIA: studio, notte: false)
        controlla(kid.ruolo == .quotidiano && kid.dove == .computerIA && kid.modello == "mistral-small4" && kid.ripiego == nil,
                  "Computer dell'IA: il KID va a Mistral Small 4 sul computer dell'IA")
        let comando = SceltaMotori.scegli(.comando, vera: vera, memoriaMac: 8, installati: [vera.modello], computerIA: studio, notte: false)
        controlla(comando.dove == .mac && comando.ruolo == .lampo, "Computer dell'IA: i comandi restano al Lampo sul Mac, subito")
        let notte = SceltaMotori.scegli(.lavoroLungo, vera: vera, memoriaMac: 8, installati: nil, computerIA: studio, notte: true)
        controlla(notte.ruolo == .quotidiano && notte.dove == .computerIA && (notte.ripiego ?? "").contains("600 GB"),
                  "Computer dell'IA: Large 4 non entra in 512 GB, di notte lavora Small 4 e Vera dice perché (\(notte.ripiego ?? "-"))")
        var conLarge3 = vera
        conLarge3.motori.modelloProfondo = CatalogoMistral.large3.nome
        let large3 = SceltaMotori.scegli(.lavoroLungo, vera: conLarge3, memoriaMac: 8, installati: nil, computerIA: studio, notte: true)
        controlla(large3.ruolo == .profondo && large3.dove == .computerIA && large3.modello == "mistral-large3" && large3.famiglia == "Mistral Large 3",
                  "Computer dell'IA: con Mistral Large 3 il Profondo lavora di notte sul computer dell'IA")
        let giorno = SceltaMotori.scegli(.lavoroLungo, vera: conLarge3, memoriaMac: 8, installati: nil, computerIA: studio, notte: false)
        controlla(giorno.ruolo == .quotidiano && giorno.dove == .computerIA, "Computer dell'IA: di giorno il Profondo non lavora")
        let piccolo = StatoComputerIA(nome: "Mac mini", indirizzo: "http://192.168.1.31:47620", memoriaGB: 32, installati: ["mistral-small4"])
        let nonEntra = SceltaMotori.scegli(.documento, vera: vera, memoriaMac: 8, installati: [vera.modello], computerIA: piccolo, notte: false)
        controlla(nonEntra.dove == .mac && nonEntra.ruolo == .lampo && (nonEntra.ripiego ?? "").contains("32 GB"),
                  "Computer dell'IA: su un computer da 32 GB Small 4 non entra, lavora il Mac")
        let senzaModello = StatoComputerIA(nome: "Mac Studio", indirizzo: "http://192.168.1.30:47620", memoriaGB: 512, installati: [])
        let daScaricare = SceltaMotori.scegli(.documento, vera: vera, memoriaMac: 8, installati: [vera.modello], computerIA: senzaModello, notte: false)
        controlla(daScaricare.dove == .mac && (daScaricare.ripiego ?? "").contains("non è scaricato sul computer dell'IA"),
                  "Computer dell'IA: un modello non scaricato là non si usa")

        // Il motore: il ponte cifrato verso il computer dell'IA, con il nome giusto sotto la risposta
        #if os(macOS)
        let motore = MotoriVera.generativo(kid, vera: vera, locale: .nonDisponibile("Ollama spento sul Mac"), computerIA: studio) as? MotoreLocale
        controlla(motore?.nome == "Mistral Small 4 sul computer dell'IA" && motore?.modello == "mistral-small4" && motore?.fornitore is FornitorePonte,
                  "Computer dell'IA: risponde anche con Ollama spento sul Mac, attraverso il ponte cifrato")
        controlla((MotoriVera.generativo(kid, vera: vera, locale: .pronto, computerIA: nil) as? MotoreLocale)?.modello == vera.modello,
                  "Computer dell'IA: senza lo stato del computer dell'IA resta il motore del Mac")
        #endif

        // Lo stato dei modelli e la memoria del computer dell'IA per l'interfaccia
        let stati = StatoMotoreVera.stati(vera: conLarge3, installati: [vera.modello], caricati: [:], memoriaMac: 8, computerIA: studio)
        controlla(stati[0].dove == .mac && stati[0].stato == .pronto && stati[1].dove == .computerIA && stati[1].stato == .inMemoria
                  && stati[2].dove == .computerIA && stati[2].stato == .pronto && stati[2].spiegazione.contains("turno di notte"),
                  "Computer dell'IA: Lampo sul Mac, Small 4 in memoria e Large 3 pronto per la notte sul computer dell'IA")
        controlla(studio.memoria.dove == .computerIA && studio.memoria.percentuale == 14, "Computer dell'IA: la memoria usata (73 GB su 512 = 14%)")

        // Lo stato del ponte: vale solo un Mac che dice di essere il computer dell'IA
        var st = StatoPonte(pronto: true, motivo: nil, fornitore: .ollama, modello: "ministral-3:3b", mac: "Mac Studio", versione: PonteVera.versioneProtocollo)
        controlla(StatoComputerIA(st, indirizzo: "http://x:1") == nil, "Computer dell'IA: un Mac con il solo ponte non è il computer dell'IA")
        st.computerIA = true
        st.memoriaGB = 512
        st.installati = ["Mistral-Small4"]
        let letto = (try? JSONEncoder().encode(st)).flatMap { try? JSONDecoder().decode(StatoPonte.self, from: $0) }
        controlla(letto.flatMap { StatoComputerIA($0, indirizzo: "http://x:1") }?.ha("mistral-small4") == true,
                  "Computer dell'IA: memoria e modelli viaggiano nello stato del ponte")
        let vecchio = try? JSONDecoder().decode(StatoPonte.self, from: Data(#"{"pronto":true,"fornitore":"ollama","modello":"qwen3.5:4b","mac":"Mac"}"#.utf8))
        controlla(vecchio != nil && vecchio?.computerIA == nil, "Computer dell'IA: lo stato di un Mac di prima si legge ancora")

        // Il server sceglie il modello: quello chiesto solo se scaricato là
        controlla(ServerPonteVera.modelloDaUsare(chiesto: "mistral-small4", delMac: "ministral-3:3b", ammessi: ["mistral-small4:latest"]) == "mistral-small4"
                  && ServerPonteVera.modelloDaUsare(chiesto: "mistral-large4", delMac: "ministral-3:3b", ammessi: ["mistral-small4"]) == "ministral-3:3b"
                  && ServerPonteVera.modelloDaUsare(chiesto: "mistral-small4", delMac: "ministral-3:3b", ammessi: []) == "ministral-3:3b",
                  "Computer dell'IA: il server usa il modello chiesto solo se l'ha già scaricato")

        // Le impostazioni: spente di base, salvate e rilette; il codice deve essere valido
        var imp = ImpostazioniVera()
        controlla(!imp.computerIA.questoMac && !imp.computerIA.usa && !imp.computerIA.attivo, "Computer dell'IA: spento di base")
        imp.computerIA.usa = true
        imp.computerIA.codice = "abcd efgh jkmn"
        let riletti = (try? JSONEncoder().encode(imp)).flatMap { try? JSONDecoder().decode(ImpostazioniVera.self, from: $0) }
        controlla(riletti == imp && riletti?.computerIA.attivo == true, "Computer dell'IA: impostazioni salvate e rilette, codice valido")
        imp.computerIA.codice = "ABCD-EFGH-IJK0"
        controlla(!imp.computerIA.attivo, "Computer dell'IA: con un codice non valido non si cerca")
    }

    private static func scelta(_ controlla: (Bool, String) -> Void) {
        let vera = ImpostazioniVera()
        controlla(vera.modello == "ministral-3:3b" && MotoreLocale.modelloPredefinito == CatalogoMistral.ministral3B.nome,
                  "Motori: sul Mac il modello di base è Ministral 3 da 3 miliardi")
        controlla(CompitoVera.chiediAlVolo.ruolo == .lampo && CompitoVera.comando.ruolo == .lampo && CompitoVera.kid.ruolo == .quotidiano
                  && CompitoVera.immagine.ruolo == .quotidiano && CompitoVera.lavoroLungo.ruolo == .profondo,
                  "Motori: ⌘K e comandi al Lampo, KID e immagini al Quotidiano, lavori lunghi al Profondo")

        // Il MacBook da 8 GB: entra solo Ministral 3 da 3 miliardi
        controlla(MemoriaComputer.piuGrandeCheEntra(totale: 8) == CatalogoMistral.ministral3B
                  && MemoriaComputer.piuGrandeCheEntra(totale: 16) == CatalogoMistral.ministral14B
                  && MemoriaComputer.piuGrandeCheEntra(totale: 128) == CatalogoMistral.small4
                  && MemoriaComputer.piuGrandeCheEntra(totale: 4) == nil,
                  "Motori: il modello più grande che entra (8 GB → Ministral 3B, 16 GB → 14B, 128 GB → Small 4)")
        let tutti = CatalogoMistral.tutti.map(\.nome)
        let lampo = SceltaMotori.scegli(.comando, vera: vera, memoriaMac: 8, installati: tutti, notte: false)
        controlla(lampo.ruolo == .lampo && lampo.modello == vera.modello && lampo.dove == .mac && lampo.ripiego == nil,
                  "Motori: un comando va subito al Lampo, senza ripiego")
        let kid = SceltaMotori.scegli(.kid, vera: vera, memoriaMac: 8, installati: tutti, notte: false)
        controlla(kid.ruoloChiesto == .quotidiano && kid.ruolo == .lampo && kid.modello == vera.modello
                  && (kid.ripiego ?? "").contains("Mistral Small 4") && (kid.ripiego ?? "").contains("72 GB"),
                  "Motori: sul MacBook da 8 GB il KID va a Ministral 3 e Vera dice perché (\(kid.ripiego ?? "-"))")
        let notte = SceltaMotori.scegli(.lavoroLungo, vera: vera, memoriaMac: 8, installati: tutti, notte: true)
        controlla(notte.ruoloChiesto == .profondo && notte.ruolo == .lampo && notte.modello == vera.modello
                  && (notte.ripiego ?? "").contains("Mistral Large 4"),
                  "Motori: di notte il Profondo non entra nel MacBook e lavora Ministral 3")
        let giorno = SceltaMotori.scegli(.lavoroLungo, vera: vera, memoriaMac: 128, installati: tutti, notte: false)
        controlla(giorno.ruolo == .quotidiano && giorno.modello == CatalogoMistral.small4.nome && (giorno.ripiego ?? "").contains("solo nel turno di notte"),
                  "Motori: di giorno il Profondo non lavora, il lavoro lungo va al Quotidiano")

        // Su un Mac grande il Quotidiano lavora solo se è già scaricato; senza elenco (Ollama non ha risposto) resta il modello del Mac
        let grande = SceltaMotori.scegli(.documento, vera: vera, memoriaMac: 128, installati: tutti, notte: false)
        controlla(grande.ruolo == .quotidiano && grande.modello == CatalogoMistral.small4.nome && grande.ripiego == nil,
                  "Motori: con 128 GB e il modello scaricato i documenti vanno a Mistral Small 4")
        let nonScaricato = SceltaMotori.scegli(.documento, vera: vera, memoriaMac: 128, installati: [vera.modello], notte: false)
        let senzaElenco = SceltaMotori.scegli(.documento, vera: vera, memoriaMac: 128, installati: nil, notte: false)
        controlla(nonScaricato.modello == vera.modello && (nonScaricato.ripiego ?? "").contains("non è ancora scaricato")
                  && senzaElenco.modello == vera.modello,
                  "Motori: un modello non scaricato non si usa, resta quello del Mac")

        // «Sempre Lampo»: la scelta a mano vince sul compito
        var aMano = vera
        aMano.motori.modo = .lampo
        controlla(SceltaMotori.scegli(.kid, vera: aMano, memoriaMac: 128, installati: tutti, notte: false).ruolo == .lampo,
                  "Motori: con «Sempre Lampo» anche il KID va al Lampo")

        // Il motore della scelta: il modello del Mac solo se pronto; un altro modello scaricato quando Ollama risponde
        let delMac = MotoriVera.generativo(lampo, vera: vera, locale: .pronto)
        controlla(delMac?.nome == "Ministral sul Mac" && MotoriVera.generativo(lampo, vera: vera, locale: .nonDisponibile("no")) == nil,
                  "Motori: il Lampo risponde solo se il modello del Mac è pronto")
        #if os(macOS)
        let quotidiano = MotoriVera.generativo(grande, vera: vera, locale: .pronto) as? MotoreLocale
        controlla(quotidiano?.modello == CatalogoMistral.small4.nome, "Motori: il Quotidiano scaricato risponde con Mistral Small 4")
        #endif

        // La scelta è segnata come motore attivo per l'interfaccia
        let stato = StatoMotoreVera()
        let s = stato.scegli(.chiediAlVolo, vera: vera)
        controlla(stato.attivo == s && s.famiglia == "Ministral 3", "Motori: l'interfaccia riceve il motore attivo")
    }

    private static func stati(_ controlla: (Bool, String) -> Void) {
        let vera = ImpostazioniVera()
        let spenti = StatoMotoreVera.stati(vera: vera, installati: nil, caricati: [:], memoriaMac: 8)
        controlla(spenti.map(\.ruolo) == RuoloMotore.allCases && spenti[0].stato == .spento
                  && spenti[1].stato == .nonEntra && spenti[2].stato == .nonEntra,
                  "Motori: con Ollama spento il Lampo è spento, Small 4 e Large 4 non entrano nel MacBook")
        let caricati = FornitoreOllama.inMemoria(["models": [["name": "ministral-3:3b", "size": 3_758_096_384]]])
        controlla(abs((caricati["ministral-3:3b"] ?? 0) - 3.5) < 0.01, "Motori: /api/ps letto (Ministral 3 occupa 3,5 GB)")
        let accesi = StatoMotoreVera.stati(vera: vera, installati: ["ministral-3:3b"], caricati: caricati, memoriaMac: 8)
        controlla(accesi[0].stato == .inMemoria && accesi[0].famiglia == "Ministral 3" && accesi[1].spiegazione.contains("72 GB"),
                  "Motori: Ministral 3 in memoria, Small 4 spiega quanta memoria vuole")
        let daScaricare = StatoMotoreVera.stati(vera: vera, installati: [], caricati: [:], memoriaMac: 128)
        controlla(daScaricare[0].stato == .daScaricare && daScaricare[1].stato == .daScaricare && daScaricare[2].stato == .nonEntra
                  && daScaricare[0].spiegazione.contains("ollama pull ministral-3:3b"),
                  "Motori: su un Mac da 128 GB Small 4 è da scaricare, Large 4 non entra")
        let memoria = MemoriaMotore(dove: .mac, totaleGB: 8, prismaGB: 0.5, modelliGB: 3.5)
        controlla(memoria.percentuale == 50 && memoria.usataGB == 4, "Motori: la memoria usata in percentuale (4 GB su 8 = 50%)")
        controlla(SceltaMotori.gb(72) == "72 GB" && SceltaMotori.gb(3.5) == "3,5 GB", "Motori: i GB scritti all'italiana")
    }

    private static func impostazioni(_ controlla: (Bool, String) -> Void) {
        // Chi aveva Qwen come modello di base passa a Ministral 3; un modello scelto a mano resta
        for vecchio in ["qwen3:4b", "qwen3.5:4b"] {
            let lette = (try? JSONDecoder().decode(ImpostazioniVera.self, from: Data(#"{"modelloLocale":"\#(vecchio)"}"#.utf8))) ?? ImpostazioniVera()
            controlla(lette.modelloLocale == "ministral-3:3b" && lette.motori == ImpostazioniMotori(),
                      "Motori: \(vecchio) → ministral-3:3b, motori automatici se mancano")
        }
        let aMano = (try? JSONDecoder().decode(ImpostazioniVera.self, from: Data(#"{"modelloLocale":"qwen3:8b"}"#.utf8))) ?? ImpostazioniVera()
        controlla(aMano.modelloLocale == "qwen3:8b", "Motori: un modello scelto a mano resta")
        var nuove = ImpostazioniVera()
        nuove.motori.modo = .quotidiano
        nuove.motori.modelloQuotidiano = "mistral-small4:119b"
        let riletti = (try? JSONEncoder().encode(nuove)).flatMap { try? JSONDecoder().decode(ImpostazioniVera.self, from: $0) }
        controlla(riletti == nuove, "Motori: modo e modelli dei ruoli salvati e riletti")
        let rovinate = (try? JSONDecoder().decode(ImpostazioniVera.self, from: Data(#"{"motori":{"modo":"turbo","modelloProfondo":""}}"#.utf8))) ?? ImpostazioniVera()
        controlla(rovinate.motori == ImpostazioniMotori(), "Motori: valori sconosciuti o vuoti tornano a quelli di base")
        controlla(PacchettoSuMisura.modelloUnsloth(per: "ministral-3:3b") == "unsloth/Ministral-3-3B-Instruct-2512"
                  && PacchettoSuMisura.modelloUnsloth(per: "qwen3.5:4b") == "unsloth/Qwen3.5-4B",
                  "Motori: Vera su misura parte da Ministral 3 (Unsloth), le versioni da Qwen restano")
    }
}
