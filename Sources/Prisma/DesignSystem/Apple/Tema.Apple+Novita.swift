import SwiftUI

// Gettoni della parte comune di «Orizzonte» (Design/template-novita-specifica.md §1, §2.1, §2.2, §3.1):
// la pillola «✦ Novità» della barra, il pannello «Le novità» e i suoi movimenti (la schermata sobria delle app «in
// arrivo» non c'è più: dal giro 7 anche Mercato è un'app vera, Tema.Apple+Mercato.swift). Misure in pt del palco 1440×900.

// MARK: - Pillola «✦ Novità» (§2.1)

extension Tema.Apple.BarraAlta {
    /// Fra «✦ Novità» e la pastiglia con il numero (`gap: 7`).
    static let spazioNovita: CGFloat = 7
    /// Il testo della pillola è blu accento (sia in chiaro sia in scuro), non nell'inchiostro sopra l'acqua.
    static let testoNovita = Tema.Apple.Colore.accento
    /// La pastiglia: fondo accento, cifra bianca 10 semibold, padding 1×6, a capsula.
    static let fondoPastigliaNovita = Tema.Apple.Colore.accento
    static let paddingPastigliaNovita = EdgeInsets(top: 1, leading: 6, bottom: 1, trailing: 6)
    static let pastigliaNovita = Tema.Apple.Carattere(dimensione: 10, peso: .semibold, tabellare: true)
}

// MARK: - Pannello «Le novità» (§2.2)

extension Tema.Apple {
    enum Novita {
        /// Vetro centrato sotto la barra: largo 540, a 40 dall'alto, alto quanto il contenuto e al massimo 820,
        /// poi scorre. Raggio 24, padding 16.
        static let larghezza: CGFloat = 540
        static let dallAlto: CGFloat = 40
        static let altezzaMassima: CGFloat = 820
        /// Quanto resta libero sotto il pannello quando la finestra è bassa.
        static let basso: CGFloat = 16
        /// Margine ai lati quando la finestra è più stretta del pannello.
        static let bordo: CGFloat = 16
        static let raggio: CGFloat = 24
        static let padding: CGFloat = 16
        /// Testata: «✦ Le novità» 16 bold e «11 funzioni da provare» (`.k`), 6 sopra le voci.
        static let spazioTestata: CGFloat = 6
        static let titolo = Carattere(dimensione: 16, peso: .bold)
        static let conteggio = Carattere.secondario
        /// Voce `.novI`: padding 9×10, raggio 14, 12 fra pallino, testi e freccia; passo fra le voci circa 53.
        static let paddingVoce = EdgeInsets(top: 9, leading: 10, bottom: 9, trailing: 10)
        static let raggioVoce: CGFloat = Raggio.voce
        static let spazioVoce: CGFloat = 12
        static let spazioVoci: CGFloat = 2
        static let titoloVoce = Carattere(dimensione: 14, peso: .bold)
        static let fraseVoce = Carattere.secondario
        /// Il pallino numerato `.novN`: 26, sfumato a 135° da #5AC8FA a #8B5CF6, cifra bianca 12 bold.
        static let numero: CGFloat = 26
        static let numeroDa = Colore.Composizione.obbligazionario
        static let numeroA = Colore.anello3
        static let cifra = Carattere(dimensione: 12, peso: .bold, tabellare: true)
        static let testoNumero = BarraAlta.testoSuColore
        /// La freccia «›» blu accento, bold.
        static let freccia = Carattere(dimensione: 16, peso: .bold)
        static let coloreFreccia = Colore.accento
        /// Fondo della voce sotto il puntatore (`--chip`).
        static let fondoPassaggio = Colore.chip
    }
}

extension Tema.Apple.Novita {
    /// Il gradiente del pallino numerato (135°: dall'alto a sinistra al basso a destra).
    static var gradienteNumero: LinearGradient {
        LinearGradient(colors: [numeroDa, numeroA], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Movimento del pannello (§3.1)

extension Tema.Apple.Moto {
    /// Il pannello che si apre: come quello delle notifiche (da y −10, scala 0,97, molla in 0,38 s).
    /// Si chiude subito, senza animazione. Si apre da solo 1,7 s dopo il primo sblocco dopo l'aggiornamento.
    enum PannelloNovita {
        static let durata = PannelloNotifiche.durata
        static let spostamento: CGFloat = PannelloNotifiche.spostamento
        static let scala: CGFloat = PannelloNotifiche.scala
        static var animazione: Animation { Curva.molla.animazione(durata) }
        static let ripiego = PannelloNotifiche.ripiego
        static let aperturaAutomatica = 1.7
    }

    /// Le voci a cascata: da x +16, 0,38 s con `uscita`, ritardo 0,06 + i·0,035. Passaggio del puntatore in 0,2 s.
    enum VoceNovita {
        static let durata = 0.38
        static let spostamento: CGFloat = 16
        static let ritardoBase = 0.06
        static let passo = 0.035
        static var animazione: Animation { Curva.uscita.animazione(durata) }
        static func ritardo(indice: Int) -> Double { ritardoBase + Double(indice) * passo }
        static let durataPassaggio = 0.2
        static var passaggio: Animation { Curva.ease.animazione(durataPassaggio) }
    }
}

extension Tema.Apple.Moto.StileEntrata {
    /// Voci del pannello Novità: da x +16, in 0,38 s, senza sfocatura.
    static let voceNovita = Tema.Apple.Moto.StileEntrata(durata: Tema.Apple.Moto.VoceNovita.durata,
                                                         curva: Tema.Apple.Moto.Curva.uscita,
                                                         spostamentoX: Tema.Apple.Moto.VoceNovita.spostamento,
                                                         spostamentoY: 0, scala: 1, sfocatura: 0)
}
