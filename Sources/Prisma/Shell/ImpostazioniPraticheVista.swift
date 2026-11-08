import SwiftUI

// Impostazioni › Pratiche (Design/template-luce-specifica.md §7.3, D3.2, «Luce» giro 3): dopo quanti giorni senza un
// passo nuovo una pratica dopo la firma è «ferma». 7 di base; il campo non resta mai vuoto (almeno un giorno). Le
// pratiche ferme compaiono solo dentro Prisma: nel centro notifiche, gruppo «Da sistemare», e nella scheda Dopo la firma.

struct PaginaImpostazioniPratiche: View {
    @Environment(StatoShell.self) var stato

    private typealias I = ImpostazioniPratiche

    var body: some View {
        let _ = ContaCorpi.segna()
        let giorni = stato.dati.impostazioni.pratiche.giorniFerma
        return VStack(alignment: .leading, spacing: Tema.Apple.Impostazioni.Pagina.spazioGruppi) {
            NotaImpostazioni("Una pratica nasce quando una proposta viene accettata e segue i passi fino alla consegna "
                             + "al cliente. Qui scegli quando una pratica senza passi nuovi diventa «ferma».")
            VStack(alignment: .leading, spacing: Tema.Apple.Impostazioni.Riga.fraRighe) {
                GruppoImpostazioni(titolo: "Pratiche ferme") {
                    RigaImpostazione(titolo: "Ferma dopo",
                                     sottotitolo: "Oltre questi giorni senza un passo nuovo la pratica è segnata in rosso",
                                     aiuto: "I giorni si contano dall'ultimo passo fatto (o dall'apertura, se non ce n'è "
                                        + "ancora uno). Con 7 giorni una pratica diventa ferma all'ottavo.",
                                     ultima: true) {
                        Stepper(value: Binding(
                            get: { stato.dati.impostazioni.pratiche.giorniFerma },
                            set: { stato.dati.impostazioni.pratiche.giorniFerma = min(I.giorniFermaMassimi, max(I.giorniFermaMinimi, $0)) }),
                                in: I.giorniFermaMinimi...I.giorniFermaMassimi) {
                            Text(giorni == 1 ? "1 giorno" : "\(giorni) giorni")
                                .carattereApple(Tema.Apple.Carattere.corpo.tabellari)
                                .foregroundColor(Tema.Apple.Colore.inchiostro)
                        }
                        .fixedSize()
                        .disabled(stato.solaLettura)
                    }
                }
                NotaImpostazioni("Le pratiche ferme restano dentro Prisma: compaiono nel centro notifiche, fra le cose da "
                                 + "sistemare, e in Pratiche › Dopo la firma. Nessuna notifica di macOS.")
            }
            .cascataImpostazioni(1)
        }
    }
}
