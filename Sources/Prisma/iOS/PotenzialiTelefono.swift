#if os(iOS)
import SwiftUI

/// I potenziali clienti sull'iPhone («Luce» giro 12, §9.2.4 «iPhone/iPad»), in sola lettura e nella gerarchia approvata
/// (Design/iphone.html): una cosa grande in alto (quanti sono e il probabile entro fine anno, MotorePassaparola), poi
/// l'elenco per fase. Le schede si spostano dal Mac.
struct PotenzialiTelefono: View {
    @Environment(StatoShell.self) var stato

    private typealias E = Tema.Apple.Telefono.Elenco
    private typealias P = Tema.Apple.Potenziali

    var body: some View {
        let _ = ContaCorpi.segna()
        let oggi = Date()
        let potenziali = stato.dati.potenziali
        let totali = MotorePassaparola.totali(potenziali, clienti: stato.dati.clienti, oggi: oggi)
        let colonne = MotorePassaparola.percorso(potenziali, oggi: oggi)
        FondoTelefono {
            VStack(alignment: .leading, spacing: E.spazioTesto) {
                Text("\(totali.conteggio) potenziali")
                    .carattereApple(Tema.Apple.Carattere.valore)
                    .foregroundColor(E.coloreNome)
                NumeroCheConta(totali.probabileEntroAnno, formato: .euro)
                    .carattereApple(P.tileValore)
                    .foregroundColor(E.coloreNome)
                Text(TestiPassaparola.tileProbabile.lowercased()
                     + (totali.esclusiDalProbabile > 0 ? " · " + TestiPassaparola.esclusi(totali.esclusiDalProbabile) : ""))
                    .carattereApple(E.dettaglio)
                    .foregroundColor(E.coloreDettaglio)
            }
            .schedaTelefono()
            if potenziali.isEmpty {
                VuotoTelefono(testo: TestiPassaparola.vuoto)
            }
            ForEach(FasePotenziale.colonne) { fase in
                let elenco = colonne[fase] ?? []
                if !elenco.isEmpty {
                    SezioneTelefono(titolo: fase.titolo.uppercased() + " · \(elenco.count)")
                    ForEach(elenco) { p in
                        VStack(alignment: .leading, spacing: E.spazioTesto) {
                            Text(p.nome).carattereApple(E.nome).foregroundColor(E.coloreNome).lineLimit(1)
                            Text([TestiPassaparola.fonte(p, clienti: stato.dati.clienti), TestiPassaparola.stima(p.patrimonioStimato),
                                  TestiPassaparola.probabilita(p.probabilita)].compactMap { $0 }.joined(separator: " · "))
                                .carattereApple(E.dettaglio).foregroundColor(E.coloreDettaglio).lineLimit(2)
                            if p.informativaIl == nil && p.fase != .cliente {
                                Text(TestiPassaparola.informativaDaDare).carattereApple(P.segno).foregroundColor(P.coloreSegno)
                            }
                        }
                        .schedaTelefono()
                    }
                }
            }
            Text(TestiPassaparola.notaPercorsoSolaLettura)
                .carattereApple(E.dettaglio)
                .foregroundColor(E.coloreDettaglio)
                .fixedSize(horizontal: false, vertical: true)
        }
        .navigationTitle("Potenziali")
    }
}
#endif
