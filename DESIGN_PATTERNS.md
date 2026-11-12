# Birthmate design patterns (v1)

Companion to [APP_STORE.md](APP_STORE.md) and [PRODUCT_ROADMAP.md](PRODUCT_ROADMAP.md).

**North star:** Warm, native iOS **daily magazine for one date** — faces and surprises first, lists for depth, share for growth.

---

## Category position

| Do | Don't (v1) |
|----|------------|
| Famous birthmates + history for **month/day** | Horoscope, zodiac, age gates |
| Wikipedia / Wikidata as source | Imply “real people” unless Circle ships |
| No account to get value | Sign in before first highlight |
| Share cards as viral unit | Social feed tab in marketing |

---

## Information architecture

```
Onboarding (once) → Tab hub
  Today      → habit + shuffle
  Birthmates → volume + search + favorites
  On This Day→ history + filters
  Settings   → date, reminders, trust
```

**Cross-tab rule:** Every main feed uses **BirthdayBanner** so users see **calendar today** vs **your birth date** (not confused with “Today” the tab name).

---

## Visual system (`BirthmateTheme`)

| Token | Use |
|-------|-----|
| Coral-rose `accent` | Tab tint, CTAs, section labels, born-year highlight |
| `cream` + grouped background | Warm neutrals, stats strip |
| `heroCardBackground()` | Today featured person/event |
| `cardBackground()` | Standard rows and explore CTA |
| `onboardingGradient` | First-run only |

**Typography:** One bold headline per screen; body in `.secondary` for support copy. Avoid third accent colors.

**Imagery:** Prefer **photos on heroes** (Today, App Store). Placeholder silhouette is acceptable in lists; heroes should not ship empty in marketing screenshots.

---

## Screen patterns

### Onboarding

1. **Hook** — logo + “Who shares your birthday?”
2. **Input** — month/day wheels only (no year)
3. **Proof** — live preview: one face + count + one history line
4. **One CTA** — “Discover my day”

Pattern: *show payoff before commit* (preview before save).

### Today

1. **BirthdayBanner**
2. Time-based greeting + one-line instruction (shuffle / pull to refresh)
3. Two **hero** cards (birthmate + history) with “Another”
4. Story stat (count + date in prose)
5. Single explore row → Birthmates tab
6. Relative “Updated …” only (no footer attribution on this tab)

Pattern: *maximum two taps to depth* (hero → detail, or explore → list).

### Birthmates / On This Day

1. **BirthdayBanner**
2. One **story** line with bold counts (not badge-only stats)
3. Search + segmented filter
4. Era or type sections with short subtitles
5. Pull to refresh; error + empty states via shared `FeedStateViews`

### Detail + share

- Photo, name, year, extract, favorite, **ShareLink** / card
- Share is the **growth surface** — keep primary actions visible, not buried in menus.

### Settings

- Birthday summary (read-only display)
- Notifications toggle + time picker
- Destructive **Change Birthday** in its own section (not under Notifications)
- Wikipedia/Wikidata attribution (legal + trust)

---

## Interaction patterns

| Pattern | Implementation |
|---------|----------------|
| Deferred notification prompt | Day 2+, after content loads (`AppLaunchStore`) |
| Shuffle without losing date | “Another” on Today heroes only |
| Favorites | Per-device; filter tab on Birthmates |
| Offline / error | `FeedErrorView` + refreshable |
| No welcome tour on launch | v1 — onboarding is the only first-run story |

---

## App Store creative (6.7")

Order matches emotional story in [APP_STORE.md](APP_STORE.md):

1. **03-today** — face + history (hook)
2. **04-birthmates** — scale (“237 on your day”)
3. **05-history** — depth
4. Share frame (capture from detail when needed)
5. **02-onboarding** — trust + date picker preview

Do not use stale `07-circle`, `08-welcome`, or `01-current-screen` in Connect.

---

## Post-v1 design investments (in order)

1. **Share deep link** — pre-fill date on install (roadmap #1 growth)
2. **Widget** — birthmate or “on this day” glance
3. **Circle** — separate visual language; never mix with Wikipedia birthmates without labels

---

## Research note (ScreensDesign)

Recorded competitor UI research via [ScreensDesign](https://screensdesign.com) requires an **active Pro** subscription on the connected account. Free OAuth access does not run `search_market_apps` / flows. After upgrading, re-run onboarding and paywall-free competitor scans against this checklist.

---

## Design review checklist (before submit)

- [ ] BirthdayBanner on Today, Birthmates, On This Day
- [ ] Onboarding preview loads for a fixed test date (e.g. Jul 29)
- [ ] Today heroes show photos when network is available
- [ ] Share card includes app/date branding
- [ ] Settings: notification toggle + single Change Birthday
- [ ] Screenshots match current tab bar (4 tabs, no Circle)
