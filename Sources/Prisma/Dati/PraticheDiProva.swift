import Foundation

/// Le quattro pratiche del template (Design/template-luce-specifica.md §7.3.7), solo nei dati di prova (`DatiPrisma.demo()`
/// e quindi `ClientiFittizi.completi()`), su posizioni che i clienti di prova hanno già, con le date relative a oggi.
/// Ogni pratica ha l'id con il prefisso «pratica-prova-» e la nota «Dati di prova»: la scheda lo dice accanto al titolo.
/// I passi sono segni a mano; Prisma aggiunge quelli che riconosce dai dati (per Giulia il numero di contratto della
/// polizza già in essere, tolto a mano perché è del contratto precedente).
/// - Giulia · Piano di risparmio rivalutabile · Alleanza: 4 di 6, emissione in corso, ultimo passo 3 giorni fa;
/// - Marco · Infortuni famiglia · Alleanza: 3 di 6, ferma da 9 giorni, manca il primo premio;
/// - Laura · Fondo pensione aperto · indipendente: 5 di 6, da consegnare, ultimo passo ieri;
/// - Sofia · Non autosufficienza · Alleanza: completata alla fine del mese scorso.
enum PraticheDiProva {
    static let prefisso = "pratica-prova-"
    static let nota = "Dati di prova: pratica dimostrativa del template."

    static func pratiche(oggi: Date = Date(), calendario: Calendar = Calendar(identifier: .gregorian)) -> [Pratica] {
        let inizio = calendario.startOfDay(for: oggi)
        func giorno(_ n: Int, _ base: Date? = nil) -> Date {
            let g = calendario.date(byAdding: .day, value: n, to: base ?? inizio) ?? inizio
            // A mezzogiorno e al secondo intero: l'archivio JSON non conserva le frazioni
            return calendario.date(bySettingHour: 12, minute: 0, second: 0, of: g) ?? g
        }
        func pratica(_ chiave: String, _ posizione: String, aperta: Date, fatti: [(PassoPratica, Date)]) -> Pratica {
            var p = Pratica(id: prefisso + chiave, posizioneId: posizione, apertaIl: aperta)
            for (passo, data) in fatti { p.passi[passo.rawValue] = SegnoPasso(fatto: true, il: data) }
            p.note = [NotaPratica(data: aperta, testo: nota)]
            return p
        }
        var giulia = pratica("giulia", "pos-giulia-piano-di-risparmio-rivalutabile", aperta: giorno(-12),
                             fatti: [(.moduli, giorno(-12)), (.documentiInformativi, giorno(-11)),
                                     (.documentoIdentita, giorno(-11)), (.primoPremio, giorno(-3))])
        // Il numero di contratto della posizione è quello del contratto già in essere: l'emissione nuova non c'è ancora
        giulia.passi[PassoPratica.polizzaEmessa.rawValue] = SegnoPasso(fatto: false, il: giorno(-3),
                                                                      nota: "Il numero di contratto è del contratto precedente.")
        let marco = pratica("marco", "pos-marco-infortuni-famiglia", aperta: giorno(-11),
                            fatti: [(.moduli, giorno(-11)), (.documentiInformativi, giorno(-10)),
                                    (.documentoIdentita, giorno(-9))])
        let laura = pratica("laura", "pos-laura-fondo-pensione-aperto", aperta: giorno(-15),
                            fatti: [(.moduli, giorno(-15)), (.documentiInformativi, giorno(-14)),
                                    (.documentoIdentita, giorno(-14)), (.primoPremio, giorno(-8)),
                                    (.polizzaEmessa, giorno(-1))])
        // Completata quattro giorni prima dell'inizio di questo mese: sempre nel mese scorso
        let mese = calendario.dateInterval(of: .month, for: inizio)?.start ?? inizio
        let fine = giorno(-4, mese)
        var sofia = pratica("sofia", "pos-sofia-non-autosufficienza", aperta: giorno(-20, fine),
                            fatti: [(.moduli, giorno(-20, fine)), (.documentiInformativi, giorno(-19, fine)),
                                    (.documentoIdentita, giorno(-19, fine)), (.primoPremio, giorno(-12, fine)),
                                    (.polizzaEmessa, giorno(-6, fine)), (.consegnata, fine)])
        sofia.conclusaIl = fine
        return [giulia, marco, laura, sofia]
    }
}
