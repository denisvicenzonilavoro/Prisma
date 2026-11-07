#if os(macOS)
import Foundation

/// Le istantanee di Studio › Track record (Design/template-novita-specifica.md §4.7), 520-525 in chiaro e in scuro,
/// tutte nello stato finale (`\.modoIstantanea`):
/// - 520: dati di prova completi (tre accettate con un risultato, una rimandata, una rifiutata);
/// - 521: il dettaglio della prima accettata (cifra, due linee, legenda, note, piede);
/// - 522: il dettaglio della rifiutata (senza cifra né linee);
/// - 523: lo stato vero dei dati di prova, senza raccomandazioni registrate (stato vuoto);
/// - 524: accettate senza valori aggiornati e con un riferimento mancante («da misurare», tile 4 «—»);
/// - 525: un'accettata con risultato negativo, in rosso.
///
/// DATI DI PROVA DICHIARATI: le raccomandazioni, le posizioni «pos-prova-track-…» e l'indice «Conto deposito (di prova)»
/// con i suoi valori annui esistono SOLO dentro queste scene (lo stato dell'istantanea non si salva). Sono cifre
/// dimostrative inventate per vedere la scheda, non dati veri né rendimenti reali; a schermo il titolo porta
/// «dati di prova» (i clienti sono quelli di prova).
enum CasoTrackRecordIstantanee {
    case completo, daMisurare, negativo
}

extension Istantanee {
    nonisolated static var sceneTrackRecord: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("520-studio-track", { s in preparaTrackRecord(s, .completo, dettaglio: nil) }),
            ("520-studio-track-scuro", { s in preparaTrackRecord(s, .completo, dettaglio: nil) }),
            ("521-studio-track-dettaglio", { s in preparaTrackRecord(s, .completo, dettaglio: idTrackMarco) }),
            ("521-studio-track-dettaglio-scuro", { s in preparaTrackRecord(s, .completo, dettaglio: idTrackMarco) }),
            ("522-studio-track-dettaglio-rifiutata", { s in preparaTrackRecord(s, .completo, dettaglio: idTrackAndrea) }),
            ("522-studio-track-dettaglio-rifiutata-scuro", { s in preparaTrackRecord(s, .completo, dettaglio: idTrackAndrea) }),
            // Lo stato vero dei dati di prova: nessuna raccomandazione registrata
            ("523-studio-track-vuoto", { s in s.apriStudio(.track) }),
            ("523-studio-track-vuoto-scuro", { s in s.apriStudio(.track) }),
            ("524-studio-track-da-misurare", { s in preparaTrackRecord(s, .daMisurare, dettaglio: nil) }),
            ("524-studio-track-da-misurare-scuro", { s in preparaTrackRecord(s, .daMisurare, dettaglio: nil) }),
            ("525-studio-track-negativo", { s in preparaTrackRecord(s, .negativo, dettaglio: nil) }),
            ("525-studio-track-negativo-scuro", { s in preparaTrackRecord(s, .negativo, dettaglio: nil) }),
        ]
    }

    nonisolated static let idTrackMarco = "racc-pos-prova-track-marco"
    nonisolated static let idTrackAndrea = "racc-pos-prova-track-andrea"
    /// L'indice di prova delle scene: un «conto deposito» con valori annui inventati.
    nonisolated static let indiceTrackDiProva = "indice-prova-conto-deposito"

    /// Studio › Track record con le raccomandazioni di prova del caso, ed eventualmente un dettaglio già aperto.
    nonisolated static func preparaTrackRecord(_ s: StatoShell, _ caso: CasoTrackRecordIstantanee, dettaglio: String?) {
        trackRecordDiProva(s, caso)
        if let dettaglio { RichiestaIstantaneaTrack.chiedi(s, dettaglio: dettaglio) }
        s.apriStudio(.track)
    }

    /// Le posizioni, l'indice e le raccomandazioni di prova (dichiarati nella documentazione del file).
    nonisolated static func trackRecordDiProva(_ s: StatoShell, _ caso: CasoTrackRecordIstantanee) {
        let cal = Calendar.current
        let oggi = cal.startOfDay(for: Date())
        let anno = cal.component(.year, from: oggi)
        func mesi(_ n: Int) -> Date {
            ValoriDaDocumento.mezzogiorno(cal.date(byAdding: .month, value: -n, to: oggi) ?? oggi)
        }
        func giorni(_ n: Int, da d: Date) -> Date {
            ValoriDaDocumento.mezzogiorno(cal.date(byAdding: .day, value: n, to: d) ?? d)
        }

        // L'indice di prova: nel caso «da misurare» ha solo l'ultimo anno, così i versamenti più vecchi restano scoperti
        let indice = indiceTrackDiProva
        var riferimenti = s.dati.impostazioni.riferimenti
        riferimenti.indici.removeAll { $0.id == indice }
        riferimenti.indici.append(IndiceRiferimento(id: indice, nome: "Conto deposito (di prova)",
                                                    fonte: "Valori dimostrativi delle istantanee, non dati veri"))
        riferimenti.valori.removeAll { $0.serie == indice }
        let valori: [Double] = caso == .daMisurare ? [2.5] : [2.0, 2.4, 3.1, 2.8, 2.5]
        for (i, v) in valori.enumerated() {
            riferimenti.valori.append(ValoreRiferimento(serie: indice, anno: anno - valori.count + i, valore: v))
        }
        s.dati.impostazioni.riferimenti = riferimenti

        func posizione(_ cliente: String, _ canale: Canale, _ stato: StatoPosizione, _ area: AreaPosizione, _ nome: String,
                       _ configura: (inout Posizione) -> Void) -> Posizione {
            var p = Posizione(clienteId: cliente, canale: canale, stato: stato, area: area, nome: nome)
            p.id = "pos-prova-track-\(cliente)"
            p.creataIl = mesi(30)
            configura(&p)
            return p
        }
        func rilevazione(_ m: Int, _ valore: Double, _ versato: Double) -> Rilevazione {
            Rilevazione(data: mesi(m), controvalore: valore, versato: versato)
        }

        // Marco Bianchi: fondo pensione da 450 € al mese, accettato 26 mesi fa (nel caso «da misurare» 8 mesi fa, un valore)
        let marco = posizione("marco", .indipendente, .inEssere, .previdenza, "Fondo pensione aperto") { p in
            p.esito = .accettata
            p.premio = 450
            p.frequenza = .mensile
            p.dataValore = giorni(-5, da: oggi)
            if caso == .daMisurare {
                p.decorrenza = mesi(8)
                p.totaleVersato = 8 * 450
                p.controvalore = 3_640
            } else {
                p.decorrenza = mesi(26)
                p.totaleVersato = 26 * 450
                p.controvalore = 13_300
                p.rilevazioni = [rilevazione(20, 2_760, 2_700), rilevazione(14, 5_610, 5_400),
                                 rilevazione(8, 8_610, 8_100), rilevazione(2, 11_780, 10_800)]
            }
        }
        // Giulia Rossi: piano di risparmio rivalutabile da 300 € al mese, accettato 20 mesi fa
        let giulia = posizione("giulia", .alleanza, .inEssere, .risparmio, "Piano di risparmio rivalutabile") { p in
            p.esito = .accettata
            p.premio = 300
            p.frequenza = .mensile
            p.decorrenza = mesi(20)
            p.dataValore = giorni(-5, da: oggi)
            p.totaleVersato = 20 * 300
            p.controvalore = 6_290
            p.rilevazioni = [rilevazione(14, 1_830, 1_800), rilevazione(8, 3_700, 3_600), rilevazione(2, 5_600, 5_400)]
        }
        // Laura Moretti: 20.000 € in un portafoglio di ETF, accettato 15 mesi fa (nel caso «da misurare» 30 mesi fa;
        // nel caso «negativo» il valore è sceso sotto l'alternativa)
        let laura = posizione("laura", .indipendente, .inEssere, .investimento, "Portafoglio ETF bilanciato") { p in
            let inizio = caso == .daMisurare ? mesi(30) : mesi(15)
            p.esito = .accettata
            p.versamentoIniziale = 20_000
            p.frequenza = .unica
            p.decorrenza = inizio
            p.movimenti = [Movimento(data: inizio, importo: 20_000)]
            p.totaleVersato = 20_000
            p.dataValore = giorni(-5, da: oggi)
            if caso == .negativo {
                p.controvalore = 19_250
                p.rilevazioni = [rilevazione(9, 19_900, 20_000), rilevazione(3, 19_500, 20_000)]
            } else {
                p.controvalore = 21_600
                p.rilevazioni = [rilevazione(9, 20_650, 20_000), rilevazione(3, 21_150, 20_000)]
            }
        }
        // Sofia Romano: rendita integrativa presentata 5 mesi fa e rimandata a gennaio
        let sofia = posizione("sofia", .alleanza, .proposta, .previdenza, "Rendita integrativa") { p in
            p.esito = .rimandata
            p.versamentoIniziale = 120_000
            var seguito = SeguitoProposta()
            seguito.presentataIl = mesi(5)
            seguito.esitoIl = mesi(4)
            let gennaio = cal.date(from: DateComponents(year: anno + 1, month: 1, day: 15)) ?? oggi
            seguito.riprendereIl = ValoriDaDocumento.mezzogiorno(gennaio)
            p.seguito = seguito
        }
        // Andrea Conti: temporanea caso morte da 200.000 € presentata 12 mesi fa e rifiutata
        let andrea = posizione("andrea", .alleanza, .proposta, .protezione, "Temporanea caso morte") { p in
            p.esito = .rifiutata
            p.capitaleAssicurato = 200_000
        }
        // Nel caso «da misurare» nessuna accettata si misura: il piano di Giulia (che si misurerebbe) resta fuori
        let posizioni = caso == .daMisurare ? [marco, laura, sofia, andrea] : [marco, giulia, laura, sofia, andrea]
        let ids = Set(posizioni.map(\.id))
        s.dati.posizioni.removeAll { ids.contains($0.id) }
        s.dati.posizioni += posizioni

        func alternativa(_ testo: String, serie: Bool) -> AlternativaRaccomandazione {
            AlternativaRaccomandazione(tipo: serie ? .riferimento : .altro, descrizione: testo,
                                       serieRiferimento: serie ? indice : nil, ricavata: false)
        }
        func raccomandazione(_ p: Posizione, il data: Date, perche: String, invece: AlternativaRaccomandazione,
                             scelta: SceltaCliente?, sceltaIl: Date?) -> Raccomandazione {
            var r = Raccomandazione(id: "racc-\(p.id)", data: data, clienteId: p.clienteId, posizioneId: p.id,
                                    canale: p.canale, area: p.area, proposta: MotoreTrackRecord.titolo(p),
                                    motivazione: perche, cifre: MotoreTrackRecord.cifre(p, adeguatezza: nil),
                                    alternativa: invece)
            r.registraScelta(.inAttesa, il: data)
            if let scelta, let sceltaIl { r.registraScelta(scelta, il: sceltaIl) }
            return r
        }
        let inizioMarco = marco.decorrenza ?? oggi
        var rMarco = raccomandazione(
            marco, il: giorni(-12, da: inizioMarco),
            perche: "Divario pensionistico stimato in 1.100 € al mese e una deduzione fiscale che restava inutilizzata.",
            invece: alternativa("Nessun versamento integrativo: i soldi restano sul conto deposito", serie: true),
            scelta: .accettata, sceltaIl: giorni(-3, da: inizioMarco))
        rMarco.aggiungiNota("Rivisto il piano con il cliente: versamento confermato, nessun riscatto.", il: mesi(6))
        let inizioGiulia = giulia.decorrenza ?? oggi
        let rGiulia = raccomandazione(
            giulia, il: giorni(-10, da: inizioGiulia),
            perche: "Un fondo per gli studi dei figli in dieci anni, con il capitale garantito a scadenza.",
            invece: alternativa("Lasciare i soldi sul conto deposito", serie: true),
            scelta: .accettata, sceltaIl: giorni(-2, da: inizioGiulia))
        let inizioLaura = laura.decorrenza ?? oggi
        let rLaura = raccomandazione(
            laura, il: giorni(-14, da: inizioLaura),
            perche: "Liquidità ferma oltre il fondo di emergenza e un orizzonte di sette anni.",
            invece: alternativa("Lasciare il capitale sul conto deposito", serie: true),
            scelta: .accettata, sceltaIl: giorni(-4, da: inizioLaura))
        let rSofia = raccomandazione(
            sofia, il: mesi(5),
            perche: "Integrare la pensione con una rendita certa a partire dai 67 anni.",
            invece: alternativa("Prelievi liberi dal conto", serie: false),
            scelta: nil, sceltaIl: nil)
        let rAndrea = raccomandazione(
            andrea, il: mesi(12),
            perche: "Mutuo in corso e due figli a carico: il reddito della famiglia non era protetto.",
            invece: alternativa("Nessuna copertura", serie: false),
            scelta: .rifiutata, sceltaIl: mesi(11))
        let elenco = caso == .daMisurare ? [rMarco, rLaura, rSofia, rAndrea] : [rMarco, rGiulia, rLaura, rSofia, rAndrea]
        let idsRacc = Set(elenco.map(\.id))
        s.dati.raccomandazioni.removeAll { idsRacc.contains($0.id) }
        s.dati.raccomandazioni += elenco
    }
}
#endif
