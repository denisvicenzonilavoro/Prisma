#if os(macOS)
import Foundation

/// Le istantanee di «Nuovo cliente in 10 secondi» (Design/template-luce-specifica.md §9.1.7, «Luce» giro 13), tutte nello
/// stato finale (`\.modoIstantanea`):
/// - 840: la scena aperta con il ponte acceso, in attesa dell'iPhone (chiara e scura);
/// - 841: lo stato finale del template (carta fac-simile con i campi accesi, cinque righe, «3,6», moduli pronti), chiara
///   e scura; 842: lettura parziale (scadenza e luogo non letti, codice fiscale che non torna);
/// - 843: il cliente già in Prisma; 844: senza i modelli dei moduli; 845: il ponte spento; 846: «Riduci movimento»;
/// - 847: la testata di Clienti con il menu «…» e «Nuovo cliente» col glifo.
///
/// DATI DI PROVA DICHIARATI: la carta fac-simile «Elena Marchi» (`CartaIdentitaFacSimile`, scritta «FAC-SIMILE», numero
/// «CA00000AA» palesemente finto), i moduli fac-simile disegnati da Prisma e il codice fiscale messo a un cliente di prova
/// (843) esistono SOLO dentro queste scene: lo stato delle istantanee non si salva. Il contatore è fermo al valore
/// dichiarato della scena di prova (3,6 secondi), non a un tempo vero.
extension Istantanee {
    nonisolated static var sceneNuovoCliente: [(nome: String, prepara: (StatoShell) -> Void)] {
        var scene: [(nome: String, prepara: (StatoShell) -> Void)] = []
        func una(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            scene.append((nome: nome, prepara: prepara))
        }
        func coppia(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            una(nome, prepara)
            una(nome + "-scuro", prepara)
        }
        coppia("840-clienti-nuovo-attesa") { s in
            preparaNuovoCliente(s)
        }
        coppia("841-clienti-nuovo-letto") { s in
            preparaNuovoCliente(s, righe: CartaIdentitaFacSimile.righe(), moduli: true)
        }
        una("842-clienti-nuovo-parziale") { s in
            preparaNuovoCliente(s, righe: CartaIdentitaFacSimile.righeParziali(), moduli: true)
        }
        una("843-clienti-nuovo-gia-cliente") { s in
            if let i = s.dati.clienti.firstIndex(where: { $0.id == "laura" }) {
                s.dati.clienti[i].codiceFiscale = CartaIdentitaFacSimile.codiceFiscale
            }
            preparaNuovoCliente(s, righe: CartaIdentitaFacSimile.righe(), moduli: true)
        }
        una("844-clienti-nuovo-senza-moduli") { s in
            preparaNuovoCliente(s, righe: CartaIdentitaFacSimile.righe(), moduli: false)
        }
        una("845-clienti-nuovo-ponte-spento") { s in
            preparaNuovoCliente(s, ponte: false)
        }
        una("846-clienti-nuovo-calmo") { s in
            s.dati.impostazioni.riduciMovimento = true
            preparaNuovoCliente(s, righe: CartaIdentitaFacSimile.righe(), moduli: true)
        }
        una("847-clienti-testata-luce") { s in
            s.apriApp(.clienti)
        }
        return scene
    }

    /// Clienti davanti con la scena aperta: il ponte acceso o spento, i moduli fac-simile (privacy e adeguata verifica)
    /// in memoria e, se ci sono, le righe della carta arrivate dall'iPhone di prova, con il contatore fermo a 3,6.
    nonisolated static func preparaNuovoCliente(_ s: StatoShell, ponte: Bool = true, righe: [RigaLetta]? = nil, moduli: Bool = false) {
        s.dati.impostazioni.vera.ponte.condividi = ponte
        if ponte, !s.dati.impostazioni.vera.ponte.abbinato { s.dati.impostazioni.vera.ponte.codice = PonteVera.nuovoCodice() }
        if moduli { moduliPrivacyEVerificaDiProva(s) }
        s.apriApp(.clienti)
        s.apriNuovoCliente()
        if let righe {
            s.nuovoCliente.mostra(righe: righe, origine: CartaIdentitaFacSimile.dispositivo, carta: "carta-prova", subito: true)
            s.nuovoCliente.fermaPerIstantanea(secondi: 3.6)
        }
    }

    /// I fac-simile di Prisma: l'adeguata verifica di `caricaEsempiModuli` e la stessa pagina come informativa privacy
    /// (dati di prova, solo in memoria).
    nonisolated static func moduliPrivacyEVerificaDiProva(_ s: StatoShell) {
        s.caricaEsempiModuli()
        guard let verifica = s.moduli.tutti.first(where: { $0.tipo == .adeguataVerifica }), let pdf = s.moduli.pdf(verifica) else { return }
        var privacy = verifica
        privacy.id = "modulo-prova-privacy"
        privacy.titolo = "Informativa privacy (fac-simile)"
        privacy.tipo = .privacy
        privacy.file = "modulo-prova-privacy.pdf"
        s.moduli.aggiungi(privacy, pdf: pdf)
    }
}
#endif
