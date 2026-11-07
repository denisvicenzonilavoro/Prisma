import SwiftUI

/// Prova del tema Apple dentro `Prisma --prova-calcoli` (chiamata da `ProvaCalcoli.esegui()`): nello stato finale
/// (istantanee o «Riduci movimento») i componenti si disegnano subito completi. Si verifica senza interfaccia
/// la parte di calcolo che lo decide: il testo di `NumeroCheConta` prima del conteggio, gli aiuti di
/// `Tema.Apple.Moto` (niente ritardi né animazioni in istantanea) e le curve che arrivano a 1.
enum ProvaStatoFinaleApple {
    private typealias MotoApple = Tema.Apple.Moto

    static func esegui(_ verifica: VerificaCalcoli) {
        // NumeroCheConta: in istantanea e con calma il numero mostrato è il valore finale, non il punto di partenza
        verifica.vero("Tema Apple: numero in istantanea al valore finale (euro)",
                      FormatoCifra.euro.testoFermo(318_400, da: 0, statoFinale: true) == FormatoCifra.euro.testo(318_400))
        verifica.vero("Tema Apple: numero in istantanea al valore finale (percentuale)",
                      FormatoCifra.percentuale.testoFermo(48, da: 0, statoFinale: true) == "48%")
        verifica.vero("Tema Apple: numero in istantanea al valore finale (mesi)",
                      FormatoCifra.mesi.testoFermo(4.5, da: 0, statoFinale: true) == "4,5")
        verifica.vero("Tema Apple: numero animato parte da «da»",
                      FormatoCifra.intero.testoFermo(7_650, da: 0, statoFinale: false) == "0")
        verifica.vero("Tema Apple: numero senza conteggio all'apparire (da nil) già al valore",
                      FormatoCifra.intero.testoFermo(7_650, da: nil, statoFinale: false) == "7.650")
        verifica.vero("Tema Apple: euro con il punto anche a quattro cifre",
                      FormatoCifra.euro.testo(7_650) == "7.650\u{00A0}€")
        verifica.vero("Tema Apple: negativo con il meno tipografico",
                      FormatoCifra.intero.testo(-1_200) == Formati.meno + "1.200")

        // Il conteggio e le curve arrivano esattamente al valore finale
        verifica("Tema Apple: quartica a t = 1", MotoApple.Curva.quartica(1), 1, tolleranza: 1e-12)
        verifica("Tema Apple: quartica oltre t = 1 resta 1", MotoApple.Curva.quartica(1.4), 1, tolleranza: 1e-12)
        verifica("Tema Apple: quartica a t = 0", MotoApple.Curva.quartica(0), 0, tolleranza: 1e-12)
        verifica("Tema Apple: curva «uscita» a t = 1", MotoApple.Curva.uscita.valore(1), 1, tolleranza: 1e-6)

        // Aiuti di movimento: in istantanea nessun ritardo e nessuna animazione, stato finale sempre
        verifica.vero("Tema Apple: stato finale in istantanea", MotoApple.statoFinale(calmo: false, istantanea: true))
        verifica.vero("Tema Apple: stato finale con calma", MotoApple.statoFinale(calmo: true, istantanea: false))
        verifica.vero("Tema Apple: niente stato finale nell'uso normale", !MotoApple.statoFinale(calmo: false, istantanea: false))
        // Le istantanee di iPhone e iPad (schermo vero, `istantaneaSchermo`): stato finale senza `modoIstantanea`
        var ambienteSchermo = EnvironmentValues()
        ambienteSchermo.istantaneaSchermo = true
        verifica.vero("Tema Apple: stato finale nelle istantanee dello schermo (iPhone e iPad)", ambienteSchermo.prismaStatoFinale)
        verifica.vero("Tema Apple: niente stato finale in un ambiente nuovo", !EnvironmentValues().prismaStatoFinale)
        verifica("Tema Apple: ritardo della cascata in istantanea",
                 MotoApple.ritardo(MotoApple.Cascata.ritardo(indice: 5, base: MotoApple.Cascata.baseFinestra), calmo: false, istantanea: true), 0)
        verifica("Tema Apple: ritardo dell'anello con calma",
                 MotoApple.ritardo(MotoApple.Anello.ritardo(indice: 2, base: MotoApple.Anello.ritardoFinestra), calmo: true), 0)
        verifica.vero("Tema Apple: nessuna animazione in istantanea",
                      MotoApple.animazione(MotoApple.Cascata.animazione, calmo: false, istantanea: true) == nil)
        verifica("Tema Apple: dissolvenza calma di 0,15 s", MotoApple.durataCalma, 0.15, tolleranza: 1e-9)

        // Vera (§2.18-2.20): la sfera respira fino a 1,045 a metà ciclo e pulsa fino a 1,1; i puntini salgono al 30%
        // e al 60% sono di nuovo spenti; il testo si divide in parole tenendo spazi e a capo di Qwen
        let metaRespiro = Date(timeIntervalSinceReferenceDate: MotoApple.Sfera.respiro / 2)
        verifica("Tema Apple: sfera di Vera a metà del respiro",
                 Double(SferaVera.fase(al: metaRespiro, viva: true, pensa: false, inizioPensa: nil).scala),
                 Double(MotoApple.Sfera.scalaRespiro), tolleranza: 1e-9)
        verifica("Tema Apple: sfera di Vera a metà della pulsazione",
                 Double(SferaVera.fase(al: metaRespiro.addingTimeInterval(MotoApple.Sfera.pensa / 2), viva: true, pensa: true,
                                      inizioPensa: metaRespiro).scala),
                 Double(MotoApple.Sfera.scalaPensa), tolleranza: 1e-9)
        verifica.vero("Tema Apple: sfera di Vera ferma a riposo", SferaVera.Fase.riposo.scala == 1 && SferaVera.Fase.riposo.angolo == 0)
        let picco = PuntiniScrittura.picco(MotoApple.Puntini.ciclo * MotoApple.Puntini.picco)
        verifica("Tema Apple: puntino in alto al 30% del ciclo", picco.salita, 1, tolleranza: 1e-9)
        verifica("Tema Apple: puntino spento dopo il 60% del ciclo", PuntiniScrittura.picco(MotoApple.Puntini.ciclo * 0.8).luce, 0)
        let frase = "Ciao  Giulia,\nla casa è al 52%."
        let fini = TestoProgressivo.fini(frase)
        verifica.vero("Tema Apple: testo di Vera diviso in parole", fini.count == 7)
        verifica.vero("Tema Apple: testo di Vera fino alla seconda parola, con gli spazi di Qwen",
                      TestoProgressivo.prefisso(frase, fini: fini, parole: 2) == "Ciao  Giulia,")
        verifica.vero("Tema Apple: testo di Vera completo all'ultima parola",
                      TestoProgressivo.prefisso(frase, fini: fini, parole: fini.count) == frase
                          && TestoProgressivo.prefisso(frase, fini: fini, parole: 0).isEmpty)
    }
}
