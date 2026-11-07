import Foundation

/// Prove di Inquadra e capisci (Orizzonte, giro 5; specifica §9.5.5), chiamate da `ProvaCalcoli.esegui()`: dai testi
/// di prova (polizze inventate, nessun dato vero) i dati della posizione con l'intervallo da cui vengono e il riquadro
/// delle righe; la frequenza del premio («al mese», «all'anno»); la posizione creata dal documento con la frequenza
/// letta (non più sempre annuale) e il premio unico nel versamento iniziale.
enum ProvaCalcoliInquadra {
    /// Il foglio di prova: una vita intera di una compagnia inventata, letta riga per riga con il riquadro.
    static let foglio: [RigaLetta] = [
        RigaLetta(testo: "COMPAGNIA ESEMPIO VITA", riquadro: RiquadroPagina(x: 0.10, y: 0.05, larghezza: 0.50, altezza: 0.04)),
        RigaLetta(testo: "Polizza n. VI-2021-004512", riquadro: RiquadroPagina(x: 0.10, y: 0.12, larghezza: 0.40, altezza: 0.03)),
        RigaLetta(testo: "Contraente: Anna Verdi", riquadro: RiquadroPagina(x: 0.10, y: 0.18, larghezza: 0.45, altezza: 0.03)),
        RigaLetta(testo: "Premio: 90,00 € al mese", riquadro: RiquadroPagina(x: 0.10, y: 0.24, larghezza: 0.42, altezza: 0.03)),
        RigaLetta(testo: "Capitale assicurato: € 50.000,00", riquadro: RiquadroPagina(x: 0.10, y: 0.30, larghezza: 0.55, altezza: 0.03)),
        RigaLetta(testo: "Decorrenza: 01/03/2021", riquadro: RiquadroPagina(x: 0.10, y: 0.36, larghezza: 0.35, altezza: 0.03)),
        RigaLetta(testo: "Tipo: Vita intera a premio ricorrente", riquadro: RiquadroPagina(x: 0.10, y: 0.42, larghezza: 0.60, altezza: 0.03)),
        RigaLetta(testo: "Compagnia: Esempio Vita S.p.A.", riquadro: RiquadroPagina(x: 0.10, y: 0.48, larghezza: 0.50, altezza: 0.03)),
    ]

    static func esegui(_ verifica: VerificaCalcoli) {
        let d = MotoreInquadra.leggi(foglio)
        func testo(_ c: CampoDocumento) -> String? { d.campo(c).flatMap { $0.intervallo.testo(in: d.testo) } }

        // IQ1. I sei campi, nell'ordine della scheda, con il valore e il testo da cui vengono
        verifica.vero("IQ1 Campi trovati nell'ordine: contraente, premio, capitale, decorrenza, tipo, compagnia",
                      d.campi.map(\.campo) == MotoreInquadra.campiPosizione)
        verifica.vero("IQ1 Contraente «Anna Verdi» dalla riga 3", d.contraente == "Anna Verdi" && testo(.contraente) == "Anna Verdi" && d.campo(.contraente)?.righe == [2])
        verifica("IQ1 Premio 90", d.premio ?? -1, 90)
        verifica.vero("IQ1 Premio con la frequenza: «90,00 € al mese»", testo(.premio) == "90,00 € al mese" && d.frequenza == .mensile)
        verifica("IQ1 Premio dell'anno: 90 × 12", d.premioAnnuo ?? -1, 1_080)
        verifica("IQ1 Capitale assicurato 50.000", d.capitale ?? -1, 50_000)
        verifica.vero("IQ1 Decorrenza 1° marzo 2021", d.decorrenza == EstrattoreDocumento.data("01/03/2021") && testo(.decorrenza) == "01/03/2021")
        verifica.vero("IQ1 Tipo e compagnia", d.tipo == "Vita intera a premio ricorrente" && d.compagnia == "Esempio Vita S.p.A.")
        // IQ2. Il riquadro da illuminare è quello della riga da cui viene il campo
        verifica.vero("IQ2 Riquadro del premio = riga 4 del foglio", d.campo(.premio)?.riquadro == foglio[3].riquadro && d.campo(.premio)?.righe == [3])
        let unito = RiquadroPagina(x: 0.1, y: 0.2, larghezza: 0.3, altezza: 0.1).unito(RiquadroPagina(x: 0.2, y: 0.25, larghezza: 0.4, altezza: 0.1))
        verifica.vero("IQ2 Due righe insieme: il riquadro che le contiene", abs(unito.x - 0.1) < 1e-9 && abs(unito.y - 0.2) < 1e-9
                      && abs(unito.larghezza - 0.5) < 1e-9 && abs(unito.altezza - 0.15) < 1e-9)
        verifica.vero("IQ2 Riquadri fuori dalla pagina riportati dentro", RiquadroPagina(x: -0.2, y: 0.9, larghezza: 2, altezza: 0.5)
                      == RiquadroPagina(x: 0, y: 0.9, larghezza: 1, altezza: 0.1))
        // Dal testo semplice (un PDF): stessi campi, senza riquadri
        let semplice = MotoreInquadra.leggi(testo: foglio.map(\.testo).joined(separator: "\n"))
        verifica.vero("IQ2 Testo senza riquadri: stessi valori, riquadro assente",
                      semplice.campi.map(\.valore) == d.campi.map(\.valore) && semplice.campi.allSatisfy { $0.riquadro == nil })

        // IQ3. La frequenza del premio scritta dopo la cifra
        let casi: [(String, Frequenza?)] = [
            ("Premio: 90,00 € al mese", .mensile), ("90 € all’anno", .annuale), ("Premio: 120 euro ogni mese", .mensile),
            ("Premio: 380,00", nil), ("Premio annuo: 380,00", .annuale), ("Premio: 250 € al trimestre", .trimestrale),
        ]
        for (riga, attesa) in casi {
            verifica.vero("IQ3 Frequenza: «\(riga)»", MotoreConfrontoDossier.frequenzaPremio(riga) == attesa)
        }
        // L'estratto del premio tiene la coda della riga, solo se la frequenza non è già prima della cifra
        let estratti = EstrattoreDocumento.conRegole(["Premio: 90,00 € al mese\nPremio annuo: 380,00 rate mensili"])
        verifica.vero("IQ3 L'estratto del premio arriva fino alla frequenza", estratti.first { $0.chiave == .premio }?.estratto == "Premio: 90,00 € al mese")
        let annuo = EstrattoreDocumento.conRegole(["Premio annuo: 380,00 rate mensili"]).first { $0.chiave == .premio }
        verifica.vero("IQ3 «Premio annuo … rate mensili» resta annuo", annuo.map { MotoreConfrontoDossier.frequenzaPremio($0.estratto) } == .annuale)

        // IQ4. La posizione creata dal documento usa la frequenza letta (prima era sempre annuale)
        var documento = MotoreInquadra.documento(d, clienteId: "prova", titolo: "Polizza inquadrata")
        verifica.vero("IQ4 Il documento nasce con i dati da confermare", !documento.campi.isEmpty && documento.campi.allSatisfy { !$0.confermato })
        let senzaConferma = StatoShell.posizioneDaDocumento(documento, canale: .indipendente, area: .protezione)
        verifica("IQ4 Senza conferma niente premio", senzaConferma.premio, 0)
        for i in documento.campi.indices { documento.campi[i].confermato = true }
        let p = StatoShell.posizioneDaDocumento(documento, canale: .indipendente, area: .protezione)
        verifica.vero("IQ4 Posizione: frequenza mensile", p.frequenza == .mensile)
        verifica("IQ4 Posizione: premio 90", p.premio, 90)
        verifica("IQ4 Posizione: premio dell'anno 1.080", p.premioAnnuo, 1_080)
        verifica.vero("IQ4 Posizione: contraente, compagnia, tipo, capitale, decorrenza",
                      p.contraente == "Anna Verdi" && p.emittente == "Esempio Vita S.p.A." && p.tipologia == "Vita intera a premio ricorrente"
                        && p.capitaleAssicurato == 50_000 && p.decorrenza == EstrattoreDocumento.data("01/03/2021"))
        // Premio unico: nel versamento iniziale, senza rate
        var unico = Documento(clienteId: "prova", titolo: "Unico", tipo: .polizza)
        unico.campi = EstrattoreDocumento.conRegole(["Premio unico: 50.000,00"]).map { var c = $0; c.confermato = true; return c }
        let u = StatoShell.posizioneDaDocumento(unico, canale: .indipendente, area: .risparmio)
        verifica.vero("IQ4 Premio unico: versamento iniziale 50.000, frequenza unica", u.versamentoIniziale == 50_000 && u.premio == 0 && u.frequenza == .unica)
        // Senza frequenza scritta: annuale, con la nota «da confermare»
        var muto = Documento(clienteId: "prova", titolo: "Muto", tipo: .polizza)
        muto.campi = EstrattoreDocumento.conRegole(["Premio: 380,00"]).map { var c = $0; c.confermato = true; return c }
        let m = StatoShell.posizioneDaDocumento(muto, canale: .alleanza, area: .protezione)
        verifica.vero("IQ4 Premio senza frequenza: annuale da confermare", m.frequenza == .annuale && m.premio == 380 && m.note.contains("da confermare")
                      && m.emittente == "Alleanza Assicurazioni")

        // IQ5. Un foglio senza la riga «Tipo»: la copertura scritta nel testo, con il premio annuo lordo
        let tcm = MotoreInquadra.leggi(testo: """
            Proposta di assicurazione temporanea caso morte
            Contraente: Marco Neri
            Premio annuo lordo: € 456,30
            Capitale caso morte: 150.000,00
            """)
        verifica.vero("IQ5 Tipo dal testo: «Temporanea caso morte»", tcm.tipo == "Temporanea caso morte" && tcm.campo(.tipologia)?.righe == [0])
        verifica.vero("IQ5 Premio annuo lordo 456,30 l'anno", tcm.premio == 456.3 && tcm.frequenza == .annuale)
        verifica("IQ5 Capitale caso morte 150.000", tcm.capitale ?? -1, 150_000)
        verifica.vero("IQ5 Il tipo ricavato entra tra i dati del documento", tcm.estratti.contains { $0.chiave == .tipologia && $0.valore == "Temporanea caso morte" })
        // IQ6. Niente inventato: un foglio senza dati non dà campi
        let vuoto = MotoreInquadra.leggi(testo: "Gentile cliente,\nla ringraziamo per la fiducia.")
        verifica.vero("IQ6 Un foglio senza dati non dà campi né frequenza", vuoto.campi.isEmpty && vuoto.frequenza == nil && vuoto.premioAnnuo == nil)
    }
}
