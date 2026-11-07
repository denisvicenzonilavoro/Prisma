import SwiftUI

// Gettoni della sintesi di Analisi 360 › Protezione (Shell/Analisi360Protezione.swift): la cifra principale
// dello scoperto, le coperture con il canale, le caselle dei rischi del nucleo, le schede compatte persona per
// persona e le parti richiudibili (fisco, metodo). Solo alias dei colori e dei caratteri del tema: funzionano
// in chiaro e in scuro. I grafici (barra di copertura, cascata, tessere) sono quelli di GraficiAnalisi.swift.

extension Tema.Colore {
    enum Analisi360Protezione {
        /// Colore dell'area protezione: il coperto nella barra e il simbolo delle coperture.
        static let area = Colori.Analisi.area(.protezione)
        /// Occhiello e nota della cifra principale.
        static let occhiello = Colori.Strumenti.risultatoNota
        static let nota = Colori.Strumenti.risultatoNota
        /// Righe delle coperture: nome, dettaglio, filo tra una riga e l'altra.
        static let nome = Tema.Colore.inchiostro
        static let dettaglio = Tema.Colore.inchiostroSecondario
        static let filo = Tema.Colore.separatore
        /// Caselle dei rischi del nucleo: coperto, in proposta, scoperto (da avere), da valutare.
        static let copertoTesto = Colori.Strumenti.rischioPresenteTesto
        static let copertoFondo = Colori.Strumenti.rischioPresenteFondo
        static let copertoBordo = Colori.Strumenti.rischioPresenteBordo
        static let propostaTesto = Tema.Colore.GraficiAnalisi.attenzione
        static let propostaFondo = Tema.Colore.GraficiAnalisi.tintaAttenzione
        static let scopertoTesto = Tema.Colore.GraficiAnalisi.negativo
        static let scopertoFondo = Tema.Colore.GraficiAnalisi.tintaNegativo
        static let valutareTesto = Colori.Strumenti.rischioAssenteTesto
        static let valutareFondo = Colori.Strumenti.rischioAssenteFondo
        static let valutareBordo = Colori.Strumenti.rischioAssenteBordo
        /// Bordo delle caselle in proposta e scoperte: il colore del testo, leggero.
        static let opacitaBordo: Double = 0.35
        /// Intestazione di una persona.
        static let persona = Tema.Colore.inchiostro
        static let personaDettaglio = Tema.Colore.inchiostroSecondario
        /// Collegamento che apre le parti richiudibili.
        static let apri = Tema.Colore.MotoriAnalisi.apriIpotesi
    }
}

extension Tema.Misura {
    enum Analisi360Protezione {
        /// Spazio tra le parti della sintesi e dentro la cifra principale.
        static let spazioSezioni: CGFloat = 16
        static let spazioCifra: CGFloat = 4
        /// Spazio tra le due cifre principali affiancate (caso morte e invalidità).
        static let spazioCifre: CGFloat = 28
        /// La cifra grande si rimpicciolisce al massimo fino a questa scala, mai troncata.
        static let scalaMinimaCifra: CGFloat = 0.5
        /// Righe delle coperture: margini e spazio tra nome, dettaglio, pillola e canale.
        static let rigaCopertura = EdgeInsets(top: 7, leading: 0, bottom: 7, trailing: 0)
        static let spazioRiga: CGFloat = 8
        static let spazioTesti: CGFloat = 1
        static let simbolo: CGFloat = 16
        /// Caselle dei rischi: larghezza minima, spazio, margini, raggio, spazio tra simbolo e nome.
        static let casellaMinima: CGFloat = 150
        static let spazioCaselle: CGFloat = 6
        static let margineCasella = EdgeInsets(top: 6, leading: 9, bottom: 6, trailing: 9)
        static let raggioCasella = Tema.Raggio.Strumenti.casellaRischio
        static let spazioSimbolo: CGFloat = 6
        /// Schede persona per persona: spazio tra le persone e dentro una scheda.
        static let spazioPersone: CGFloat = 18
        static let spazioPersona: CGFloat = 8
        /// Collegamento che apre una parte richiudibile.
        static let spazioApri: CGFloat = 4
    }
}

extension Tema.Testo {
    enum Analisi360Protezione {
        /// La cifra principale: occhiello in maiuscolo, cifra grande, nota breve (come il TFR).
        static let occhiello = Tipo.risultatoOcchiello
        static let tracciatoOcchiello: CGFloat = 1.2
        static let cifra = Tipo.risultatoGrande
        static let nota = Tipo.risultatoNota
        /// Righe delle coperture.
        static let nome = Tema.Testo.corpo
        static let dettaglio = Tema.Testo.didascalia
        /// Caselle dei rischi: nome e simbolo.
        static let casella = Tipo.chip
        static let simboloCasella = Tema.Testo.sf(11, .semibold)
        /// Intestazione di una persona.
        static let persona = Tema.Testo.MotoriAnalisi.persona
        static let personaDettaglio = Tema.Testo.secondario
        /// Collegamento che apre una parte richiudibile.
        static let apri = Tema.Testo.didascalia
        static let freccia = Tema.Testo.MotoriAnalisi.freccia
    }
}
