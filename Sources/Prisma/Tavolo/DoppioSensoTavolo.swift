import Foundation

// Il tavolo a doppio senso («Luce» giro 16, decisioni 48, 49 e 113): dai motori di Prisma ai contenuti minimi che
// vanno all'iPad, e ritorno. Comune al Mac e all'iPad, senza viste: le prove lo usano tutte e due le parti.
// Solo ciò che l'iPad mostra: nome di battesimo, cifre già calcolate, niente identificativi.

extension MotoreRealtaAumentata {
    /// Il cristallo per l'iPad del tavolo.
    static func tavolo(_ e: EsitoRealta, nome: String, scattoConStanza: Bool, ultimoScatto: String? = nil) -> RealtaTavolo {
        RealtaTavolo(nome: nome,
                     strati: e.strati.map {
                         StratoRealtaTavolo(classe: $0.classe.rawValue, nome: $0.nome, quota: ProtocolloTavolo.cifra($0.quota),
                                            valoreOggi: ProtocolloTavolo.cifra($0.valoreOggi))
                     },
                     anni: e.anni.map { AnnoRealtaTavolo(anno: $0.anno, eta: $0.eta, totale: ProtocolloTavolo.cifra($0.totale)) },
                     totaleOggi: ProtocolloTavolo.cifra(e.totaleOggi), stimata: e.stimata, motivoSenzaAnni: e.motivoSenzaAnni,
                     scattoConStanza: scattoConStanza, ultimoScatto: ultimoScatto)
    }

    /// Il cristallo dall'iPad: le classi sconosciute (un Mac più nuovo) si scartano, le quote restano quelle mandate.
    static func daTavolo(_ r: RealtaTavolo) -> EsitoRealta {
        let strati: [StratoRealta] = r.strati.compactMap { s in
            guard let c = ComposizioneInvestimenti360.Classe(rawValue: s.classe), s.quota > 0, s.quota.isFinite else { return nil }
            return StratoRealta(classe: c, nome: s.nome, quota: s.quota, valoreOggi: s.valoreOggi)
        }
        let anni = r.anni.map { AnnoRealta(anno: $0.anno, eta: $0.eta, totale: max(0, $0.totale)) }
        let massimo = max(r.totaleOggi, anni.map(\.totale).max() ?? 0)
        return EsitoRealta(totaleOggi: r.totaleOggi, strati: strati, anni: anni, stimata: r.stimata,
                           motivoSenzaAnni: r.motivoSenzaAnni, massimo: massimo)
    }
}

extension CartaLanciaTavolo {
    /// La carta di un anno lanciato (titolo, frasi delle due vite, tono).
    static func da(_ a: AnnoLanciato) -> CartaLanciaTavolo {
        CartaLanciaTavolo(anno: a.anno, titolo: a.titolo, fraseCon: a.effettoCon.frase, fraseSenza: a.effettoSenza.frase,
                          tono: a.tono.rawValue)
    }
}

extension LanciaAnnoTavolo {
    /// Le due vite della partita, già calcolate dal Mac.
    static func da(_ p: PartitaLanciaAnno, nome: String, avvertenza: String) -> LanciaAnnoTavolo {
        LanciaAnnoTavolo(nome: nome, annoCorrente: p.annoCorrente, anniLanciati: p.anni.count, anniMassimi: p.anniMassimi,
                         serieCon: ProtocolloTavolo.cifre(p.con.serie), serieSenza: ProtocolloTavolo.cifre(p.senza.serie),
                         valoreCon: ProtocolloTavolo.cifra(p.con.valore), valoreSenza: ProtocolloTavolo.cifra(p.senza.valore),
                         ultimaCarta: p.anni.last.map(CartaLanciaTavolo.da), finita: p.finita, avvertenza: avvertenza)
    }
}

extension TrattoTavolo {
    /// I punti del tratto nell'area del grafico in età ed euro, come `prepara(assi:ingresso:)` del disegno sul Mac:
    /// x da `etaOggi` per gli anni dell'asse, y = 0 in basso fino al massimo dell'asse.
    func dati(etaOggi: Int, anni: Double, massimo: Double) -> [(eta: Double, valore: Double)] {
        punti.map { (eta: Double(etaOggi) + $0.x * anni, valore: $0.y * massimo) }
    }
}
