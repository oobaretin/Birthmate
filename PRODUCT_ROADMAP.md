# Birthmate product roadmap

**Last updated:** August 4, 2026  
**Status:** Paused until Apple Developer Program enrollment  
**Related:** [V1_SCOPE.md](V1_SCOPE.md) · [APP_STORE.md](APP_STORE.md)

---

## Hero job (one sentence)

> **Help people answer: “Who shares my birthday?” — and discover what their day means in history.**

Everything else supports that job. Birthmates = identity. On This Day = meaning. Circle = belonging (later, optional).

---

## Positioning

| | v1 (ship first) | v2+ (earn the right) |
|---|-----------------|----------------------|
| **Promise** | Famous birthmates + history for your date | Real people on your day (Circle) |
| **Content** | Wikipedia + Wikidata | Supabase + Sign in with Apple |
| **Habit** | Today + daily reminder + share cards | Widget + deep links + birthday week |
| **Do not lead with** | Circle, auth, social | — |

**Language split (when Circle ships):**

- **Birthmates** — famous people born on your day (Wikipedia)
- **Day twins / Circle** — real people who opt in (never mix without clear labels)

---

## Growth loop (highest leverage)

```
Pick date → surprise birthmate → share card → friend installs → same date pre-filled
```

| Step | Today | Target |
|------|-------|--------|
| Share outbound | ✅ Share card on detail | Keep optimizing card + CTA |
| Inbound install | ❌ | Universal link / deep link with month+day |
| Pre-filled onboarding | ❌ | `birthmate://` or `https://` link opens app on date |

**Product priority after Developer signup:** inbound share loop before new tabs or Circle density work.

---

## Success metrics (TestFlight → App Store)

Track these before scaling features:

| Metric | Why |
|--------|-----|
| Onboarding completion | Date picker + preview converting |
| D1 / D7 retention | Is Today enough to return? |
| Share rate per session | Viral loop working? |
| Favorites per user | Depth beyond browse |
| Notification opt-in | Habit potential |

Downloads alone do not validate the concept.

---

## Phased roadmap

### Phase 1 — Ship & learn (now → first TestFlight)

**Goal:** Personal discovery app, no social story in marketing.

- [x] Core: Today, Birthmates, On This Day, favorites, share
- [x] Onboarding live preview + notification prompt
- [x] Screenshots + privacy policy URL
- [ ] Apple Developer enrollment
- [ ] Real device smoke test
- [ ] TestFlight to 10–20 friends
- [ ] Review metrics above for 2–4 weeks

**Ship without:** Circle in App Store copy, live auth, paid features.

---

### Phase 2 — Habit (if retention needs help)

**Goal:** Daily ritual without opening the app.

| Feature | Notes |
|---------|--------|
| Home screen widget | App Groups + entitlements; show birthmate or count |
| Notification deep link | Tap reminder → Today featured card |
| Birthday week mode | Push + UI spike when `month/day == today` |
| Sharper share loop | Deep link with date in URL |

---

### Phase 3 — Social (only if Phase 1–2 show engagement)

**Goal:** Real people on your day — opt-in, not onboarding default.

- Enable Sign in with Apple + Supabase Apple provider
- Flip `BirthmateSecrets.appleSignInEnabled = true`
- Circle as tab or prominent entry (only when live)
- Gate behind 3+ sessions or explicit “Join Circle” — not first launch

**Risk:** Sparse density per day; famous birthmates already satisfy “who shares my birthday” for most users.

---

### Phase 4 — Expand (optional)

- Multiple dates (kid, partner) — natural monetization hook
- Locale / non-English Wikipedia
- Apple Watch glance
- Premium: ad-free, extra dates, compare-with-friend

---

## v1 App Store narrative

**Subtitle (≤30 chars):**  
`Who shares your birthday?`

**One-line description lead:**  
Birthmate shows you famous people born on your day and what happened in history — personalized to your birthday, not a generic feed.

**Do not mention in v1 listing:** Birthday Circle, preview mode, Sign in with Apple.

See [APP_STORE.md](APP_STORE.md) for full copy drafts.

---

## Monetization (future — design now, bill later)

| Free | Possible paid |
|------|----------------|
| One birth date (month/day) | Multiple dates |
| Today, browse, favorites, share | Year insights, compare friend |
| Local reminders | Ad-free |

No paywall in v1. Avoid building auth/backend cost before retention is proven.

---

## When you resume (Developer account checklist)

1. Enroll → create App ID `com.birthmate.app`
2. TestFlight internal build → dogfood + 10 friends
3. Finalize App Store listing from `APP_STORE.md` (v1 copy only)
4. Submit v1 **without** live Circle
5. Measure Phase 1 metrics → decide Phase 2 vs Phase 3

---

## Decisions locked in

- **Month/day only** — birth year never uploaded (privacy + simplicity)
- **Option A launch** — core first; Circle later ([V1_SCOPE.md](V1_SCOPE.md))
- **Honest labeling** — preview/demo never pretends to be live social
- **Pause until paid account** — correct; no $99 until ready to TestFlight within ~1 week
