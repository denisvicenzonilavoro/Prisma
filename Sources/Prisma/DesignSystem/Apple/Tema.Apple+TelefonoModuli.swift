import SwiftUI

// MARK: - I moduli dell'iPhone (iOS/ModuliTelefono.swift, 13 novembre 2026)
// Agenda e attività si scrivono anche dall'iPhone: nuovo appuntamento, nuova attività, modifica, spunta, elimina.
// Fogli di sistema con i caratteri e i colori del tema Apple; qui le scelte proposte e le misure.

extension Tema.Apple.Telefono {
    enum Moduli {
        /// Le durate proposte per un appuntamento (minuti).
        static let durate = [30, 45, 60, 90, 120]
        static let durataPredefinita = 60
        /// Un appuntamento nuovo con un cliente non comincia prima delle 9:30 (la regola dell'agenda che si organizza).
        static let oraPredefinita = 9
        static let minutoPredefinito = 30
        /// Il passo dei minuti quando l'appuntamento è oggi e l'ora proposta è già passata.
        static let passoMinuti = 30
        /// La spunta di un'attività: il cerchio del tema dentro un'area di tocco per il dito.
        static let toccoSpunta: CGFloat = Tema.Apple.Telefono.tocco
        /// Il movimento della spunta.
        static let spunta = Animation.easeOut(duration: Tema.Apple.Moto.tempo(0.25))
        /// I pulsanti delle azioni nel dettaglio (Modifica, Segna concluso, Elimina).
        static let spazioAzioni: CGFloat = 10
        static let altezzaAzione: CGFloat = 44
    }
}
