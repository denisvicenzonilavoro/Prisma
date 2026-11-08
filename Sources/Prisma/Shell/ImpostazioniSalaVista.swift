import SwiftUI

// Impostazioni › Sala («Luce» giro 8, Design/template-luce-specifica.md §4.3.5 e decisioni 56, 58 e 69): ciò che le
// esperienze della Sala non possono inventare. Gli eventi di Lancia l'anno con la probabilità annua E la fonte (ISTAT,
// INAIL, INPS o altre: si scrivono qui, non si scaricano), l'importo o i mesi di reddito; gli anni della partita; le
// avvertenze della lettera, di Lancia l'anno e di «Quanto vale avermi accanto» e il titolo del valore. Finché l'utente non
// li scrive restano i segnaposto dichiarati e un evento non esce mai a caso.

struct PaginaImpostazioniSala: View {
    @Environment(StatoShell.self) var stato

    private typealias S = Tema.Apple.Impostazioni.Sala

    private static let numero = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0...2))

    var body: some View {
        let _ = ContaCorpi.segna()
        let sala = stato.dati.impostazioni.sala
        let eventi = MotoreLanciaAnno.eventi(risorsa: MotoreLanciaAnno.caricati?.eventi ?? [], utente: sala.eventiAnno)
        return VStack(alignment: .leading, spacing: Tema.Apple.Impostazioni.Pagina.spazioGruppi) {
            NotaImpostazioni("Le esperienze della Sala raccontano le cifre dei motori di Prisma. Qui scrivi ciò che Prisma "
                             + "non può inventare: le probabilità degli imprevisti con la loro fonte e i testi delle avvertenze.")
            GruppoImpostazioni(titolo: "Lancia l’anno") {
                RigaImpostazione(titolo: "Durata della partita", sottotitolo: "Quanti anni si lanciano prima della fine",
                                 ultima: true) {
                    Picker("", selection: Binding(get: { sala.anniPartita ?? -1 },
                                                  set: { v in modifica { $0.anniPartita = v < 0 ? nil : v } })) {
                        Text("12 anni").tag(-1)
                        Text("Fino alla pensione").tag(0)
                        ForEach([5, 10, 15, 20, 25, 30], id: \.self) { Text("\($0) anni").tag($0) }
                    }
                    .labelsHidden()
                    .fixedSize()
                    .disabled(stato.solaLettura)
                }
            }
            .cascataImpostazioni(1)
            GruppoImpostazioni(titolo: "Gli imprevisti") {
                ForEach(Array(eventi.enumerated()), id: \.element.id) { i, e in
                    RigaImpostazione(titolo: e.titolo, sottotitolo: sottotitolo(e),
                                     aiuto: "Un evento esce a caso solo con la probabilità annua e la fonte. Senza, si gioca a mano con «Gioca una carta».",
                                     ultima: i == eventi.count - 1) {
                        HStack(spacing: S.spazioCampi) {
                            if e.effetto == .mancatoReddito {
                                TextField("mesi", value: legame(e, \.mesiDouble), format: Self.numero)
                                    .frame(width: S.campoMesi)
                                Text("mesi")
                            } else {
                                TextField("importo", value: legame(e, \.importo, azzeraProva: true), format: Self.numero)
                                    .frame(width: S.campoImporto)
                                Text("€")
                            }
                            TextField("%", value: legame(e, \.probabilitaPercento), format: Self.numero)
                                .frame(width: S.campoProbabilita)
                            Text("% l’anno")
                            TextField("fonte", text: legameTesto(e))
                                .frame(width: S.campoFonte)
                        }
                        .textFieldStyle(.roundedBorder)
                        .carattereApple(S.carattereCampi)
                        .disabled(stato.solaLettura)
                    }
                }
            }
            .cascataImpostazioni(2)
            NotaImpostazioni("I titoli degli imprevisti sono testi di prova (Risorse/Sala/eventi-anno.json). Le cifre del "
                             + "template valgono solo con i clienti di prova. Prisma non scarica tabelle: l’unica rete è Mercato.")
            GruppoImpostazioni(titolo: "Avvertenze e testi") {
                riga("La lettera dal futuro", \.avvertenzaLettera, segnaposto: ImpostazioniSala.segnapostoAvvertenza)
                riga("Lancia l’anno", \.avvertenzaLancia, segnaposto: ImpostazioniSala.segnapostoAvvertenza)
                riga("Quanto vale avermi accanto", \.avvertenzaValore, segnaposto: ImpostazioniSala.segnapostoAvvertenza)
                riga("Titolo del valore ({valore}, {periodo})", \.titoloValore, segnaposto: ImpostazioniSala.titoloValoreDiProva,
                     ultima: true)
            }
            .cascataImpostazioni(3)
            NotaImpostazioni("Le avvertenze e il titolo sono comunicazioni al cliente: scrivile o approvale tu (OCF per "
                             + "l’indipendente, Alleanza per l’agenzia). Finché restano vuote si vede il segnaposto dichiarato.")
        }
    }

    private func sottotitolo(_ e: EventoAnno) -> String {
        var r = e.effetto.nome
        if let rischio = e.rischio { r += " · coperto da: \(rischio.nome.lowercased())" }
        r += e.esceACaso ? " · esce a caso" : " · solo a mano"
        return r
    }

    private func riga(_ titolo: String, _ campo: WritableKeyPath<ImpostazioniSala, String?>, segnaposto: String,
                      ultima: Bool = false) -> some View {
        RigaImpostazione(titolo: titolo, ultima: ultima) {
            TextField(segnaposto, text: Binding(
                get: { stato.dati.impostazioni.sala[keyPath: campo] ?? "" },
                set: { v in
                    let t = v.trimmingCharacters(in: .whitespacesAndNewlines)
                    modifica { $0[keyPath: campo] = t.isEmpty ? nil : v }
                }))
                .textFieldStyle(.roundedBorder)
                .frame(width: S.campoTesto)
                .disabled(stato.solaLettura)
        }
    }

    private func modifica(_ cambia: (inout ImpostazioniSala) -> Void) {
        guard !stato.solaLettura else { return }
        var s = stato.dati.impostazioni.sala
        cambia(&s)
        stato.dati.impostazioni.sala = s
    }

    /// Cambia un evento: la voce dell'utente con lo stesso id (copiata dalla risorsa la prima volta). La cifra di prova
    /// del template si toglie solo quando l'utente scrive l'importo (`azzeraProva`), non per la fonte o la probabilità.
    private func cambiaEvento(_ e: EventoAnno, azzeraProva: Bool = false, _ cambia: (inout EventoAnno) -> Void) {
        modifica { s in
            var x = s.eventiAnno.first { $0.id == e.id } ?? e
            cambia(&x)
            if azzeraProva { x.importoDiProva = nil }
            s.eventiAnno.removeAll { $0.id == e.id }
            s.eventiAnno.append(x)
        }
    }

    private func legame(_ e: EventoAnno, _ campo: WritableKeyPath<EventoAnno, Double?>, azzeraProva: Bool = false) -> Binding<Double?> {
        Binding(get: { e[keyPath: campo] }, set: { v in
            cambiaEvento(e, azzeraProva: azzeraProva) { $0[keyPath: campo] = v.flatMap { $0 >= 0 ? $0 : nil } }
        })
    }

    private func legameTesto(_ e: EventoAnno) -> Binding<String> {
        Binding(get: { e.fonte ?? "" }, set: { v in
            cambiaEvento(e) { $0.fonte = v.trimmingCharacters(in: .whitespaces).isEmpty ? nil : v }
        })
    }
}

private extension EventoAnno {
    /// La probabilità in percentuale per il campo (0…100).
    var probabilitaPercento: Double? {
        get { probabilita.map { $0 * 100 } }
        set { probabilita = newValue.flatMap { $0 > 0 && $0 <= 100 ? $0 / 100 : nil } }
    }

    var mesiDouble: Double? {
        get { mesi.map(Double.init) }
        set { mesi = newValue.flatMap { $0 >= 1 ? Int($0) : nil } }
    }
}
