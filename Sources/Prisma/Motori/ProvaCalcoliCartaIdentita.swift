import Foundation

/// Prove di «Nuovo cliente in 10 secondi» (Design/template-luce-specifica.md §9.1, «Luce» giro 13), solo su dati di prova
/// dichiarati (la carta fac-simile «Elena Marchi» del template, numero «CA00000AA» palesemente finto): codice fiscale
/// (carattere di controllo, omocodie, coerenza con cognome, nome, data e sesso, comune mai controllato), zona a lettura
/// ottica con le cifre di controllo 7-3-1, fronte con le etichette, campi mancanti mai inventati, fronte e retro, documento
/// scaduto, doppioni, limiti della busta del ponte e creazione del cliente. Chiamata da `ProvaCalcoli.esegui()`.
enum ProvaCalcoliCartaIdentita {
    static func esegui(_ verifica: VerificaCalcoli) {
        codiceFiscale(verifica)
        zonaOttica(verifica)
        fronte(verifica)
        doppioni(verifica)
        creazione(verifica)
        potenziale(verifica)
    }

    /// Una data di nascita come le scrive la carta: giorno a mezzanotte nel calendario gregoriano.
    static func giorno(_ anno: Int, _ mese: Int, _ g: Int) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: anno, month: mese, day: g)) ?? Date()
    }

    // MARK: - Punti 1-4: il codice fiscale

    private static func codiceFiscale(_ verifica: VerificaCalcoli) {
        let cf = "MRCLNE90D43A944S"
        verifica.vero("Carta: il carattere di controllo di «MRCLNE90D43A944» è S",
                      CodiceFiscale.carattereDiControllo("MRCLNE90D43A944") == "S" && CodiceFiscale.carattereDiControlloValido(cf))
        let nascita = giorno(1990, 4, 3)
        verifica.vero("Carta: con l'ultima lettera cambiata il codice non ha la forma valida",
                      CodiceFiscale.coerenza("MRCLNE90D43A944T", cognome: "Marchi", nome: "Elena", nascita: nascita, sesso: .femmina) == .formaNonValida)
        // Omocodia: il 4 del comune diventa Q, il controllo ricalcolato è P
        let omocodia = "MRCLNE90D43A94QP"
        verifica.vero("Carta: l'omocodia «MRCLNE90D43A94QP» è valida e torna «MRCLNE90D43A944»",
                      CodiceFiscale.carattereDiControlloValido(omocodia) && CodiceFiscale.formaValida(omocodia)
                        && CodiceFiscale.senzaOmocodia(omocodia).prefix(15) == "MRCLNE90D43A944")
        let esito = CodiceFiscale.coerenza(cf, cognome: "Marchi", nome: "Elena", nascita: nascita, sesso: .femmina)
        verifica.vero("Carta: il codice del fac-simile è coerente, comune non controllato (decisione 70)",
                      esito == .coerenteSenzaComune && esito.testo == "✓ coerente (comune non controllato)" && !CodiceFiscale.comuneControllato)
        verifica.vero("Carta: anche minuscolo e con gli spazi il codice si legge uguale",
                      CodiceFiscale.coerenza("mrcl ne90d43a944s", cognome: "MARCHI", nome: "ELENA", nascita: nascita, sesso: .femmina) == .coerenteSenzaComune)
        verifica.vero("Carta: con l'omocodia la coerenza resta (senza comune)",
                      CodiceFiscale.coerenza(omocodia, cognome: "Marchi", nome: "Elena", nascita: nascita, sesso: .femmina) == .coerenteSenzaComune)
        let meseSbagliato = CodiceFiscale.coerenza(cf, cognome: "Marchi", nome: "Elena", nascita: giorno(1990, 5, 3), sesso: .femmina)
        verifica.vero("Carta: con il mese sbagliato «non torna con la data di nascita: controllalo»",
                      meseSbagliato == .diverso([.mese]) && meseSbagliato.testo == "non torna con la data di nascita: controllalo" && meseSbagliato.daGuardare)
        verifica.vero("Carta: un maschio con il giorno 43 non torna con il sesso",
                      CodiceFiscale.coerenza(cf, cognome: "Marchi", nome: "Elena", nascita: nascita, sesso: .maschio) == .diverso([.sesso]))
        verifica.vero("Carta: il sesso si legge dal giorno (43 = femmina)", CodiceFiscale.sesso(cf) == .femmina)
        verifica.vero("Carta: senza la data di nascita il codice non si può confrontare",
                      CodiceFiscale.coerenza(cf, cognome: "Marchi", nome: "Elena", nascita: nil, sesso: nil) == .nonVerificabile)
        verifica.vero("Carta: «Elena» → «LNE» (due consonanti e una vocale)", CodiceFiscale.lettereNome("Elena") == "LNE")
        verifica.vero("Carta: «Gianfranco» → «GFR» (1ª, 3ª e 4ª consonante)", CodiceFiscale.lettereNome("Gianfranco") == "GFR")
        verifica.vero("Carta: «Fo» → «FOX» (cognome corto)", CodiceFiscale.lettereCognome("Fo") == "FOX")
        verifica.vero("Carta: «D'Angelo» → «DNG» (senza apostrofi né accenti)", CodiceFiscale.lettereCognome("D'Angelo") == "DNG")
        let nascitaLetta = CodiceFiscale.nascita(cf) { aa in aa > 30 ? 1900 : 2000 }
        verifica.vero("Carta: la data scritta nel codice è il 3 aprile 1990",
                      nascitaLetta?.year == 1990 && nascitaLetta?.month == 4 && nascitaLetta?.day == 3)
    }

    // MARK: - Punti 5-6: la zona a lettura ottica

    private static func zonaOttica(_ verifica: VerificaCalcoli) {
        verifica.vero("Carta: cifre di controllo 7-3-1 (CA00000AA → 4, 900403 → 4, 310403 → 5)",
                      MotoreCartaIdentita.cifraDiControllo("CA00000AA") == 4 && MotoreCartaIdentita.cifraDiControllo("900403") == 4
                        && MotoreCartaIdentita.cifraDiControllo("310403") == 5)
        let z = MotoreCartaIdentita.leggi(CartaIdentitaFacSimile.righeRetro())
        let tutti: [CampoCarta] = [.numero, .dataNascita, .sesso, .scadenza, .cittadinanza, .cognome, .nome]
        verifica.vero("Carta: la zona TD1 dà numero, nascita, sesso, scadenza, cittadinanza, cognome e nome, tutti dalla zona",
                      z.conZonaOttica && z.tipo == .cartaIdentita && tutti.allSatisfy { z[$0]?.fonte == .zonaOttica && z[$0]?.daGuardare == false })
        verifica.vero("Carta: dalla zona «CA00000AA», 3/4/1990, F, 3/4/2031, ITA, Marchi Elena",
                      z.numero == "CA00000AA" && z.dataNascita == giorno(1990, 4, 3) && z.sessoLetto == .femmina
                        && z.scadenza == giorno(2031, 4, 3) && z[.cittadinanza]?.valore == "ITA" && z.cittadinanza == "Italiana"
                        && z.nomeCompleto == "Elena Marchi")
        var sbagliata = CartaIdentitaFacSimile.zonaRetro
        sbagliata[1] = "9004035F3104035ITA<<<<<<<<<<<2"
        let zs = MotoreCartaIdentita.zonaOttica(sbagliata)
        verifica.vero("Carta: con la cifra della nascita sbagliata la nascita resta da guardare",
                      zs?[.dataNascita]?.daGuardare == true && zs?[.scadenza]?.daGuardare == false)
        let unite = MotoreCartaIdentita.leggi(CartaIdentitaFacSimile.righe() + sbagliata.map { RigaLetta(testo: $0) })
        verifica.vero("Carta: con la zona che non torna vale il fronte, segnato da guardare",
                      unite[.dataNascita]?.fonte == .fronte && unite[.dataNascita]?.daGuardare == true)
        let nonZona = MotoreCartaIdentita.zonaOttica(CartaIdentitaFacSimile.zonaDisegnata)
        verifica.vero("Carta: la zona disegnata del template (troppo corta) non si legge come zona ottica", nonZona == nil)
        let td3 = [
            "P<ITAMARCHI<<ELENA<<<<<<<<<<<<<<<<<<<<<<<<<<",
            "YA00000008ITA9004034F3104035<<<<<<<<<<<<<<00",
        ]
        let p = MotoreCartaIdentita.zonaOttica(td3)
        verifica.vero("Carta: la zona TD3 del passaporto si legge (tipo passaporto, nascita e scadenza)",
                      td3.allSatisfy { $0.count == 44 } && p?.tipo == .passaporto && p?.dataNascita == giorno(1990, 4, 3)
                        && p?.scadenza == giorno(2031, 4, 3) && p?.nomeCompleto == "Elena Marchi")
    }

    // MARK: - Punti 7-10 e 12: fronte, mancanti, fronte e retro, scaduto, limiti del ponte

    private static func fronte(_ verifica: VerificaCalcoli) {
        let oggi = giorno(2026, 11, 8)
        let f = MotoreCartaIdentita.leggi(CartaIdentitaFacSimile.righe())
        verifica.vero("Carta: il fronte del fac-simile dà i campi del template, ognuno con il suo riquadro",
                      !f.conZonaOttica && f.tipo == .cartaIdentita
                        && CartaIdentitaFacSimile.campiDisegnati.allSatisfy { f[$0]?.fonte == .fronte && f[$0]?.riquadro != nil })
        let righe = MotoreCartaIdentita.righe(f, correzioni: [:], oggi: oggi)
        verifica.vero("Carta: cinque righe nell'ordine del template", righe.map(\.id) == ["nome", "nascita", "cf", "documento", "eta"])
        verifica.vero("Carta: «Elena Marchi», «Nata il» «3 aprile 1990, a Bologna», «36 anni»",
                      righe[0].valore == "Elena Marchi" && righe[1].etichetta == "Nata il" && righe[1].valore == "3 aprile 1990, a Bologna"
                        && righe[4].valore == "36 anni")
        verifica.vero("Carta: «MRCLNE90D43A944S · ✓ coerente (comune non controllato)» e «carta d'identità · scade nel 2031»",
                      righe[2].valore == "MRCLNE90D43A944S · ✓ coerente (comune non controllato)"
                        && righe[3].valore == "carta d'identità · scade nel 2031" && righe.allSatisfy { $0.stato == .letta })
        verifica.vero("Carta: con il fronte intero «Anagrafica completa»", MotoreCartaIdentita.sottotitolo(f) == "Anagrafica completa")

        let parziale = MotoreCartaIdentita.leggi(CartaIdentitaFacSimile.righeParziali())
        let rp = MotoreCartaIdentita.righe(parziale, correzioni: [:], oggi: oggi)
        verifica.vero("Carta: i campi non letti restano nil, mai inventati", parziale[.scadenza] == nil && parziale[.luogoNascita] == nil)
        verifica.vero("Carta: lettura parziale «Mancano 2 dati», documento «non letto: lo scrivi tu», codice fiscale da guardare",
                      MotoreCartaIdentita.sottotitolo(parziale) == "Mancano 2 dati" && rp[3].stato == .mancante
                        && rp[3].valore == MotoreCartaIdentita.nonLetto && rp[2].stato == .daGuardare
                        && rp[2].valore.hasSuffix("non torna con la data di nascita: controllalo"))
        let corretta = MotoreCartaIdentita.righe(parziale, correzioni: [.codiceFiscale: "MRCLNE90D43A944S"], oggi: oggi)
        verifica.vero("Carta: il codice corretto a mano si ricontrolla e diventa «scritto da te»", corretta[2].stato == .scrittaDaTe)

        let retro = MotoreCartaIdentita.leggi(CartaIdentitaFacSimile.righeRetro())
        let unita = parziale.unita(con: retro)
        verifica.vero("Carta: fronte e retro si sommano (la scadenza arriva dal retro, il nome del fronte resta)",
                      unita.scadenza == giorno(2031, 4, 3) && unita[.nome]?.fonte == .fronte && unita.conZonaOttica
                        && unita[.cittadinanza] != nil)
        let soloFronte = f.unita(con: LetturaCartaIdentita())
        verifica.vero("Carta: una seconda faccia vuota non cancella nulla", soloFronte == f)

        let scaduta = MotoreCartaIdentita.righe(f, correzioni: [.scadenza: "03.04.2026"], oggi: oggi)
        verifica.vero("Carta: documento scaduto «carta d'identità · scaduta il 3 aprile 2026», da guardare, con la nota",
                      scaduta[3].stato == .daGuardare && scaduta[3].valore == "carta d'identità · scaduta il 3 aprile 2026"
                        && scaduta[3].nota == MotoreCartaIdentita.notaScaduto)

        let righeCarta = CartaIdentitaFacSimile.righe()
        verifica.vero("Carta: la busta della carta del fac-simile è valida",
                      CartaIdentitaPonte(dispositivo: "iPhone di prova", righe: righeCarta).valido)
        let troppe = Array(repeating: RigaLetta(testo: "riga"), count: PonteVera.massimoRighe + 1)
        verifica.vero("Carta: oltre il massimo delle righe la busta è rifiutata",
                      !CartaIdentitaPonte(dispositivo: "iPhone di prova", righe: troppe).valido)
        verifica.vero("Carta: tre facce non vanno", !CartaIdentitaPonte(dispositivo: "iPhone di prova", righe: righeCarta, facce: 3).valido)
        verifica.vero("Carta: un nome del dispositivo troppo lungo non va",
                      !CartaIdentitaPonte(dispositivo: String(repeating: "x", count: PonteVera.massimoDispositivo + 1), righe: righeCarta).valido)
        verifica.vero("Carta: una busta senza righe non va", !CartaIdentitaPonte(dispositivo: "iPhone di prova", righe: []).valido)
    }

    // MARK: - Punto 11: doppioni

    private static func doppioni(_ verifica: VerificaCalcoli) {
        let f = MotoreCartaIdentita.leggi(CartaIdentitaFacSimile.righe())
        var conCodice = Cliente.nuovo(tinta: .verde)
        conCodice.nome = "Elena Rossi"
        conCodice.codiceFiscale = "mrclne90d43a944s"
        verifica.vero("Carta: doppione per codice fiscale (anche minuscolo)",
                      MotoreCartaIdentita.clienteGiaPresente(f, clienti: [conCodice])?.id == conCodice.id)
        var conNome = Cliente.nuovo(tinta: .blu)
        conNome.nome = "MARCHI ELENA"
        conNome.dataNascita = giorno(1990, 4, 3)
        verifica.vero("Carta: doppione per nome (invertito) e data di nascita",
                      MotoreCartaIdentita.clienteGiaPresente(f, clienti: [conNome])?.id == conNome.id)
        var altraData = conNome
        altraData.dataNascita = giorno(1991, 4, 3)
        verifica.vero("Carta: stesso nome e data diversa non è un doppione",
                      MotoreCartaIdentita.clienteGiaPresente(f, clienti: [altraData]) == nil)
    }

    // MARK: - Punto 13: la creazione del cliente

    private static func creazione(_ verifica: VerificaCalcoli) {
        let s = StatoShell(persistente: false)
        let prima = s.dati.clienti.count
        s.nuovoCliente.apri(fase: .trascina)
        s.nuovoCliente.mostra(righe: CartaIdentitaFacSimile.righe() + CartaIdentitaFacSimile.righeRetro(), origine: "prova", subito: true)
        let c = s.creaClienteDaCarta()
        let creato = s.dati.clienti.first { $0.id == c?.id }
        verifica.vero("Carta: «Crea il dossier» crea un cliente con nome, codice fiscale, nascita, luogo e cittadinanza",
                      s.dati.clienti.count == prima + 1 && creato?.nome == "Elena Marchi" && creato?.codiceFiscale == "MRCLNE90D43A944S"
                        && creato?.dataNascita == giorno(1990, 4, 3) && creato?.luogoNascita == "Bologna (BO)" && creato?.cittadinanza == "Italiana")
        verifica.vero("Carta: il documento entra nella conformità (carta d'identità, numero, scadenza)",
                      creato?.conformita?.documento?.tipo == .cartaIdentita && creato?.conformita?.documento?.numero == "CA00000AA"
                        && creato?.conformita?.documento?.scadenza == giorno(2031, 4, 3))
        verifica.vero("Carta: niente canali, consensi, email, telefono o professione scritti da soli",
                      creato?.canali.isEmpty == true && creato?.consensi == Consensi() && creato?.email == "" && creato?.telefono == ""
                        && creato?.professione == "")
        verifica.vero("Carta: dopo «Crea» la scena è svuotata (niente resta in memoria)", s.nuovoCliente.lettura.vuota && s.nuovoCliente.righe.isEmpty)
        // «Aggiorna il documento» cambia solo il documento
        guard let i = s.dati.clienti.firstIndex(where: { $0.id == "giulia" }) else { return verifica.vero("Carta: manca Giulia", false) }
        var giulia = s.dati.clienti[i]
        s.nuovoCliente.apri(fase: .trascina)
        s.nuovoCliente.mostra(righe: CartaIdentitaFacSimile.righeRetro(), origine: "prova", subito: true)
        s.aggiornaDocumentoDaCarta("giulia")
        let dopo = s.dati.clienti.first { $0.id == "giulia" }
        giulia.conformita = dopo?.conformita
        verifica.vero("Carta: «Aggiorna il documento» cambia solo il documento del cliente",
                      dopo == giulia && dopo?.conformita?.documento?.numero == "CA00000AA")
    }

    // MARK: - «È un potenziale cliente» (§9.1.4) e «Diventa cliente» (§9.2.4)

    /// Elena Marchi (DATI DI PROVA: lo stesso nome della carta fac-simile) fra i potenziali, presentata da Sofia.
    private static func elena(_ id: String, fase: FasePotenziale) -> PotenzialeCliente {
        var p = PotenzialeCliente(id: id, nome: "Elena Marchi", creatoIl: giorno(2026, 6, 15))
        p.presentatoDa = "sofia"
        p.fase = fase
        p.email = "elena.prova@example.invalid"
        return p
    }

    private static func potenziale(_ verifica: VerificaCalcoli) {
        // 1. La carta letta riconosce il potenziale per nome; «Crea il dossier» porta chi l'ha presentata e lo collega
        let s = StatoShell(persistente: false)
        s.dati.potenziali = s.dati.potenziali + [elena("pot-carta-elena", fase: .proposta)]
        s.nuovoCliente.apri(fase: .trascina)
        s.nuovoCliente.mostra(righe: CartaIdentitaFacSimile.righe(), origine: "prova", subito: true)
        let p = s.potenzialeDaCarta
        verifica.vero("Carta: la carta di Elena Marchi riconosce il potenziale con lo stesso nome", p?.id == "pot-carta-elena")
        verifica.vero("Carta: la scena dice «Elena Marchi è tra i potenziali, presentata da Sofia» (genere dalla carta)",
                      p.map { s.frasePotenzialeDaCarta($0) } == "Elena Marchi è tra i potenziali, presentata da Sofia")
        let c = s.creaClienteDaCarta()
        let creato = s.dati.clienti.first { $0.id == c?.id }
        let dopo = s.dati.potenziali.first { $0.id == "pot-carta-elena" }
        verifica.vero("Carta: il dossier nato dal potenziale porta chi l'ha presentata, con la data della presentazione",
                      creato?.presentatoDa == "sofia" && creato?.presentatoIl == giorno(2026, 6, 15)
                        && creato?.email == "elena.prova@example.invalid" && creato?.codiceFiscale == "MRCLNE90D43A944S")
        verifica.vero("Carta: il potenziale passa in «Cliente», collegato al dossier",
                      dopo?.fase == .cliente && dopo?.clienteId == creato?.id && dopo?.storia.last?.fase == .cliente)
        s.nuovoCliente.apri(fase: .trascina)
        s.nuovoCliente.mostra(righe: CartaIdentitaFacSimile.righe(), origine: "prova", subito: true)
        verifica.vero("Carta: una seconda lettura della stessa carta non ritrova il potenziale (ora è il cliente)",
                      s.potenzialeDaCarta == nil && s.clienteGiaPresenteDaCarta?.id == creato?.id)
        s.svuotaNuovoCliente()

        // 2. «Diventa cliente» apre la scena con il nome già scritto; chiusa senza dossier, la scheda torna in «Proposta»
        let t = StatoShell(persistente: false)
        t.dati.potenziali = t.dati.potenziali + [elena("pot-scena-elena", fase: .analisi)]
        t.nuovoCliente.apri(fase: .trascina, potenziale: "pot-scena-elena")
        verifica.vero("Carta: aperta da «Diventa cliente», la scena conosce il potenziale prima di leggere la carta",
                      t.potenzialeDaCarta?.id == "pot-scena-elena"
                        && t.potenzialeDaCarta.map { t.frasePotenzialeDaCarta($0) } == "Elena Marchi è tra i potenziali, su presentazione di Sofia")
        t.nuovoCliente.ricomincia(fase: .trascina)
        verifica.vero("Carta: «Riprova» non dimentica il potenziale", t.nuovoCliente.potenzialeId == "pot-scena-elena")
        t.svuotaNuovoCliente()
        let annullata = t.dati.potenziali.first { $0.id == "pot-scena-elena" }
        verifica.vero("Carta: chiusa senza dossier, la scheda torna in «Proposta» e non diventa cliente",
                      annullata?.fase == .proposta && annullata?.clienteId == nil && t.nuovoCliente.potenzialeId == nil)

        // 3. «Scrivi a mano» dalla scena del potenziale: il modulo porta chi l'ha presentata e lo collega al salvataggio
        t.nuovoCliente.apri(fase: .trascina, potenziale: "pot-scena-elena")
        t.scriviAManoDaCarta()
        verifica.vero("Carta: «Scrivi a mano» apre il modulo con il nome del potenziale e chi l'ha presentata",
                      t.bozzaNuovoCliente?.nome == "Elena Marchi" && t.bozzaNuovoCliente?.presentatoDa == "sofia"
                        && t.potenzialeDellaBozza == "pot-scena-elena")
        verifica.vero("Carta: passato al modulo, il potenziale resta in «Proposta» (lo collega il salvataggio)",
                      t.dati.potenziali.first { $0.id == "pot-scena-elena" }?.fase == .proposta)
        if let bozza = t.bozzaNuovoCliente, let id = t.potenzialeDellaBozza {
            t.confermaClienteDaPotenziale(potenziale: id, cliente: bozza)
        }
        let collegata = t.dati.potenziali.first { $0.id == "pot-scena-elena" }
        verifica.vero("Carta: salvato il modulo, la scheda è in «Cliente» collegata al dossier",
                      collegata?.fase == .cliente && collegata?.clienteId == t.bozzaNuovoCliente?.id
                        && t.dati.clienti.contains { $0.id == collegata?.clienteId && $0.presentatoDa == "sofia" })
    }
}
