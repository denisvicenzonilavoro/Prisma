import SwiftUI

/// I dati di prova delle istantanee di Messaggi (Mac, iPhone e iPad), tutti relativi a oggi così le scene sono uguali
/// in ogni giorno. DATI DI PROVA DICHIARATI, solo dentro le scene (lo stato dell'istantanea non si salva):
/// - Giulia Rossi: l'incontro «Il punto sul progetto casa» concluso ieri alle 17:30, con decisioni, prossimo passo e
///   prossimo incontro di prova (le cifre del template, dimostrative: 550 € al mese);
/// - Marco Bianchi: la polizza di prova «Infortuni famiglia» che scade fra 45 giorni (il primo giorno della soglia);
/// - Sofia Romano: un consenso commerciale di prova firmato 25 mesi fa (vale 24 mesi: scaduto).
/// Il testo dei messaggi è il modello fisso di Prisma compilato con le cifre dei motori; nelle scene «con Ruby» si mostra
/// come scritto da Ruby (lo stato finale di Ruby: Qwen nelle istantanee non c'è).
enum MessaggiDiProva {
    static let incontroGiulia = "incontro-giulia-casa"
    static let infortuniMarco = "pos-marco-infortuni-famiglia"
    /// Il motivo di prova per «Ruby non è pronta».
    static let motivoNonPronta = "Ollama non è aperto: avvialo sul Mac e scegli il modello \(MotoreLocale.modelloPredefinito)."

    static func prepara(_ s: StatoShell, cal: Calendar = .current) {
        let oggi = cal.startOfDay(for: Date())
        if let i = s.dati.incontri.firstIndex(where: { $0.id == incontroGiulia }) {
            let ieri = cal.date(byAdding: .day, value: -1, to: oggi) ?? oggi
            s.dati.incontri[i].data = cal.date(bySettingHour: 17, minute: 30, second: 0, of: ieri) ?? ieri
            s.dati.incontri[i].stato = .concluso
            s.dati.incontri[i].decisioni = "Portare il versamento per la casa a 550 € al mese e preparare il confronto per il fondo pensione"
            s.dati.incontri[i].prossimaAttivita = "Mandare i prospetti della casa e della pensione"
            s.dati.incontri[i].prossimoIncontro = cal.date(byAdding: .day, value: 30, to: oggi)
        }
        if let p = s.dati.posizioni.firstIndex(where: { $0.id == infortuniMarco }) {
            s.dati.posizioni[p].stato = .inEssere
            s.dati.posizioni[p].scadenza = cal.date(byAdding: .day, value: RegoleMessaggi.giorniScadenzaPredefiniti, to: oggi)
        }
        if let c = s.dati.clienti.firstIndex(where: { $0.id == "sofia" }) {
            s.dati.clienti[c].consensi.marketing = true
            s.dati.clienti[c].consensi.dataMarketing = cal.date(byAdding: .month, value: -25, to: oggi)
        }
    }

    /// Prepara i dati, chiede l'occasione, il tono, il canale e chi scrive, e apre Messaggi.
    static func apri(_ s: StatoShell, tipo: TipoOccasioneMessaggio, cliente: String, tono: TonoMessaggio = .cordiale,
                     canale: CanaleMessaggio = .mail, ruby: Bool = true) {
        prepara(s)
        if !ruby { s.disponibilitaLocale = .nonDisponibile(motivoNonPronta) }
        RichiestaIstantaneaMessaggi.chiedi(s, tipo: tipo, cliente: cliente, tono: tono, canale: canale, ruby: ruby,
                                           motivoNonPronta: ruby ? nil : motivoNonPronta)
        s.apri(.messaggi)
    }

    /// Nessuna occasione: Prisma senza clienti (lo stato vero appena installato).
    static func vuoto(_ s: StatoShell) {
        s.dati.clienti.removeAll()
        s.apri(.messaggi)
    }
}

#if os(macOS)
/// Le istantanee di Messaggi (Design/template-novita-specifica.md §5.7), 490-496 in chiaro e in scuro, tutte nello
/// stato finale (`\.modoIstantanea`): testo completo, nessun puntino, pillole al loro posto. iPhone (497) e iPad (498)
/// sono in iOS/IstantaneeMobile.swift. Dati di prova in `MessaggiDiProva`.
/// - 490: il riepilogo dell'incontro di Giulia, Cordiale, Mail, scritto da Ruby;
/// - 491: lo stesso con Messaggi e Breve: la nuvoletta blu e «Apri in Messaggi»;
/// - 492: la scadenza di Marco, Formale, Mail con l'oggetto;
/// - 493: il consenso commerciale di Sofia, scelto in «Questa settimana»;
/// - 494: Ruby non è pronta: il testo di Prisma con la riga che lo spiega;
/// - 495: Marco senza indirizzo email: la testata lo dice e il pulsante porta al dossier;
/// - 496: nessuna occasione.
extension Istantanee {
    nonisolated static var sceneMessaggi: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("490-messaggi-apple", { s in MessaggiDiProva.apri(s, tipo: .riepilogoIncontro, cliente: "giulia") }),
            ("490-messaggi-apple-scuro", { s in MessaggiDiProva.apri(s, tipo: .riepilogoIncontro, cliente: "giulia") }),
            ("491-messaggi-sms", { s in
                MessaggiDiProva.apri(s, tipo: .riepilogoIncontro, cliente: "giulia", tono: .breve, canale: .messaggi)
            }),
            ("491-messaggi-sms-scuro", { s in
                MessaggiDiProva.apri(s, tipo: .riepilogoIncontro, cliente: "giulia", tono: .breve, canale: .messaggi)
            }),
            ("492-messaggi-formale", { s in MessaggiDiProva.apri(s, tipo: .scadenzaPosizione, cliente: "marco", tono: .formale) }),
            ("492-messaggi-formale-scuro", { s in MessaggiDiProva.apri(s, tipo: .scadenzaPosizione, cliente: "marco", tono: .formale) }),
            ("493-messaggi-consenso", { s in MessaggiDiProva.apri(s, tipo: .consenso, cliente: "sofia") }),
            ("493-messaggi-consenso-scuro", { s in MessaggiDiProva.apri(s, tipo: .consenso, cliente: "sofia") }),
            ("494-messaggi-ruby-non-pronta", { s in
                MessaggiDiProva.apri(s, tipo: .scadenzaPosizione, cliente: "marco", ruby: false)
            }),
            ("494-messaggi-ruby-non-pronta-scuro", { s in
                MessaggiDiProva.apri(s, tipo: .scadenzaPosizione, cliente: "marco", ruby: false)
            }),
            ("495-messaggi-recapito-mancante", { s in senzaEmailMarco(s) }),
            ("495-messaggi-recapito-mancante-scuro", { s in senzaEmailMarco(s) }),
            ("496-messaggi-vuoto", { s in MessaggiDiProva.vuoto(s) }),
            ("496-messaggi-vuoto-scuro", { s in MessaggiDiProva.vuoto(s) }),
        ]
    }

    /// Marco senza indirizzo email nel dossier (solo nella scena).
    nonisolated static func senzaEmailMarco(_ s: StatoShell) {
        if let i = s.dati.clienti.firstIndex(where: { $0.id == "marco" }) { s.dati.clienti[i].email = "" }
        MessaggiDiProva.apri(s, tipo: .scadenzaPosizione, cliente: "marco")
    }
}
#endif
