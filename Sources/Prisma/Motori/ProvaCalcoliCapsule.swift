import CryptoKit
import Foundation

// Prova della capsula del tempo («Luce» giro 15, §3.4) dentro `--prova-calcoli`: pronta per data e per obiettivo
// raggiunto, non pronta prima; obiettivo eliminato → «da decidere»; senza chiave → «non apribile»; l'elenco della Sala
// solo del cliente scelto; sigilla e apri uguali con la chiave di prova; chiave sbagliata o capsula spostata su un altro
// cliente → errore; il sigillo non contiene il testo; Vera (`FonteVera`) non ha campi di capsule; le frasi «si apre …»;
// le capsule dei dati di prova. Clienti, obiettivi e testi inventati per la prova (date fisse, mai la data di oggi).
enum ProvaCalcoliCapsule {
    static func esegui(_ verifica: VerificaCalcoli) {
        let cal = Calendar(identifier: .gregorian)
        let oggi = AiutiProva.data(2031, 5, 13)
        let prima = AiutiProva.data(2031, 5, 12)
        var raggiunto = Obiettivo(clienteId: "prova-a", titolo: "Barca a vela", area: .patrimonio, importo: 23_417,
                                  scadenza: AiutiProva.data(2033, 2, 7))
        raggiunto.id = "obiettivo-prova-raggiunto"
        raggiunto.raggiuntoIl = AiutiProva.data(2031, 5, 9)
        var inCorso = Obiettivo(clienteId: "prova-a", titolo: "Laboratorio", area: .patrimonio, importo: 41_903,
                                scadenza: AiutiProva.data(2036, 9, 3))
        inCorso.id = "obiettivo-prova-in-corso"
        let obiettivi = [raggiunto, inCorso]
        func capsula(_ id: String, _ cliente: String, _ apertura: CapsulaTempo.Apertura, sigillata: Date = AiutiProva.data(2029, 3, 21),
                     stato: CapsulaTempo.Stato = .sigillata) -> CapsulaTempo {
            CapsulaTempo(id: id, clienteId: cliente, apertura: apertura, sigillataIl: sigillata, sigillo: Data([0x11, 0x5C]),
                         chiaveId: "chiave-prova", stato: stato)
        }

        // Pronta per data: dal giorno in poi, non prima
        let perData = capsula("capsula-prova-data", "prova-a", .data(oggi))
        verifica.vero("Capsula: pronta il giorno della data",
                      MotoreCapsule.stato(perData, obiettivi: obiettivi, oggi: oggi, chiavePresente: true, cal: cal) == .pronta(dal: oggi))
        verifica.vero("Capsula: non pronta il giorno prima",
                      MotoreCapsule.stato(perData, obiettivi: obiettivi, oggi: prima, chiavePresente: true, cal: cal) == .sigillata)
        // Pronta per obiettivo raggiunto; sigillata se l'obiettivo è in corso; da decidere se l'obiettivo non c'è più
        let perObiettivo = capsula("capsula-prova-obiettivo", "prova-a", .obiettivo(id: raggiunto.id))
        verifica.vero("Capsula: pronta con l'obiettivo raggiunto",
                      MotoreCapsule.stato(perObiettivo, obiettivi: obiettivi, oggi: oggi, chiavePresente: true, cal: cal)
                          == .pronta(dal: AiutiProva.data(2031, 5, 9)))
        let attesa = capsula("capsula-prova-attesa", "prova-a", .obiettivo(id: inCorso.id))
        verifica.vero("Capsula: sigillata con l'obiettivo non ancora raggiunto",
                      MotoreCapsule.stato(attesa, obiettivi: obiettivi, oggi: oggi, chiavePresente: true, cal: cal) == .sigillata)
        let orfana = capsula("capsula-prova-orfana", "prova-a", .obiettivo(id: "obiettivo-eliminato"))
        verifica.vero("Capsula: obiettivo eliminato → da decidere",
                      MotoreCapsule.stato(orfana, obiettivi: obiettivi, oggi: oggi, chiavePresente: true, cal: cal) == .daDecidere)
        verifica.vero("Capsula: senza chiave → non apribile",
                      MotoreCapsule.stato(perData, obiettivi: obiettivi, oggi: oggi, chiavePresente: false, cal: cal) == .nonApribile)
        let aperta = capsula("capsula-prova-aperta", "prova-a", .data(prima), stato: .aperta)
        verifica.vero("Capsula: aperta resta aperta (anche senza chiave)",
                      !MotoreCapsule.stato(aperta, obiettivi: obiettivi, oggi: oggi, chiavePresente: false, cal: cal).chiusa)

        // Elenco della Sala: solo il cliente scelto, pronte prima
        let altra = capsula("capsula-prova-altro", "prova-b", .data(prima))
        let tutte = [attesa, altra, aperta, perObiettivo, orfana]
        let delCliente = MotoreCapsule.delCliente(tutte, clienteId: "prova-a", obiettivi: obiettivi, oggi: oggi, cal: cal)
        verifica.vero("Capsula: nella Sala solo le capsule del cliente scelto", delCliente.allSatisfy { $0.clienteId == "prova-a" }
                      && delCliente.count == 4)
        verifica.vero("Capsula: nella Sala le pronte prima, le aperte in fondo",
                      delCliente.first?.id == perObiettivo.id && delCliente.last?.id == aperta.id)
        verifica.vero("Capsula: pronte tra tutte", Set(MotoreCapsule.pronte(tutte, obiettivi: obiettivi, oggi: oggi, cal: cal))
                      == [perObiettivo.id, altra.id])
        verifica.vero("Capsula: quella legata all'obiettivo", MotoreCapsule.perObiettivo(tutte, obiettivoId: raggiunto.id)?.id == perObiettivo.id
                      && MotoreCapsule.perObiettivo(tutte, obiettivoId: "obiettivo-senza-capsula") == nil)

        // Le frasi «si apre …»
        let settembre = capsula("capsula-prova-settembre", "prova-a", .data(AiutiProva.data(2036, 9, 14)))
        let capodanno = capsula("capsula-prova-anno", "prova-a", .data(AiutiProva.data(2037, 1, 1)))
        verifica.vero("Capsula: «si apre a settembre 2036»", MotoreCapsule.quando(settembre, obiettivo: nil, cal: cal) == "si apre a settembre 2036")
        verifica.vero("Capsula: «si apre nel 2037»", MotoreCapsule.quando(capodanno, obiettivo: nil, cal: cal) == "si apre nel 2037")
        verifica.vero("Capsula: «si apre quando «Laboratorio» è raggiunto»",
                      MotoreCapsule.quando(attesa, obiettivo: inCorso, cal: cal) == "si apre quando «Laboratorio» è raggiunto")
        verifica.vero("Capsula: obiettivo sparito, la frase chiede di scegliere",
                      MotoreCapsule.quando(orfana, obiettivo: nil, cal: cal) == TestiCapsule.obiettivoSparito)
        verifica.vero("Capsula: sopratitolo «SIGILLATA A MARZO 2029»", TestiCapsule.sopratitolo(AiutiProva.data(2029, 3, 21)) == "SIGILLATA A MARZO 2029")
        verifica.vero("Capsula: titolo con il genere", TestiCapsule.titolo(femminile: true).contains("alla te stessa")
                      && TestiCapsule.titolo(femminile: false).contains("al te stesso"))
        verifica.vero("Capsula: frase onesta senza promesse impossibili", !TestiCapsule.fraseOnesta.lowercased().contains("nemmeno"))
        verifica.vero("Capsula: nome del file con il solo nome di battesimo", TestiCapsule.nomeFile(nome: "Ottavia") == "La-capsula-di-Ottavia.pdf")

        // Sigillo: andata e ritorno con la chiave di prova; chiave sbagliata o capsula spostata → errore
        let testo = "Ottavia, il laboratorio è tuo: ricordati del primo vaso storto. Prova 7319."
        let chiave = SigilloCapsule.chiaveDiProva
        if let sigillo = try? SigilloCapsule.sigilla(testo, id: "capsula-prova-sigillo", clienteId: "prova-a", chiave: chiave) {
            let c = CapsulaTempo(id: "capsula-prova-sigillo", clienteId: "prova-a", apertura: .data(oggi), sigillataIl: prima,
                                 sigillo: sigillo, chiaveId: SigilloCapsule.chiaveId(chiave))
            verifica.vero("Capsula: sigilla e apri tornano uguali", (try? SigilloCapsule.apri(c, chiave: chiave)) == testo)
            verifica.vero("Capsula: nel sigillo il testo non compare", sigillo.range(of: Data("laboratorio".utf8)) == nil
                          && sigillo.range(of: Data(testo.utf8)) == nil)
            let sbagliata = SymmetricKey(data: SHA256.hash(data: Data("chiave sbagliata della prova".utf8)))
            verifica.vero("Capsula: la chiave sbagliata non apre", (try? SigilloCapsule.apri(c, chiave: sbagliata)) == nil)
            var spostata = c
            spostata.clienteId = "prova-b"
            verifica.vero("Capsula: spostata su un altro cliente non si apre", (try? SigilloCapsule.apri(spostata, chiave: chiave)) == nil)
            var rinominata = c
            rinominata.id = "capsula-prova-altra"
            verifica.vero("Capsula: con un altro id non si apre", (try? SigilloCapsule.apri(rinominata, chiave: chiave)) == nil)
            let di2 = try? SigilloCapsule.sigilla(testo, id: "capsula-prova-sigillo", clienteId: "prova-a", chiave: chiave)
            verifica.vero("Capsula: due sigilli dello stesso testo sono diversi", di2 != nil && di2 != sigillo)
            verifica.vero("Capsula: id della chiave di 16 cifre esadecimali, uguale per la stessa chiave",
                          SigilloCapsule.chiaveId(chiave).count == 16 && SigilloCapsule.chiaveId(chiave) == SigilloCapsule.chiaveIdDiProva
                          && SigilloCapsule.chiaveId(sbagliata) != SigilloCapsule.chiaveIdDiProva)
        } else {
            verifica.vero("Capsula: sigillo creato", false)
        }

        // Vera non legge le capsule: nessun campo di capsule nella fonte di Vera
        let cliente = Cliente(id: "prova-a", nome: "Ottavia Prova", iniziali: "OP", tinta: .blu, tema: "", email: "", telefono: "",
                              preferito: false, nota: "", creatoIl: prima)
        let fonte = FonteVera(oggi: oggi, nomeUtente: "Prova", cliente: cliente, posizioni: [], appuntamenti: [], attivita: [],
                              analisi: Analisi360(), analisiSalvata: false, simulazioni: [])
        let campi = Mirror(reflecting: fonte).children.compactMap { $0.label?.lowercased() }
        verifica.vero("Capsula: la fonte di Vera non ha campi di capsule", !campi.isEmpty && !campi.contains { $0.contains("capsul") })

        // Le capsule dei dati di prova: dichiarate, aperte con la chiave di prova, Sofia pronta, stesse a ogni lettura
        let demo = DatiPrisma.demo()
        let diProva = demo.capsule
        verifica.vero("Capsula: quattro capsule di prova, tutte dichiarate", diProva.count == 4 && diProva.allSatisfy { $0.diProva == true })
        verifica.vero("Capsula: le capsule di prova si aprono con la chiave di prova",
                      diProva.allSatisfy { (try? SigilloCapsule.apri($0, chiave: SigilloCapsule.chiaveDiProva)) != nil })
        let sofia = diProva.first { $0.clienteId == "sofia" }
        verifica.vero("Capsula: quella di Sofia è pronta (obiettivo di prova raggiunto)", sofia.map {
            MotoreCapsule.stato($0, obiettivi: demo.obiettivi, oggi: Date(), chiavePresente: true).pronta
        } ?? false)
        verifica.vero("Capsula: i dati di prova sono gli stessi a ogni lettura", DatiPrisma.demo().capsule == diProva)
        let traguardoSofia = MotoreTraguardi.calcola(dati: demo, oggi: Date()).first { $0.clienteId == "sofia" && $0.tipo == .obiettivoRaggiunto }
        verifica.vero("Capsula: il traguardo di Sofia porta la sua capsula", traguardoSofia?.capsulaId == sofia?.id && sofia != nil)
    }
}
