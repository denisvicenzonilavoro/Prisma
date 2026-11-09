import Foundation

/// **Dati di prova** (dichiarati): la carta d'identità fac-simile «Elena Marchi» del template della specifica (§9.1.1),
/// con la scritta «FAC-SIMILE» e il numero «CA00000AA», palesemente finto. Serve alla scena disegnata, alle istantanee e
/// alle prove: mai un documento vero (il repository è pubblico). Le righe hanno i riquadri del disegno
/// (`CartaIdentitaDisegnata`), in coordinate 0…1 con l'origine in alto a sinistra, come le dà `LetturaDocumenti`.
/// La zona ottica del retro (TD1) è calcolata con le cifre di controllo giuste (4, 4, 5 e la composita 2).
/// `DatiDemo` e `ClientiFittizi` non la usano: la carta arriva dal telefono e si decide, non sta nei dati dell'app.
enum CartaIdentitaFacSimile {
    static let nota = "FAC-SIMILE · dati di prova del template"

    static let cognome = "MARCHI"
    static let nome = "ELENA"
    static let nascita = "03.04.1990"
    static let luogo = "BOLOGNA (BO)"
    static let scadenza = "03.04.2031"
    static let codiceFiscale = "MRCLNE90D43A944S"
    /// Il telefono che «manda» la carta nelle istantanee.
    static let dispositivo = "iPhone di prova"
    /// La zona ottica come la disegna il template (decorativa, troppo corta per essere letta).
    static let zonaDisegnata = ["C<ITACA00000AA0<<<<<<", "MARCHI<<ELENA<<<<<<<<"]

    /// La zona ottica TD1 vera del retro (tre righe da 30), con le cifre di controllo giuste.
    static let zonaRetro = [
        "C<ITACA00000AA4<<<<<<<<<<<<<<<",
        "9004034F3104035ITA<<<<<<<<<<<2",
        "MARCHI<<ELENA<<<<<<<<<<<<<<<<<",
    ]

    /// I riquadri del disegno: etichetta sopra, valore sotto, nella colonna a destra della foto.
    static func riquadroEtichetta(_ n: Int) -> RiquadroPagina {
        RiquadroPagina(x: 0.34, y: 0.16 + Double(n) * 0.11, larghezza: 0.40, altezza: 0.035)
    }

    static func riquadroValore(_ n: Int) -> RiquadroPagina {
        RiquadroPagina(x: 0.34, y: 0.195 + Double(n) * 0.11, larghezza: 0.40, altezza: 0.06)
    }

    static let riquadroEtichettaFiscale = RiquadroPagina(x: 0.05, y: 0.74, larghezza: 0.55, altezza: 0.035)
    static let riquadroFiscale = RiquadroPagina(x: 0.05, y: 0.775, larghezza: 0.55, altezza: 0.06)

    /// Il fronte del fac-simile, con i cinque campi e il codice fiscale.
    static func righe() -> [RigaLetta] {
        var r: [RigaLetta] = [
            RigaLetta(testo: "CARTA D'IDENTITÀ", riquadro: RiquadroPagina(x: 0.05, y: 0.04, larghezza: 0.45, altezza: 0.05)),
            RigaLetta(testo: "FAC-SIMILE", riquadro: RiquadroPagina(x: 0.72, y: 0.045, larghezza: 0.23, altezza: 0.04)),
        ]
        let campi: [(String, String)] = [("COGNOME", cognome), ("NOME", nome), ("NATA IL", nascita), ("A", luogo), ("SCADENZA", scadenza)]
        for (n, campo) in campi.enumerated() {
            r.append(RigaLetta(testo: campo.0, riquadro: riquadroEtichetta(n)))
            r.append(RigaLetta(testo: campo.1, riquadro: riquadroValore(n)))
        }
        r.append(RigaLetta(testo: "CODICE FISCALE", riquadro: riquadroEtichettaFiscale))
        r.append(RigaLetta(testo: codiceFiscale, riquadro: riquadroFiscale))
        return r
    }

    /// Il retro: la sola zona a lettura ottica TD1.
    static func righeRetro() -> [RigaLetta] {
        zonaRetro.enumerated().map { n, testo in
            RigaLetta(testo: testo, riquadro: RiquadroPagina(x: 0.05, y: 0.70 + Double(n) * 0.08, larghezza: 0.9, altezza: 0.06))
        }
    }

    /// Una lettura parziale: la scadenza e il luogo coperti da un riflesso, il codice fiscale che non torna con la data
    /// (il mese è «E», maggio, con il suo carattere di controllo giusto).
    static func righeParziali() -> [RigaLetta] {
        let sbagliato = "MRCLNE90E43A944" + String(CodiceFiscale.carattereDiControllo("MRCLNE90E43A944") ?? "X")
        return righe().filter { riga in
            ![scadenza, "SCADENZA", luogo, "A"].contains(riga.testo)
        }.map { riga in
            riga.testo == codiceFiscale ? RigaLetta(testo: sbagliato, riquadro: riga.riquadro) : riga
        }
    }

    /// I campi della carta che il disegno accende, per ogni campo letto.
    static let campiDisegnati: [CampoCarta] = [.cognome, .nome, .dataNascita, .luogoNascita, .scadenza, .codiceFiscale]
}
