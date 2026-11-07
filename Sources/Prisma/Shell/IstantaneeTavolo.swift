#if os(macOS)
import Foundation

/// Le istantanee del tavolo con l'iPad (Tavolo/TavoloMac.swift, viste in Shell/AlTavolo.swift), senza rete:
/// - 470: la sala della presentazione con «Al tavolo» (iPad collegato) e la striscia dei comandi aperta;
/// - 471: la pagina finale della presa visione nel PDF (con un tratto di prova), in sala, sulla carta bianca.
extension Istantanee {
    nonisolated static var sceneTavolo: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("470-tavolo-sala", { s in
                preparaProspettiApple(s)
                if let d = s.documentoProspetto(sceltaProspettiApple) { s.presenta(d) }
                s.tavolo.mostraPerIstantanea(iPad: "iPad di Denis", mostrato: "Pagina 1 · Un anno insieme", pannello: true)
            }),
            ("471-tavolo-presa-visione", { s in
                preparaProspettiApple(s)
                guard let d = s.documentoProspetto(sceltaProspettiApple), let tratto = TrattoProvaTavolo.immagine() else { return }
                let completo = TavoloMac.documentoConPresaVisione(d, tratto: tratto, data: Date())
                s.presenta(completo, daPagina: completo.pagine.count - 1)
            }),
        ]
    }
}
#endif
