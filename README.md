# Prisma
Financial Desk for Financial Advisor

App macOS nativa (SwiftUI, Swift Package Manager, senza Xcode) per uso personale.

## Scarica
L'ultima versione di main, rifatta a ogni unione con la build verde:
- Mac: https://github.com/denisvicenzonilavoro/Prisma/releases/download/ultima/Prisma.zip
- iPhone e iPad (AltStore / Sideloadly): https://github.com/denisvicenzonilavoro/Prisma/releases/download/ultima/Prisma.ipa

## Build
Build e prove avvengono solo su GitHub Actions (`.github/workflows/build.yml`, runner `macos-15`, Apple Silicon) a ogni push.
L'artifact scaricabile si chiama **Prisma** e contiene `Prisma.zip` con dentro `Prisma.app` (solo Apple Silicon, firma ad-hoc).
Sul Mac si installa l'ultima versione di main con `bash Supporto/installa-ultima.sh`.

## Struttura
- `Sources/Prisma/` — codice dell'app
- `Sources/Prisma/Risorse/` — risorse (icone convertite da `Design/Icone`)
- `Design/template.html` — template grafico di riferimento
- `Design/Icone/` — icone originali (SVG) e `AppIcon.png` per l'icona dell'app

## Anteprime
A ogni push il workflow disegna le schermate principali (`Prisma --istantanee <cartella>`) e le pubblica sul branch `anteprime`.
