# App Store screenshots

Capture on **iPhone 16 Pro Max** Simulator (or required App Store device sizes).

## Full automated set

```bash
chmod +x scripts/capture-all-screenshots.sh
./scripts/capture-all-screenshots.sh
```

Produces:

| File | Screen |
|------|--------|
| `02-onboarding.png` | Month/day picker |
| `03-today.png` | Today tab |
| `04-birthmates.png` | Birthmates tab |
| `05-history.png` | History tab |
| `06-settings.png` | Settings |
| `07-circle.png` | Birthday Circle (preview) |
| `08-welcome.png` | Welcome quick tour sheet |

Optional env vars: `SCREENSHOT_MONTH`, `SCREENSHOT_DAY`, `SCREENSHOT_LOAD_WAIT` (default 12s for network).

## Single capture

```bash
./scripts/capture-app-store-screenshots.sh   # current Simulator screen
./scripts/verify-fresh-install.sh            # build + fresh install smoke test
```

Apple requires 6.7" and other sizes for App Store Connect — export at required dimensions before submit.
