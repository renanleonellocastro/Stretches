<div align="center">

<img src="resources/drawables/launcher_icon.png" alt="Stretches logo" width="96"/>

# 🤸 Stretches

**A colorful stretching-routine coach for Garmin watches.**

Build your own routine, get reminded at the times you choose, follow guided
illustrated stretches, and save every session to Garmin Connect.

[![CI](https://github.com/renanleonellocastro/Stretches/actions/workflows/ci.yml/badge.svg)](../../actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/renanleonellocastro/Stretches?include_prereleases&color=ff5500)](../../releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-ffaa00.svg)](LICENSE)
[![Connect IQ](https://img.shields.io/badge/Connect%20IQ-%E2%89%A53.2-ff8800)](https://developer.garmin.com/connect-iq/)
[![Devices](https://img.shields.io/badge/devices-80-ffaa00)](#-supported-devices)
[![Languages](https://img.shields.io/badge/languages-6-ff5500)](#-languages)

<img src="docs/images/store-hero.png" alt="Stretches on Garmin — guided stretching coach" width="820"/>

</div>

---

## 📷 Screenshots

<div align="center">

| Home | My stretches | Guided stretch | Get ready | Done! |
|:---:|:---:|:---:|:---:|:---:|
| <img src="docs/images/screenshots/home.png" width="150"/> | <img src="docs/images/screenshots/picker.png" width="150"/> | <img src="docs/images/screenshots/stretch.png" width="150"/> | <img src="docs/images/screenshots/announce.png" width="150"/> | <img src="docs/images/screenshots/congrats.png" width="150"/> |

<sub>Captured on the Forerunner 55 simulator. Live heart rate appears during the stretch on a watch with a HR sensor.</sub>

</div>

## ✨ Features

- 🧘 **34 stretches** across neck, wrist/forearm, shoulder/chest, torso/back
  and legs — including twelve dedicated neck positions (tilts, turns and
  combined turn+tilt holds).
- 🎨 **Illustrated guidance**: each stretch shows a clear drawing with a
  motion arrow, color-coded by muscle group.
- 🛠 **Your routine, your rules**: pick any set of stretches, give each one its
  own duration (default 30 s), and set the play order under **Reorder**.
- ⏰ **Daily schedules**: add as many alarm times as you want and toggle each
  one on/off individually.
- 📳 **Smart reminders**: at the scheduled time the watch vibrates and shows a
  calm *Time to stretch!* notification; open the app and press **Start now**.
- 🚦 **Guided flow**: 5-second countdown → stretch preview with a 3-second
  lead-in → live countdown with progress ring → short buzz between
  stretches → 🎉 congratulations screen.
- ⏯ **Full control mid-workout**: pause (START), skip a stretch (DOWN) or
  end early (BACK, with confirmation).
- ❤️ **Real activity recording**: sessions are saved as *Flexibility
  Training* with heart rate, calories and time, one lap per stretch, plus a
  custom *stretches completed* FIT field — all visible in Garmin Connect.
- 🌍 **6 languages** following the watch system language: English,
  Português, Español, Français, Deutsch, Italiano.
- 🔋 **Battery-friendly**: reminders use Connect IQ background temporal
  events; nothing runs while you are not stretching.

## 🖼 The stretch library

<div align="center">
<img src="docs/images/catalog-preview.png" alt="All 34 stretch illustrations" width="760"/>

*34 stretches · 5 muscle groups · hand-crafted figures rendered per screen
size, from the 208×208 Forerunner 55 to the 466×466 fēnix 9 Pro 51mm.*
</div>

## 🎬 How a session works

```mermaid
flowchart LR
    A[⏰ Scheduled time] -->|vibration| B[🔔 Time to stretch! reminder]
    B -->|any key| H0[🏠 Home]
    H0 -->|Start now| C[5s countdown]
    C --> D[🖼 Stretch preview - 3s]
    D --> E[🧘 Stretch countdown]
    E -->|short buzz| D2{More stretches?}
    D2 -->|yes, next in order| D
    D2 -->|no| F[🎉 Congratulations!]
    F --> G{Save workout?}
    G -->|Save| H[📊 Garmin Connect]
    G -->|Discard| Z2[🗑]
```

Stretches play in the order you set — arrange them under **Reorder** in the menu.
The scheduled reminder simply vibrates and shows a notification; open the app and
press **Start now** to begin.

## 📱 Using the app

| Screen | Keys |
|---|---|
| Home | **START** opens the menu |
| Menu | *Start now*, *My stretches*, *Durations*, *Schedules*, *Settings*, *About* |
| My stretches | List of all 34 stretches; tap to add/remove from your routine |
| Durations | Per-stretch seconds picker (5–300 s, default 30 s) |
| Schedules | Add times, then per-time: *Enabled*, *Edit time*, *Delete* |
| Workout | **START** pause/resume · **DOWN** skip · **BACK** end early |

> [!NOTE]
> Reminders use Connect IQ *background temporal events*: the watch wakes the
> app with a confirmation prompt at the scheduled time. Garmin fires these
> with up-to-5-minute granularity and may delay them during an ongoing
> activity — the app clamps and re-registers automatically, and also
> triggers instantly when it is already open.

## ⌚ Supported devices

Forerunner 55 (the reference device) and the Forerunner 70/165/170/245/255/265/
570/745/945/955/965/970 series, Fēnix 6/7/7 Pro/8/E/9 series, Epix 2 and Epix Pro,
Enduro 3, Venu / Venu 2 / Venu 3 / Venu 4 / Venu X1 / Venu Sq series, Vívoactive
4/5/6, Instinct 3 AMOLED and Instinct Crossover AMOLED, MARQ 2, Descent Mk3 and
D2 Mach 1/2. That is 80 models in total, all on Connect IQ API ≥ 3.2.

<details>
<summary>Full device list</summary>

`fr55` `fr70` `fr165` `fr165m` `fr170` `fr170m` `fr245` `fr245m` `fr255`
`fr255m` `fr255s` `fr255sm` `fr265` `fr265s` `fr745` `fr945` `fr945lte`
`fr955` `fr965` `fr970` `fr57042mm` `fr57047mm` `enduro3` `epix2`
`epix2pro42mm` `epix2pro47mm` `epix2pro51mm` `fenix6` `fenix6pro` `fenix6s`
`fenix6spro` `fenix6xpro` `fenix7` `fenix7pro` `fenix7pronowifi` `fenix7s`
`fenix7spro` `fenix7x` `fenix7xpro` `fenix7xpronowifi` `fenix8pro47mm`
`fenix8solar47mm` `fenix8solar51mm` `fenix9pro43mm` `fenix9pro47mm`
`fenix9pro51mm` `fenix9prosolar47mm` `fenix9prosolar51mm` `fenix843mm`
`fenix847mm` `fenix943mm` `fenix947mm` `fenixe` `venu` `venu2` `venu2plus`
`venu2s` `venu3` `venu3s` `venu441mm` `venu445mm` `venusq` `venusq2`
`venusq2m` `venusqm` `venux1` `vivoactive4` `vivoactive4s` `vivoactive5`
`vivoactive6` `instinct3amoled45mm` `instinct3amoled50mm`
`instinctcrossoveramoled` `d2mach1` `d2mach2` `d2mach2pro` `descentmk343mm`
`descentmk351mm` `marq2` `marq2aviator`

</details>

## 🌍 Languages

| | Language | |
|---|---|---|
| 🇺🇸 | English | default |
| 🇧🇷 | Português | |
| 🇪🇸 | Español | |
| 🇫🇷 | Français | |
| 🇩🇪 | Deutsch | |
| 🇮🇹 | Italiano | |

The app follows the watch system language automatically. Adding a language
is a single XML file — see [CONTRIBUTING.md](CONTRIBUTING.md).

## 🚀 Getting started (developers)

```bash
# 1. Connect IQ SDK + device files (needs a free Garmin account)
connect-iq-sdk-manager agreement view          # note the hash
connect-iq-sdk-manager agreement accept --agreement-hash <HASH>
connect-iq-sdk-manager login
connect-iq-sdk-manager sdk set 9.2.0
connect-iq-sdk-manager device download --include-fonts --manifest manifest.xml
export PATH="$(connect-iq-sdk-manager sdk current-path --bin):$PATH"

# 2. Build & test
make key        # one-time signing key
make build      # compile for the Forerunner 55 (DEVICE=fr955 make build, etc.)
make sim        # launch the simulator
make test       # run the unit-test suite on the simulator
monkeydo bin/Stretches-fr55.prg fr55   # run the app in the simulator
```

To try it on a real watch, copy `bin/Stretches-fr55.prg` into the
`GARMIN/Apps` folder of the watch over USB.

### Project layout

```
stretches/
├── manifest.xml             # app id, devices, permissions, languages
├── monkey.jungle            # build configuration
├── source/
│   ├── StretchesApp.mc      # app entry + background service
│   ├── model/               # catalog, storage, scheduling math
│   ├── engine/              # WorkoutEngine — pure, unit-tested state machine
│   ├── session/             # activity recording (FIT)
│   ├── ui/                  # views, menus, theme
│   └── tests/               # Run No Evil unit tests
├── resources*/              # launcher icon + per-language strings
├── assets/illus<size>/      # stretch illustrations, one PNG set per screen size
├── scripts/                 # illustration generator (Python + Pillow)
└── .github/workflows/       # CI (build + tests) and release packaging
```

### Quality gates

Every PR runs through CI:

| Gate | What it checks |
|---|---|
| 🧾 XML validation | Manifest and all resources parse |
| 🌐 String sync | Every language ships every string id |
| 🖼 Illustration coverage | Every catalog entry has an image in every size bucket |
| 🔎 Device API audit | Every Toybox symbol used exists on **all 80 target devices** |
| 🛠 Compile | Type-check level 2 across three screen shapes, zero errors |
| ✅ Tests | Unit + on-simulator integration suite (`make test`) |

The full strategy — including the on-device test pass that covers what
simulators can't — is documented in [docs/TESTING.md](docs/TESTING.md).

## 🤝 Contributing

Contributions are very welcome — new stretches, new languages, new devices,
bug fixes. Start with [CONTRIBUTING.md](CONTRIBUTING.md); adding a stretch
is a ~4-step change with a friendly checklist.

## 📦 Releasing

Tag `v*` → CI builds and attaches the store-ready `Stretches.iq` to a GitHub
release, ready to upload to the
[Connect IQ store dashboard](https://apps.garmin.com/developer/dashboard).
Ready-to-paste store copy lives in [docs/STORE_LISTING.md](docs/STORE_LISTING.md).

## 📄 License

[MIT](LICENSE) — free to use, modify and distribute. If this app keeps your
neck happy, a ⭐ on the repo makes ours happy too.
