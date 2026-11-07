#if os(macOS)
import SwiftUI

/// Le istantanee di Studio › Parcelle e fatture (Design/template-novita-specifica.md §3.7), 510-516 in chiaro e in
/// scuro, tutte nello stato finale (`\.modoIstantanea`):
/// - 510: le cinque parcelle di prova, la 2026/015 scelta, con i dati fiscali di prova completi;
/// - 511: nessuna parcella;
/// - 512: la 2026/014 con «✓ File XML pronto»;
/// - 513: senza dati fiscali del consulente (lo stato vero di Prisma appena installato): «Prepara il file XML» spento
///   e le tile arancio con ciò che manca;
/// - 514: il modulo «Nuova parcella»;
/// - 515: il foglio della fattura a grandezza piena, solo chiaro (la carta è sempre bianca);
/// - 516: Impostazioni › Studio › Dati per le fatture con i campi vuoti.
///
/// DATI DI PROVA DICHIARATI: le parcelle «parcella-prova-…» (numeri, descrizioni e importi del template, dimostrativi),
/// il consulente di prova e il REGIME DI PROVA di `ProvaFatturaPA` (RF01, IVA, contributo e ritenuta di prova: servono a
/// vedere le voci sulla carta, non sono una scelta del regime) e i dati fiscali fittizi dei clienti di prova esistono
/// SOLO dentro queste scene (lo stato dell'istantanea non si salva). A schermo le tile portano «dati di prova» e la carta
/// «Documento di prova».
extension Istantanee {
    nonisolated static var sceneParcelle: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("510-studio-parcelle", { s in preparaParcelle(s, completo: true, scelta: idParcella015) }),
            ("510-studio-parcelle-scuro", { s in preparaParcelle(s, completo: true, scelta: idParcella015) }),
            ("511-studio-parcelle-vuoto", { s in
                s.dati.parcelle.removeAll()
                s.apriStudio(.fatture)
            }),
            ("511-studio-parcelle-vuoto-scuro", { s in
                s.dati.parcelle.removeAll()
                s.apriStudio(.fatture)
            }),
            ("512-studio-parcelle-xml-pronto", { s in preparaParcelle(s, completo: true, scelta: idParcella014, xml: true) }),
            ("512-studio-parcelle-xml-pronto-scuro", { s in preparaParcelle(s, completo: true, scelta: idParcella014, xml: true) }),
            ("513-studio-parcelle-dati-mancanti", { s in preparaParcelle(s, completo: false, scelta: idParcella015) }),
            ("513-studio-parcelle-dati-mancanti-scuro", { s in preparaParcelle(s, completo: false, scelta: idParcella015) }),
            ("514-studio-nuova-parcella", { s in preparaNuovaParcella(s) }),
            ("514-studio-nuova-parcella-scuro", { s in preparaNuovaParcella(s) }),
            // Il foglio a grandezza piena: lo disegna `cartaIstantanea` al posto della shell
            ("515-fattura-carta", { s in preparaParcelle(s, completo: true, scelta: idParcella015) }),
            ("516-impostazioni-fatturazione", { s in preparaImpostazioniFatture(s) }),
            ("516-impostazioni-fatturazione-scuro", { s in preparaImpostazioniFatture(s) }),
        ]
    }

    nonisolated static let idParcella015 = "parcella-prova-015"
    nonisolated static let idParcella014 = "parcella-prova-014"

    /// Le scene che disegnano solo il foglio della fattura (sempre chiaro), non la shell.
    nonisolated static let sceneCartaFattura: Set<String> = ["515-fattura-carta"]

    /// Il foglio della fattura scelta a grandezza piena, sul fondo chiaro fisso (scena 515); nil per le altre scene.
    static func cartaIstantanea(_ nome: String, _ s: StatoShell) -> AnyView? {
        guard sceneCartaFattura.contains(nome), let p = s.dati.parcelle.first(where: { $0.id == idParcella015 }) else {
            return nil
        }
        let t = s.testiFattura(p)
        let pagina = FatturaCarta.pagine(t).first ?? AnyView(EmptyView())
        let f = Tema.Apple.CartaFattura.Misura.formato
        return AnyView(
            ZStack {
                Tema.Apple.Parcelle.Anteprima.tavoloCarta
                pagina
                    .frame(width: f.width, height: f.height)
                    .superficieApple(Tema.Apple.Parcelle.Anteprima.carta)
            }
            .environment(\.colorScheme, .light)
        )
    }

    /// Le parcelle di prova del template (dimostrative) con o senza i dati fiscali di prova, la scheda aperta e la
    /// parcella scelta; con `xml` il file della parcella scelta è già preparato.
    nonisolated static func preparaParcelle(_ s: StatoShell, completo: Bool, scelta: String, xml: Bool = false) {
        parcelleDiProva(s, completo: completo)
        let cliente = s.dati.parcelle.first { $0.id == scelta }?.clienteId ?? ""
        let nome = xml ? s.preparaFatturaPA(scelta).file.map { s.nomeFileFatturaPA($0, clienteId: cliente) } : nil
        RichiestaIstantaneaParcelle.chiedi(s, parcella: scelta, fileXML: nome)
        s.apriStudio(.fatture)
    }

    /// Il modulo «Nuova parcella» per Andrea Conti, sopra la scheda (scena 514).
    nonisolated static func preparaNuovaParcella(_ s: StatoShell) {
        parcelleDiProva(s, completo: true)
        let oggi = Calendar.current.startOfDay(for: Date())
        var bozza = Parcella(id: "parcella-prova-nuova", clienteId: "andrea", data: oggi, descrizione: "Primo check-up patrimoniale",
                             righe: [RigaParcella(id: "riga-prova-nuova", descrizione: "Primo check-up patrimoniale", importo: 450)])
        bozza.scadenza = Calendar.current.date(byAdding: .day, value: 30, to: oggi)
        RichiestaIstantaneaParcelle.chiedi(s, parcella: idParcella015, modulo: bozza)
        s.apriStudio(.fatture)
    }

    /// Impostazioni › Studio portata ai dati per le fatture, con i campi vuoti (lo stato vero).
    nonisolated static func preparaImpostazioniFatture(_ s: StatoShell) {
        s.schedaImpostazioni = .studio
        s.ancoraImpostazioni = TestiParcelle.ancoraImpostazioni
        s.apri(.impostazioni)
    }

    /// Le cinque parcelle del template, datate a ritroso da oggi (la bozza ieri, la più vecchia 46 giorni fa), emesse in
    /// ordine con la numerazione «{anno}/{numero:3}» dal 12: 012 e 015 da incassare, 013 e 014 pagate, la bozza senza
    /// numero. `completo`: il consulente di prova con il regime di prova (voci fiscali sulla carta) e i dati fiscali
    /// fittizi dei clienti; altrimenti nessun dato fiscale (importi provvisori, «Prepara il file XML» spento).
    nonisolated static func parcelleDiProva(_ s: StatoShell, completo: Bool) {
        let cal = Calendar.current
        let oggi = cal.startOfDay(for: Date())
        func fa(_ giorni: Int) -> Date { cal.date(byAdding: .day, value: -giorni, to: oggi) ?? oggi }
        var f = completo ? ProvaFatturaPA.consulenteDiProva(regime: ProvaFatturaPA.regimeDiProvaConIVA()) : DatiFatturazione()
        f.numerazione.modello = "{anno}/{numero:3}"
        f.numerazione.primoNumeroPerAnno[cal.component(.year, from: fa(46))] = 12
        s.dati.impostazioni.studio.fatturazione = f
        if completo {
            // Dati fiscali FITTIZI dei clienti di prova (codice fiscale solo nel formato, sede di prova)
            let prova = ProvaFatturaPA.clienteDiProva()
            for i in s.dati.clienti.indices {
                var fiscale = prova.fiscale ?? DatiFiscaliCliente()
                let parti = s.dati.clienti[i].nome.split(separator: " ", maxSplits: 1).map(String.init)
                fiscale.nome = parti.first ?? ""
                fiscale.cognome = parti.count > 1 ? parti[1] : ""
                s.dati.clienti[i].fiscale = fiscale
                s.dati.clienti[i].codiceFiscale = prova.codiceFiscale
            }
        }
        // (id, cliente, descrizione, importo, giorni fa, pagata)
        let righe: [(String, String, String, Double, Int, Bool)] = [
            ("parcella-prova-012", "sofia", "Pianificazione della rendita", 750, 46, false),
            ("parcella-prova-013", "marco", "Revisione annuale del piano di famiglia", 1_500, 33, true),
            ("parcella-prova-014", "giulia", "Consulenza patrimoniale annuale", 1_200, 21, true),
            ("parcella-prova-015", "laura", "Piano previdenziale", 900, 7, false),
        ]
        var elenco: [Parcella] = []
        for (id, cliente, descrizione, importo, giorni, pagata) in righe {
            let data = fa(giorni)
            var bozza = Parcella(id: id, clienteId: cliente, data: data, descrizione: descrizione,
                                 righe: [RigaParcella(id: id + "-riga", descrizione: descrizione, importo: importo)])
            bozza.scadenza = cal.date(byAdding: .day, value: 60, to: data)
            var p = MotoreParcelle.emessa(bozza, tra: elenco, data: data, numerazione: f.numerazione, regime: f.regime)
            if pagata {
                p.stato = .pagata
                p.incassataIl = cal.date(byAdding: .day, value: 10, to: data)
            }
            elenco.append(p)
        }
        elenco.append(Parcella(id: "parcella-prova-016", clienteId: "andrea", data: fa(1), descrizione: "Primo check-up patrimoniale",
                               righe: [RigaParcella(id: "parcella-prova-016-riga", descrizione: "Primo check-up patrimoniale",
                                                    importo: 450)]))
        s.dati.parcelle = elenco
    }
}
#endif
