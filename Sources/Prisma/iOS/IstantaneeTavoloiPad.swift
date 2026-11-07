#if os(iOS)
import SwiftUI

/// Il tavolo finto delle istantanee dell'iPad (IstantaneeMobile, scene «50-53-tavolo-…»): niente rete, niente Mac.
/// Lo schermo si prepara qui con i dati di prova di Giulia, come lo manderebbe il Mac (`TavoloiPad.mostraPerIstantanea`).
@MainActor
enum IstantaneeTavoloiPad {
    static let mac = ClienteTavolo.Collegamento.collegato(mac: "MacBook Pro di Denis")
    static let cliente = "giulia"

    /// Una pagina del resoconto di Giulia, impaginata e passata in PNG come fa il Mac.
    static func pagina(_ m: StatoMobile) {
        m.stato.clienteAttivoId = cliente
        var schermo = ClienteTavolo.Schermo.neutra
        if let d = m.stato.documentoProspetto(.resoconto(report: false)), let p = pagina(d, indice: 0) {
            schermo = .mostra(MostraTavolo(id: "istantanea-pagina", genere: .pagina, titolo: d.titolo, cliente: d.cliente,
                                           pagine: [p]))
        }
        m.tavolo.mostraPerIstantanea(schermo, collegamento: mac)
    }

    /// Il versamento mensile della prima proposta di Giulia, con il risultato già ricalcolato (MotoreProiezione).
    static func cursore(_ m: StatoMobile) {
        m.stato.clienteAttivoId = cliente
        let proposta = m.stato.posizioniCliente(cliente).first { $0.stato == .proposta }
        var base = proposta.map { ParametriProiezione(posizione: $0) }
            ?? ParametriProiezione(capitaleIniziale: 0, versamento: 0, frequenza: .mensile,
                                   anni: IpotesiCalcolo.orizzontePredefinito, rendimento: IpotesiCalcolo.rendimentoPredefinito)
        base.frequenza = .mensile
        if base.anni <= 0 { base.anni = IpotesiCalcolo.orizzontePredefinito }
        var x = CursoreTavolo(id: "istantanea-cursore", titolo: "Versamento mensile", unita: "€ al mese", valore: 400,
                              minimo: 50, massimo: 1_000, passo: 25,
                              posizione: proposta?.nome ?? "Un piano di accumulo", canale: proposta?.canale, risultato: nil)
        x.valore = x.valido(400)
        base.versamento = x.valore
        let e = MotoreProiezione.calcola(base)
        let anni = base.anni == 1 ? "1 anno" : "\(base.anni) anni"
        x.risultato = RisultatoCursoreTavolo(
            valore: x.valore, titolo: "Fra \(anni), al netto di costi e imposte", cifra: ProtocolloTavolo.cifra(e.netto),
            righe: [RigaRisultatoTavolo(etichetta: "Versato in tutto", cifra: ProtocolloTavolo.cifra(e.versato)),
                    RigaRisultatoTavolo(etichetta: "Guadagno netto", cifra: ProtocolloTavolo.cifra(e.guadagnoNetto)),
                    RigaRisultatoTavolo(etichetta: "In euro di oggi", cifra: ProtocolloTavolo.cifra(e.reale))],
            nota: "Una stima con un rendimento del \(Formati.percentuale(base.rendimento)) l'anno: non è una previsione né una garanzia.")
        m.tavolo.mostraPerIstantanea(.cursore(x), collegamento: mac)
    }

    /// La richiesta di presa visione del resoconto, con un tratto di prova già nell'area.
    static func presaVisione(_ m: StatoMobile) {
        m.stato.clienteAttivoId = cliente
        let d = m.stato.documentoProspetto(.resoconto(report: false))
        let nome = d?.cliente ?? m.stato.cliente(cliente)?.nome ?? "Giulia"
        let r = RichiestaPresaVisioneTavolo(id: "istantanea-presa-visione",
                                            titolo: "\(d?.genere ?? "Prospetto") · \(d?.titolo ?? "Resoconto")",
                                            cliente: nome, pagine: d?.pagine.count ?? 1,
                                            testo: ProtocolloTavolo.testoPresaVisione)
        m.tavolo.mostraPerIstantanea(.presaVisione(r), collegamento: mac, tratto: TrattoTavoloiPad.prova)
    }

    /// La schermata neutra dopo una caduta: il logo e la riga «In attesa del Mac…», nessun dato.
    static func neutra(_ m: StatoMobile) {
        m.tavolo.mostraPerIstantanea(.neutra, collegamento: .caduto)
    }

    /// La pagina `indice` in PNG a 2× su carta bianca e in chiaro, come `TavoloMac.pagina` sul Mac.
    static func pagina(_ d: DocumentoStampabile, indice i: Int) -> PaginaTavolo? {
        guard d.pagine.indices.contains(i) else { return nil }
        let foglio = d.pagine[i]
            .frame(width: d.formato.width, height: d.formato.height)
            .background(Tema.Apple.Carta.fondo)
            .environment(\.etichetteStampa, true)
            .environment(\.colorScheme, .light)
        let renderer = ImageRenderer(content: foglio)
        renderer.proposedSize = ProposedViewSize(d.formato)
        renderer.scale = Tema.Apple.Tavolo.scalaPagina
        guard let immagine = renderer.cgImage, let png = ProtocolloTavolo.png(immagine) else { return nil }
        return PaginaTavolo(numero: i + 1, totale: d.pagine.count, larghezza: Double(d.formato.width),
                            altezza: Double(d.formato.height), png: png)
    }
}
#endif
