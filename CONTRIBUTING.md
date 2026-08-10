# Contributing to Stretches

Thanks for your interest! This project is intentionally friendly to
first-time Connect IQ contributors. If anything in this guide does not work
for you, open an issue — fixing the developer experience is a contribution
too.

## Getting set up

1. **Install the Connect IQ SDK** (pick one):
   - [Official SDK Manager](https://developer.garmin.com/connect-iq/sdk/) (GUI), or
   - [`connect-iq-sdk-manager-cli`](https://github.com/lindell/connect-iq-sdk-manager-cli):

     ```bash
     connect-iq-sdk-manager agreement view   # read & note the hash
     connect-iq-sdk-manager agreement accept --agreement-hash <HASH>
     connect-iq-sdk-manager login            # your Garmin account
     connect-iq-sdk-manager sdk set 9.2.0
     connect-iq-sdk-manager device download --include-fonts --manifest manifest.xml
     export PATH="$(connect-iq-sdk-manager sdk current-path --bin):$PATH"
     ```

2. **Create a signing key** (once): `make key`
3. **Build**: `make build` (defaults to `DEVICE=fr55`)
4. **Run tests**: `make sim` (starts the simulator), then `make test`
5. **Try the app**: `make sim`, then
   `monkeydo bin/Stretches-fr55.prg fr55`

Python 3 with Pillow is needed only if you touch the illustrations:
`pip install pillow`, then `make illustrations`.

## Project layout

| Path | What lives there |
|---|---|
| `source/model/` | Catalog, persisted state (`Prefs`), scheduling math |
| `source/engine/` | `WorkoutEngine` — the pure workout state machine |
| `source/session/` | Activity recording (FIT session, laps, custom fields) |
| `source/ui/` | Views, delegates, menus, theme |
| `source/tests/` | Unit tests (`(:test)` functions, Run No Evil) |
| `resources*/` | Drawables and per-language strings |
| `scripts/` | Illustration generator (Python + Pillow) |

## Adding a new stretch

1. Add a pose function and a `CATALOG` entry in
   `scripts/generate_illustrations.py`, then run `make illustrations`.
2. Add the entry to `StretchCatalog.entries()` (id, name, image, group).
3. Add the name string `s_<id>` to **every** `strings.xml`
   (English + por/spa/fre/deu/ita — machine translation is acceptable for a
   first pass, native review is welcome).
4. Update the expected catalog count in `tests/CatalogTest.mc`.
5. `make test`.

## Adding a new language

1. Create `resources-<code>/strings/strings.xml` (ISO 639-2 code, e.g.
   `resources-jpn`) with every id from `resources/strings/strings.xml`.
2. Add `<iq:language><code></iq:language>` to `manifest.xml`.
3. The CI string-sync check will confirm nothing is missing.

## Quality gates

Every PR must pass CI:

- XML validity + string catalogs in sync across languages
- Illustration coverage for every catalog entry
- Device API audit: every Toybox symbol used must exist on all target
  devices (`python3 scripts/audit_api_usage.py`)
- Clean compile at type-check level 2 with warnings enabled
- All unit + integration tests green on the simulator (`make test`)

See [docs/TESTING.md](docs/TESTING.md) for the full strategy, including the
manual on-device pass required before releases.

## Conventions

- **English everywhere**: code, comments, commits, PRs and docs.
- Keep the engine (`WorkoutEngine`, `Scheduler`) free of Toybox UI/time
  dependencies — that is what keeps it unit-testable.
- User-visible text always comes from string resources, never literals.
- Colors must survive the 64-color MIP palette (channels in steps of
  `0x55`); see `Theme.mc`.
- Commit messages: short imperative subject, e.g.
  `Add seated spinal twist stretch`.

## Releasing (maintainers)

1. Update `AboutText` version strings and `CHANGELOG.md`.
2. Tag: `git tag v1.x.y && git push --tags` — CI attaches `Stretches.iq`
   to the GitHub release.
3. Upload the `.iq` to the
   [Connect IQ developer dashboard](https://apps.garmin.com/developer/dashboard).
