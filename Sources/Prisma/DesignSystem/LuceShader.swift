import SwiftUI
import simd

// Il prisma di luce (Design/template-luce-specifica.md §2.2.2-bis e §2.2.2-ter, «Luce» giro 4): lo shader `FS_LUCE` del
// template portato in Metal (MSL), con la disposizione delle uniformi, e la geometria della scena che serve anche a
// Swift (etichette in fondo ai raggi, raggio sotto il puntatore, fermo-immagine). Stesso schema dell'acqua: sorgente in
// una stringa compilata a runtime (SwiftPM da riga di comando non compila i .metal), uniformi in `float4` passate con
// `setFragmentBytes`, formato `.bgra8Unorm` (i colori delle fasce sono i valori sRGB 0…1 così come sono, come nel
// template). Le coordinate sono in punti con l'origine in alto a sinistra: in Metal `[[position]]` parte già dall'alto.

enum ShaderLuce {
    /// Le uniformi come le legge lo shader (56 float, 224 byte):
    ///   tela      0: larghezza px, altezza px, pixel per punto, tempo
    ///   cristallo 4: C.x, C.y, R, rotazione
    ///   fasi      8: raggio, vetro, ventaglio, lunghezza
    ///   varie    12: n, respiro, −, −
    ///   bordi    16: e[0…6] (otto posti, l'ottavo = 1)
    ///   pesi     24: w[0…5]
    ///   colori   32: c[i].rgb, −
    struct Strato {
        var pixel: CGSize = .zero
        var pixelPerPunto: Float = 1
        var tempo: Float = 0
        var centro: CGPoint = .zero
        var raggio: Float = 0
        var rotazione: Float = 0
        var fasi = SIMD3<Float>(1, 1, 1)
        var lunghezza: Float = 0
        var n: Int = 0
        var respiro: Float = 1
        /// Sette bordi cumulati 0…1.
        var bordi: [Float] = Array(repeating: 1, count: 7)
        var pesi: [Float] = Array(repeating: 1, count: 6)
        var colori: [SIMD3<Float>] = Array(repeating: .zero, count: 6)

        static let numeroFloat = 56

        var impacchettate: [Float] {
            var u = [Float](repeating: 0, count: Self.numeroFloat)
            u[0] = Float(pixel.width); u[1] = Float(pixel.height); u[2] = pixelPerPunto; u[3] = tempo
            u[4] = Float(centro.x); u[5] = Float(centro.y); u[6] = raggio; u[7] = rotazione
            u[8] = fasi.x; u[9] = fasi.y; u[10] = fasi.z; u[11] = lunghezza
            u[12] = Float(n); u[13] = respiro
            for i in 0..<8 { u[16 + i] = i < bordi.count ? bordi[i] : 1 }
            for i in 0..<6 { u[24 + i] = i < pesi.count ? pesi[i] : 1 }
            for i in 0..<6 {
                let c = i < colori.count ? colori[i] : .zero
                u[32 + i * 4] = c.x; u[33 + i * 4] = c.y; u[34 + i * 4] = c.z
            }
            return u
        }
    }

    static let sorgente = """
    #include <metal_stdlib>
    using namespace metal;

    struct UniformiLuce {
        float4 tela;
        float4 cristallo;
        float4 fasi;
        float4 varie;
        float4 bordi[2];
        float4 pesi[2];
        float4 colori[6];
    };

    struct UscitaLuce {
        float4 posizione [[position]];
    };

    vertex UscitaLuce vs_luce(uint id [[vertex_id]]) {
        float2 v = float2(id == 1 ? 3.0 : -1.0, id == 2 ? 3.0 : -1.0);
        UscitaLuce o;
        o.posizione = float4(v, 0.0, 1.0);
        return o;
    }

    static float h21(float2 p) {
        p = fract(p * float2(123.34, 456.21));
        p += dot(p, p + 45.32);
        return fract(p.x * p.y);
    }

    static float2 ruota(float2 v, float a) {
        float c = cos(a), s = sin(a);
        return float2(c * v.x - s * v.y, s * v.x + c * v.y);
    }

    static float sdSeg(float2 p, float2 a, float2 b) {
        float2 pa = p - a, ba = b - a;
        float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-6), 0.0, 1.0);
        return length(pa - ba * h);
    }

    static float sdTri(float2 p, float2 p0, float2 p1, float2 p2) {
        float2 e0 = p1 - p0, e1 = p2 - p1, e2 = p0 - p2;
        float2 v0 = p - p0, v1 = p - p1, v2 = p - p2;
        float2 q0 = v0 - e0 * clamp(dot(v0, e0) / dot(e0, e0), 0.0, 1.0);
        float2 q1 = v1 - e1 * clamp(dot(v1, e1) / dot(e1, e1), 0.0, 1.0);
        float2 q2 = v2 - e2 * clamp(dot(v2, e2) / dot(e2, e2), 0.0, 1.0);
        float s = sign(e0.x * e2.y - e0.y * e2.x);
        float2 d = min(min(float2(dot(q0, q0), s * (v0.x * e0.y - v0.y * e0.x)),
                           float2(dot(q1, q1), s * (v1.x * e1.y - v1.y * e1.x))),
                           float2(dot(q2, q2), s * (v2.x * e2.y - v2.y * e2.x)));
        return -sqrt(d.x) * sign(d.y);
    }

    static float bordo(constant UniformiLuce &u, int i) { return u.bordi[i / 4][i % 4]; }
    static float peso(constant UniformiLuce &u, int i) { return u.pesi[i / 4][i % 4]; }

    static float3 luce(float2 p, constant UniformiLuce &u) {
        float t = u.tela.w;
        float2 C = u.cristallo.xy;
        float R = u.cristallo.z;
        float rot = u.cristallo.w;
        float beamF = u.fasi.x, glassF = u.fasi.y, fanF = u.fasi.z, lenF = u.fasi.w;
        float n = u.varie.x, lum = u.varie.y;
        float2 P0 = C + ruota(float2(0.0, -R), rot);
        float2 P1 = C + ruota(float2(-0.866 * R, 0.5 * R), rot);
        float2 P2 = C + ruota(float2(0.866 * R, 0.5 * R), rot);
        float2 Q = C + ruota(float2(0.0, R * 0.2), rot);
        float2 E = mix(P0, P1, 0.57), X = mix(P0, P2, 0.6);
        float3 L = float3(0.0);

        // Il raggio che entra
        float2 dIn = normalize(float2(1.0, -0.085));
        float2 S0 = E - dIn * 1500.0;
        float2 Hd = S0 + dIn * 1500.0 * beamF;
        float d = sdSeg(p, S0, Hd);
        float beam = exp(-d * d / 1.6) * 2.2 + exp(-d / 7.0) * 0.42 + exp(-d / 34.0) * 0.13;
        L += float3(1.0, 0.985, 0.96) * beam * lum * step(0.001, beamF);

        // Il pulviscolo nel raggio
        float2 rel = p - S0;
        float s = dot(rel, dIn);
        float pe = dot(rel, float2(-dIn.y, dIn.x));
        float cell = floor((s - t * 26.0) / 22.0);
        float jit = (h21(float2(cell, 3.1)) - 0.5) * 34.0;
        float ss = fract((s - t * 26.0) / 22.0) * 22.0 - 11.0;
        float dust = exp(-(ss * ss + (pe - jit) * (pe - jit)) / 1.3) * step(s, 1500.0 * beamF)
                     * (0.4 + 0.6 * sin(t * 2.0 + cell)) * exp(-abs(pe) / 14.0);
        L += float3(1.0) * max(dust, 0.0) * 0.9;

        // Il vetro: tre spicchi come il logo
        float2 c0 = (P0 + P1 + P2) / 3.0;
        float rr = 9.0;
        float2 a0 = P0 + normalize(c0 - P0) * rr * 2.0;
        float2 a1 = P1 + normalize(c0 - P1) * rr * 2.0;
        float2 a2 = P2 + normalize(c0 - P2) * rr * 2.0;
        float sd = sdTri(p, a0, a1, a2) - rr;
        float m = 1.0 - smoothstep(-0.8, 0.8, sd);
        float wL = step(sdTri(p, Q, P0, P1), 0.0);
        float wR = step(sdTri(p, Q, P0, P2), 0.0);
        float wB = step(sdTri(p, Q, P1, P2), 0.0);
        float face = wL * 0.20 + wR * 0.13 + wB * 0.075;
        float3 vetro = float3(0.80, 0.90, 1.0) * face * m;
        float dl = min(min(sdSeg(p, Q, P0), sdSeg(p, Q, P1)), sdSeg(p, Q, P2));
        vetro += float3(0.85, 0.93, 1.0) * exp(-dl / 0.9) * 0.55 * m;
        vetro -= float3(0.06) * m * (1.0 - smoothstep(0.8, 2.6, dl));
        vetro += float3(0.9, 0.95, 1.0) * (exp(-abs(sd) / 1.0) * 1.25 + exp(-abs(sd) / 7.0) * 0.16);
        vetro += float3(0.75, 0.88, 1.0) * exp(sd / 16.0) * 0.22 * m;
        float st = dot(p - C, normalize(float2(1.0, 1.25)));
        float ds = (st - (rot * 260.0 + sin(t * 0.27) * 24.0 - 30.0)) / 14.0;
        float streak = exp(-ds * ds) * 0.38 * m;
        vetro += float3(1.0) * streak;
        L += vetro * glassF;

        // La luce dentro il vetro, che comincia a scomporsi
        float di = sdSeg(p, E, X);
        float2 ex = X - E;
        float ti = clamp(dot(p - E, ex) / dot(ex, ex), 0.0, 1.0);
        float3 avg = float3(0.0);
        for (int i = 0; i < 6; i++) {
            if (float(i) >= n) break;
            avg += u.colori[i].rgb * (bordo(u, i + 1) - bordo(u, i));
        }
        L += mix(float3(1.0), avg * 1.4, ti) * (exp(-di * di / (2.0 + ti * 30.0)) * 1.1 + exp(-di / 12.0) * 0.25)
             * m * smoothstep(0.0, 0.2, glassF) * lum;

        // Il ventaglio che esce
        float aO = 0.08 + rot * 1.55, SP = 0.5;
        float2 v = p - X;
        float r = length(v);
        float a = atan2(v.y, v.x) - aO;
        float f = (a + SP * 0.5) / SP;
        float Lf = lenF * fanF;
        float rad = (1.0 - smoothstep(Lf * 0.78, Lf + 1.0, r)) * step(0.0, v.x + 40.0);
        float edg = smoothstep(-0.015, 0.03, f) * (1.0 - smoothstep(0.97, 1.015, f));
        float sep = smoothstep(20.0, 380.0, r);
        float3 col = float3(0.0);
        for (int i = 0; i < 6; i++) {
            if (float(i) >= n) break;
            float e0 = bordo(u, i), e1 = bordo(u, i + 1);
            if (e1 - e0 < 0.0005) continue;
            float gap = sep * 0.007, sf = mix(0.07, 0.0035, sep);
            float mm = smoothstep(e0 + gap - sf, e0 + gap + sf, f) * (1.0 - smoothstep(e1 - gap - sf, e1 - gap + sf, f));
            col += u.colori[i].rgb * mm * peso(u, i);
        }
        col = mix(float3(1.0, 0.97, 0.93) * 1.05, col, smoothstep(0.0, 210.0, r));
        float silk = 0.94 + 0.06 * sin(f * 70.0 + t * 0.4);
        float inten = edg * rad * silk * (0.42 + 1.05 * exp(-r / 430.0));
        float fuori = max(-f, f - 1.0);
        float glow = exp(-max(fuori, 0.0) * SP * r / 22.0) * (1.0 - edg) * rad * 0.12;
        L += col * inten * lum + mix(float3(0.75, 0.8, 1.0), col, 0.3) * glow;
        L += float3(1.0, 0.97, 0.92) * exp(-length(p - X) / 9.0) * 0.9 * fanF * lum
             + float3(1.0) * exp(-length(p - E) / 8.0) * 0.7 * beamF * lum;
        return L;
    }

    fragment float4 fs_luce(UscitaLuce in [[stage_in]], constant UniformiLuce &u [[buffer(0)]]) {
        float dpp = u.tela.z;
        float2 p = in.posizione.xy / dpp;
        float2 RS = u.tela.xy / dpp;
        float t = u.tela.w;
        float Fy = u.cristallo.y + u.cristallo.z * 0.5 + 100.0;
        float2 c = (p - float2(RS.x * 0.38, RS.y * 0.32)) / RS.y;
        float3 bg = mix(float3(0.10, 0.15, 0.21), float3(0.022, 0.036, 0.054), smoothstep(0.0, 1.05, length(c)));
        bg *= 1.0 - 0.35 * smoothstep(0.5, 1.3, length((p - RS * 0.5) / RS.y));
        float3 L;
        if (p.y > Fy) {
            float k = exp(-(p.y - Fy) / 120.0) * 0.22;
            L = luce(float2(p.x + sin(p.y * 0.08 + t) * 1.2, 2.0 * Fy - p.y), u) * k;
            bg *= 0.82;
            bg += float3(0.5, 0.6, 0.75) * exp(-abs(p.y - Fy) / 1.1) * 0.05
                  * smoothstep(RS.x * 0.95, RS.x * 0.2, abs(p.x - u.cristallo.x) * 1.6);
        } else {
            L = luce(p, u);
        }
        float3 col = bg + (1.0 - exp(-L * 1.15));
        col += (h21(in.posizione.xy + fract(t) * 91.0) - 0.5) * 0.018;
        return float4(clamp(col, 0.0, 1.0), 1.0);
    }
    """
}

/// La geometria della scena nel palco (`ESPM.luce`): la stessa per lo shader, le etichette, il puntatore e il
/// fermo-immagine. Misure in punti, origine in alto a sinistra.
struct GeometriaLuce: Equatable {
    let misura: CGSize

    private typealias S = Tema.Apple.Luce.Scena

    var centro: CGPoint { CGPoint(x: misura.width * S.centroX, y: misura.height * S.centroY) }
    var raggio: CGFloat { min(S.raggioMassimo, misura.height * S.quotaRaggio) }
    var pavimento: CGFloat { centro.y + raggio * 0.5 + S.pavimento }

    private func ruota(_ v: CGPoint, _ a: Double) -> CGPoint {
        let c = CGFloat(cos(a)), s = CGFloat(sin(a))
        return CGPoint(x: centro.x + c * v.x - s * v.y, y: centro.y + s * v.x + c * v.y)
    }

    /// I tre vertici del triangolo (in alto, in basso a sinistra, in basso a destra) e il punto interno del logo.
    func vertici(_ rot: Double) -> (p0: CGPoint, p1: CGPoint, p2: CGPoint, q: CGPoint) {
        let r = raggio
        return (ruota(CGPoint(x: 0, y: -r), rot), ruota(CGPoint(x: -0.866 * r, y: 0.5 * r), rot),
                ruota(CGPoint(x: 0.866 * r, y: 0.5 * r), rot), ruota(CGPoint(x: 0, y: r * S.interno), rot))
    }

    private static func mescola(_ a: CGPoint, _ b: CGPoint, _ k: CGFloat) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * k, y: a.y + (b.y - a.y) * k)
    }

    /// Il punto d'entrata sul lato P0→P1 (57%) e quello d'uscita sul lato P0→P2 (60%).
    func entrata(_ rot: Double) -> CGPoint { let v = vertici(rot); return Self.mescola(v.p0, v.p1, S.entrata) }
    func uscita(_ rot: Double) -> CGPoint { let v = vertici(rot); return Self.mescola(v.p0, v.p2, S.uscita) }

    /// La direzione centrale del ventaglio (rad, y in giù).
    func direzione(_ rot: Double) -> Double { Double(S.direzioneBase) + Double(S.direzionePerRotazione) * rot }

    /// La lunghezza del ventaglio: min(larghezza − X.x − 250, 560) × (0,72 + 0,28·√frazione).
    func lunghezza(rot: Double, frazione: Double) -> CGFloat {
        let base = max(S.lunghezzaMinima, min(misura.width - uscita(rot).x - S.spazioDestra, S.lunghezzaMassima))
        return base * (S.quotaFissa + S.quotaAnni * CGFloat(max(0, min(1, frazione)).squareRoot()))
    }

    /// 0…1 attraverso il ventaglio per il punto dato (fuori dall'apertura < 0 o > 1), e la distanza da X.
    func posizioneNelVentaglio(_ p: CGPoint, rot: Double) -> (f: Double, r: CGFloat) {
        let x = uscita(rot)
        let vx = Double(p.x - x.x), vy = Double(p.y - x.y)
        let f = (atan2(vy, vx) - direzione(rot) + Double(S.apertura) / 2) / Double(S.apertura)
        return (f, CGFloat(hypot(vx, vy)))
    }

    /// La fascia sotto il puntatore: fra 70 da X e la lunghezza + 60, dentro l'apertura.
    func fascia(_ p: CGPoint, rot: Double, bordi: [Double], lunghezza: CGFloat) -> Int? {
        let (f, r) = posizioneNelVentaglio(p, rot: rot)
        guard r > S.sceltaDa, r < lunghezza + S.sceltaOltre, f >= 0, f <= 1, bordi.count >= 2 else { return nil }
        for i in 0..<(bordi.count - 1) where f >= bordi[i] && f < bordi[i + 1] { return i }
        return f >= 1 ? bordi.count - 2 : nil
    }

    /// Dove vanno le etichette: poco oltre la punta di ogni fascia, poi quattro giri di separazione verticale a 44.
    func etichette(rot: Double, bordi: [Double], lunghezza: CGFloat) -> [CGPoint] {
        let e = Tema.Apple.Luce.Etichetta.self
        let x = uscita(rot)
        let ang = direzione(rot)
        var pos: [CGPoint] = []
        for i in 0..<max(0, bordi.count - 1) {
            let fm = (bordi[i] + bordi[i + 1]) / 2
            let a = ang - Double(S.apertura) / 2 + fm * Double(S.apertura)
            let d = Double(lunghezza + e.oltreLaPunta)
            pos.append(CGPoint(x: x.x + CGFloat(cos(a) * d), y: x.y + CGFloat(sin(a) * d)))
        }
        guard pos.count > 1 else { return pos }
        for _ in 0..<e.giriSeparazione {
            for i in 1..<pos.count where pos[i].y - pos[i - 1].y < e.distanzaMinima {
                let m = (e.distanzaMinima - (pos[i].y - pos[i - 1].y)) / 2
                pos[i].y += m
                pos[i - 1].y -= m
            }
        }
        return pos
    }

    /// I bordi cumulati 0…1 delle quote (n + 1 valori).
    static func bordi(_ quote: [Double]) -> [Double] {
        var e: [Double] = [0]
        var s = 0.0
        for q in quote { s += q; e.append(s) }
        guard s > 0 else { return [0, 1] }
        return e.map { $0 / s }
    }
}
