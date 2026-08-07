# App Store screenshots

Capture on **iPhone 16 Pro Max** Simulator (or required App Store device sizes).

## Full automated set

```bash
./scripts/capture-all-screenshots.sh
```

Produces:

| File | Screen |
|------|--------|
| `02-onboarding.png` | Date picker with live preview |
| `03-today.png` | Today tab |
| `04-birthmates.png` | Birthmates tab |
| `05-history.png` | On This Day tab |
| `06-settings.png` | Settings |

Optional env vars: `SCREENSHOT_MONTH`, `SCREENSHOT_DAY`, `SCREENSHOT_LOAD_WAIT` (default 12s for network).

## Single capture

```bash
./scripts/capture-app-store-screenshots.sh   # current Simulator screen
./scripts/verify-fresh-install.sh            # build + fresh install smoke test
```

Apple requires 6.7" and other sizes for App Store Connect — export at required dimensions before submit.
