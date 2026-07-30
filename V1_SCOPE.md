# Birthmate v1.0 scope

Use this to decide what to finish **before** vs **after** Apple Developer Program ($99/year).

**Last reviewed:** 2026-07-30  
**Tests:** 11/11 passing (`WikiFormattingTests`)  
**Supabase:** configured in local `Info.plist` (do not commit keys)

---

## v1.0 — ship without paid Apple account (core app)

These features work on Simulator and free Personal Team today.

| Feature | Tab | Status | Notes |
|---------|-----|--------|-------|
| Pick birth month & day | Onboarding | ✅ Done | Defaults to today; live date preview |
| Welcome quick tour | Sheet | ✅ Done | Shows after first launch |
| Today highlights | Today | ✅ Done | Featured birthmate + history; shuffle |
| Birthmates list | Birthmates | ✅ Done | Wikipedia + Wikidata merge, favorites |
| History timeline | History | ✅ Done | Events, highlights, deaths (leaf icon) |
| Search & filters | History / Birthmates | ✅ Done | Era sections, living/historical/favorites |
| Share card | Detail | ✅ Done | ShareLink with branded card |
| Settings | Settings | ✅ Done | Change birthday, notifications toggle |
| New logo | Assets | ✅ Done | AppLogo, AppIcon, LaunchIcon |
| Crash fix (merge) | Data | ✅ Done | `OnThisDayMerger` recursion fixed |

### Pre–Apple Developer checklist (you)

- [x] **Fresh-install test** — `./scripts/verify-fresh-install.sh` (PASS 2026-07-30)
- [ ] **Network edge cases** — airplane mode, slow Wi‑Fi, pull-to-refresh recovery (manual in Simulator)
- [x] **Multiple birth dates** — Settings → Change Birthday clears date and returns to onboarding (code verified)
- [x] **Screenshots** — onboarding captured in `AppStoreScreenshots/`; complete remaining tabs manually
- [ ] **App icon 1024×1024** — export native resolution (current icon upscaled from 500px)
- [x] **Privacy policy** — draft in `docs/PRIVACY.md` (host publicly and add URL to App Store Connect)
- [ ] **Commit local changes** — run commit excluding `Info.plist` secrets
- [ ] **Real device test** (optional) — free Apple ID, 7-day install on your iPhone

---

## v1.1 — requires Apple Developer Program

Blocked or unreliable until paid membership.

| Feature | Blocked by | Action after signup |
|---------|------------|---------------------|
| **App Store / TestFlight** | Paid account | Enroll, create App Store Connect app |
| **Sign in with Apple** | Capability + provisioning | Set `appleSignInEnabled = true` in `BirthmateSecrets.swift`; add capability in Xcode |
| **Live Birthday Circle** | Sign in with Apple + Supabase Apple provider | Configure Apple in Supabase Dashboard + Developer portal |
| **App Groups (widget sync)** | Entitlements | Re-enable shared container; widget reads live birth count |
| **Remote push notifications** | APNs certs | Optional; local reminders may work on device |

### Post-enrollment checklist

- [ ] Enroll at [developer.apple.com](https://developer.apple.com/programs/)
- [ ] Create App ID `com.birthmate.app` with Sign in with Apple + App Groups
- [ ] Enable Apple provider in Supabase → Authentication
- [ ] Flip `BirthmateSecrets.appleSignInEnabled` to `true`
- [ ] Test Circle on **real device** (Sign in with Apple is unreliable in Simulator)
- [ ] TestFlight internal beta → fix feedback → App Store submit

---

## Recommended launch strategy

### Option A — Ship core first (recommended)

**v1.0:** Birthmates + History + Today (no live Circle). Circle tab stays in **preview/demo mode** with honest copy (already in app).

**Pros:** Ship sooner; core value is strong; no auth complexity on day one.  
**Cons:** Circle is demo-only until v1.1.

### Option B — Wait for full Circle

Hold App Store submit until Sign in with Apple + Supabase + App Groups all work.

**Pros:** One launch with community.  
**Cons:** Delays release; depends on $99 + backend + device testing.

---

## Current uncommitted work (local only)

These changes exist on disk but are not on `origin/main` yet:

- Merge crash fix, Today count fix, welcome `@AppStorage`
- Death leaf indicators, logo + `AppLogoView`
- New assets (AppIcon, AppLogo, LaunchIcon)
- `APP_STORE.md`, `V1_SCOPE.md` (this file)

**Never commit:** `Birthmate/Resources/Info.plist` if it contains Supabase keys (use env-specific config or `.gitignore` + template).

---

## Quick commands

```bash
# Run tests
xcodebuild test -scheme Birthmate -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max'

# Build & run (Simulator)
xcodebuild -scheme Birthmate -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' build

# Supabase setup (if resetting backend)
./scripts/setup-supabase-cloud.sh
```

---

## When to pay for Apple Developer

Pay when **all** of these are true:

1. Core app checklist above is done and you’re happy with polish  
2. Screenshots + description + privacy policy are ready  
3. You’re ready to test on a real iPhone within ~1 week  
4. You want TestFlight or App Store (or live Sign in with Apple)

Until then, keep building and testing on Simulator for free.
