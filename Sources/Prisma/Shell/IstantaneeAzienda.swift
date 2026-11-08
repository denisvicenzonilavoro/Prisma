#if os(macOS)
import SwiftUI

/// Le istantanee della scheda «L'azienda» del dossier (Design/template-luce-specifica.md §9.3.7, «Luce» giro 7), tutte
/// nello stato finale (anelli pieni al valore, numeri completi):
/// - 858: Marco Bianchi con l'azienda di prova del template: testata e quattro schede (0, 0, 33, 20: le percentuali
///   vengono da `MotoreAzienda` sulle liste di prova, non dal 35 e dal 10 dimostrativi del template), chiaro e scuro;
/// - 859: un'azienda con il solo nome: «fatturato da inserire», anelli grigi «—» e «Inserisci i dati ›», chiaro e scuro;
/// - 860: il foglio `ModuloAzienda` aperto sopra il dossier (i fogli non si disegnano fuori schermo: il modulo è messo
///   sopra la shell, con il velo);
/// - 861: la finestra stretta, griglia a 2 colonne.
/// DATI DI PROVA DICHIARATI: `AziendeDiProva` (il piede della scheda dice «Dati aziendali di prova»).
extension Istantanee {
    nonisolated static var sceneAzienda: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("858-dossier-azienda", { s in marcoAzienda(s) }),
            ("858-dossier-azienda-scuro", { s in marcoAzienda(s) }),
            ("859-dossier-azienda-da-completare", { s in soloNome(s) }),
            ("859-dossier-azienda-da-completare-scuro", { s in soloNome(s) }),
            ("860-dossier-azienda-modulo", { s in marcoAzienda(s) }),
            ("861-dossier-azienda-stretta", { s in marcoAzienda(s) }),
        ]
    }

    /// Le scene della scheda che disegnano qualcosa sopra la shell (il foglio del modulo).
    nonisolated static let sceneModuloAzienda: Set<String> = ["860-dossier-azienda-modulo"]

    nonisolated private static func marcoAzienda(_ s: StatoShell) {
        s.clienteAttivoId = "marco"
        s.schedaCliente = .azienda
        s.apri(.clienti)
    }

    /// L'azienda di Marco con il solo nome (di prova).
    nonisolated private static func soloNome(_ s: StatoShell) {
        if let i = s.dati.clienti.firstIndex(where: { $0.id == "marco" }) {
            var a = AziendaCliente(id: AziendeDiProva.idBianchi, ragioneSociale: "Bianchi Serramenti S.r.l.")
            a.diProva = true
            s.dati.clienti[i].aziende = [a]
        }
        marcoAzienda(s)
    }

    /// La shell con sopra il foglio del modulo dell'azienda di Marco (scena 860); nil per le altre scene.
    static func moduloAziendaIstantanea(_ nome: String, _ s: StatoShell) -> AnyView? {
        guard sceneModuloAzienda.contains(nome), let c = s.cliente("marco"), let a = c.elencoAziende.first else { return nil }
        return AnyView(
            ZStack {
                ShellView()
                Tema.Colore.velo
                ModuloAzienda(modifica: ModificaAzienda(azienda: a, nuova: false), cliente: c,
                              posizioni: s.posizioniCliente(c.id), salva: { _ in }, elimina: { _ in })
                    // Il foglio vero ha il fondo del sistema: qui serve pieno, o la shell passerebbe attraverso
                    .background(Tema.Apple.Colore.cardPiena)
                    .clipShape(RoundedRectangle(cornerRadius: Tema.Apple.Raggio.finestra, style: .continuous))
                    .ombraApple(.finestra)
            }
        )
    }
}
#endif
