# App Store listing notes

Use this when preparing App Store Connect for **v1** (personal discovery — no Circle in copy).

**Product strategy:** [PRODUCT_ROADMAP.md](PRODUCT_ROADMAP.md)

---

## Subtitle (30 characters max)

**Recommended:** `Who shares your birthday?` (26 chars)

Alternates:
- Famous birthdays on your day (28)
- Your day in history (19)

---

## Promotional text (170 chars, updatable without review)

See who shares your birthday — and explore history on your day. Daily highlights, hundreds of birthmates, and favorites. No account required.

---

## Description (lead paragraph)

Birthmate answers a simple question: **who shares your birthday?**

Pick your month and day — no birth year needed — and explore famous birthmates, historical events, and “on this day” moments from Wikipedia, all personalized to **your** date.

**What you can do:**
- Get daily highlights on the Today tab — a featured birthmate and history moment
- Browse everyone born on your birthday, with photos and bios
- Explore what happened on your day across history
- Save favorites and share branded cards with friends
- Optional daily reminder to discover something new

Birthmate uses public data from Wikipedia and Wikidata. Your birth year is never collected.

---

## Keywords (100 chars, comma-separated)

```
birthday,birthmates,famous birthdays,on this day,history,who shares my birthday,Wikipedia
```

---

## Screenshot story (emotional order)

Lead with identity, not chrome:

1. **Hook** — “Who shares your birthday?” + one famous face (Today hero)
2. **Proof** — Birthmates list with count (“847 on July 29”)
3. **Depth** — On This Day history moment
4. **Action** — Share card preview
5. **Trust** — Onboarding date picker with live preview

Assets: `./scripts/capture-all-screenshots.sh` → `AppStoreScreenshots/`

---

## v1 — do not include in listing

- Birthday Circle / community / social
- Sign in with Apple
- “Preview mode” or backend features

Add Circle to marketing only when live (Phase 3 in roadmap).

---

## Before submit checklist

- [ ] Subtitle and description finalized in App Store Connect
- [ ] Screenshots for required device sizes (6.7", etc.)
- [ ] Privacy policy URL — **https://oobaretin.github.io/Birthmate/**
- [ ] App preview video (optional, 15–20s: pick date → face → share)
- [ ] `Info.plist` production Supabase keys configured locally (never commit secrets)
- [ ] Fresh install: onboarding → welcome → Today → share flow
- [ ] TestFlight feedback pass (10+ testers)

---

## Support & contact

Use GitHub Issues URL or support email in App Store Connect — match [docs/PRIVACY.md](docs/PRIVACY.md).
