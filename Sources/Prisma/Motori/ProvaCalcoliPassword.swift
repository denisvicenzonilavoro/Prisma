import Foundation

// Prova della password delle cose date al cliente («Luce» giro 15, decisione 4): l'elenco delle parole (almeno 2048,
// uniche, solo a-z, 4-7 lettere), il formato «Parola-Parola-Parola-NN», nessun doppione in mille proposte e i rifiuti di
// `motivoNonValida` (troppo corta, nome, cognome, data di nascita, codice fiscale). Cliente e dati inventati per la prova.
enum ProvaCalcoliPassword {
    static func esegui(_ verifica: VerificaCalcoli) {
        let parole = GeneratorePassword.parole
        verifica.vero("Password: almeno \(GeneratorePassword.paroleMinime) parole nell'elenco", parole.count >= GeneratorePassword.paroleMinime)
        verifica.vero("Password: parole uniche", Set(parole).count == parole.count)
        verifica.vero("Password: parole solo a-z di 4-7 lettere", parole.allSatisfy(GeneratorePassword.valida))
        verifica.vero("Password: verifica delle risorse senza errori", GeneratorePassword.verificaRisorse() == nil)
        // Un elenco con righe sbagliate: restano solo le valide, senza doppioni
        let letto = GeneratorePassword.leggi("lago\nLago\nvela\nvela\nàncora\nre\nlunghissima\n pino \n")
        verifica.vero("Password: lettura dell'elenco tollerante", letto == ["lago", "vela", "pino"])

        // Formato e varietà
        let insieme = Set(parole)
        var proposte: [String] = []
        for _ in 0..<1000 { proposte.append(GeneratorePassword.nuova()) }
        let formatoGiusto = proposte.allSatisfy { p in
            let pezzi = p.split(separator: "-").map(String.init)
            guard pezzi.count == 4, let n = Int(pezzi[3]), GeneratorePassword.numeri.contains(n), pezzi[3].count == 2 else { return false }
            return pezzi.prefix(3).allSatisfy { w in
                guard let prima = w.first, prima.isUppercase else { return false }
                return insieme.contains(w.lowercased())
            }
        }
        verifica.vero("Password: formato Parola-Parola-Parola-NN con parole dell'elenco", formatoGiusto)
        verifica.vero("Password: mille proposte senza doppioni", Set(proposte).count == proposte.count)
        verifica.vero("Password: ogni proposta di almeno 12 caratteri",
                      proposte.allSatisfy { GeneratorePassword.motivoNonValida($0, cliente: nil) == nil })
        // Uniforme: valori sempre nell'intervallo
        verifica.vero("Password: indice uniforme nell'intervallo",
                      (0..<500).allSatisfy { _ in (0..<7).contains(GeneratorePassword.uniforme(7)) })

        // Rifiuti
        var c = Cliente(id: "prova-password", nome: "Ottavia Brunelleschi", iniziali: "OB", tinta: .blu, tema: "", email: "",
                        telefono: "", preferito: false, nota: "", creatoIl: AiutiProva.data(2024, 3, 9))
        c.dataNascita = AiutiProva.data(1983, 7, 14)
        c.codiceFiscale = "BRNTTV83L54Z999Q"
        verifica.vero("Password: corta rifiutata", GeneratorePassword.motivoNonValida("Lago-Vela-1", cliente: nil) != nil)
        verifica.vero("Password: 12 caratteri accettati", GeneratorePassword.motivoNonValida("Lago-Vela-17", cliente: c) == nil)
        verifica.vero("Password: nome rifiutato", GeneratorePassword.motivoNonValida("Ottavia-Mare-Sole-41", cliente: c) != nil)
        verifica.vero("Password: cognome rifiutato (senza maiuscole)",
                      GeneratorePassword.motivoNonValida("lago-brunelleschi-58", cliente: c) != nil)
        verifica.vero("Password: data di nascita ggmmaaaa rifiutata",
                      GeneratorePassword.motivoNonValida("Vela-Pino-14071983", cliente: c) != nil)
        verifica.vero("Password: data con le barre rifiutata",
                      GeneratorePassword.motivoNonValida("Vela-14/07/1983-x", cliente: c) != nil)
        verifica.vero("Password: anno di nascita rifiutato", GeneratorePassword.motivoNonValida("Vela-Pino-Lago-1983", cliente: c) != nil)
        verifica.vero("Password: codice fiscale rifiutato",
                      GeneratorePassword.motivoNonValida("x-brnttv83l54z999q-y", cliente: c) != nil)
        verifica.vero("Password: proposte per il cliente sempre valide",
                      (0..<200).allSatisfy { _ in GeneratorePassword.motivoNonValida(GeneratorePassword.nuova(cliente: c), cliente: c) == nil })
    }
}
