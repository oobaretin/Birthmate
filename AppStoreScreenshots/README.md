# App Store screenshots

Capture on **iPhone 16 Pro Max** Simulator (or required App Store device sizes).

## Automated

```bash
./scripts/verify-fresh-install.sh          # fresh install → onboarding
./scripts/capture-app-store-screenshots.sh # saves current screen
```

## Manual set (navigate in Simulator, run capture script after each)

| File | Screen |
|------|--------|
| `01-current-screen.png` | Onboarding (auto after fresh install) |
| `02-today.png` | Today tab |
| `03-birthmates.png` | Birthmates tab |
| `04-history.png` | History tab |
| `05-settings.png` | Settings (optional) |
| `06-welcome.png` | Welcome sheet (delete app or reset `birthmate_has_seen_welcome_tips`) |

Apple requires 6.7" and other sizes for App Store Connect — export at required dimensions before submit.
