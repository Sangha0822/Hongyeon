# Hongyeon — Build Plan & Feature Spec (v2)

*A long-distance proximity app for two people. See how far apart you are and
which way to turn — glanceable on your wrist — without a battery-draining live map.*

This document supersedes the original PRD. It bakes in the architecture
corrections we worked through and locks the stack you chose. It's a living
document — update it whenever a phase finishes or the plan changes.

**Status (November 2026):** Phases 0–5 complete. Next up: Phase 6 —
Onboarding flow.

---

## 1. The Locked Stack

| Layer | Choice | Why |
|---|---|---|
| Backend | **FastAPI (Python)**, self-built | Async fits an IO-bound event router; matches the backend skills you're building; it *is* the portfolio piece |
| Database | **PostgreSQL** + SQLAlchemy (async) | Modern standard; PostGIS available if you ever want geo queries in-DB |
| Auth | **Sign in with Apple + Google** | Google alone fails App Store review (Guideline 4.8); Apple is the required privacy-equivalent option |
| Hosting | **Render** (free tier now → paid as it grows) | Only major host with a real free tier; simple path to always-on ($7/mo) later |
| Foreground realtime | **Polling now → WebSocket later** | Ship fast with polling; WebSocket becomes a v2 talking point |
| Background wake | **APNs silent push** | The only way iOS lets you wake a backgrounded app — not a choice, a constraint |
| Clients | SwiftUI (iOS + watchOS), WidgetKit, ActivityKit | Native; complication is your differentiator |

**Rough running cost:** $0 to start on Render's free tier, ~$7/month once you
need an always-on backend (free instances sleep after 15 min). APNs, Sign in
with Apple, and Google sign-in are all free. Budget under ~$10/month.

---

## 2. What Hongyeon Can Do (Feature Spec)

### MVP (prove it works)
- Sign in with Apple **or** Google.
- Pair with your partner using a 6-character code.
- Your phone quietly reports its location in the background when you meaningfully move.
- A watch-face complication shows **"5 mi away · updated 12m ago."**
- Open the watch app to see a **live arrow** pointing toward your partner.

### v1.0 (App Store launch)
- Onboarding that clearly explains the location permission and the privacy model.
- **"You're close" moment:** when you're within ~1 mile, a Live Activity surfaces
  in the watch Smart Stack as a tap-to-find-each-other hook.
- Privacy controls: **pause sharing**, **unpair**, and a plain statement that only
  your *most recent* location is stored — never a history.
- Graceful "stale data" states ("last seen 3h ago") so the app never pretends to
  be more live than it is.

### Couple features (scheduled — Phases 6–9)
- **Onboarding flow:** display name, pairing, anniversary date (powering a
  "Day N together" counter) (Phase 6).
- A lightweight **"thinking of you" nudge** — a tap that sends your partner a
  visible push notification (Phase 7).
- A **shared diary** both partners can write in (Phase 8).
- A **shared photo wall**, photos hanging along a red thread (Phase 9).

### Later (v2+ / portfolio flourishes)
- Swap polling for **WebSockets** for a genuinely live compass (Phase 12).
- iPhone home-screen widget with a red-thread distance visual (Phase 12).
- Optional support for more than one linked person (family / close friends).

---

## 3. Architecture & Data Flow (the corrected model)

Four principles fix the soft spots in the original design:

1. **Movement trigger = significant-location-change, not geofence rings.**
   Registering radius "buckets" around yourself only tells you *you* moved — it
   says nothing about distance to your partner. Use Core Location's
   significant-location-change service to wake each phone when its owner moves;
   compute the actual distance from the two coordinate pairs.

2. **The server stores only the latest location per user, overwriting each time.**
   No history. This is both the privacy promise and the whole storage model.

3. **Silent push is a best-effort freshener, not the backbone.**
   iOS throttles and delays silent pushes at its own discretion. Design for
   "fresh within minutes," show timestamps, and never assume real-time delivery.

4. **Distance and direction are computed on-device.**
   The server only hands out the partner's latest coordinates. The device computes
   distance (CoreLocation's built-in `distance(from:)`) and bearing (our own math
   from both lat/lng pairs) — built and validated on iPhone in Phase 5. Direction
   also needs the viewer's live compass heading (Core Location's heading), which
   only the device has; the watch combines bearing with live heading to rotate
   the arrow.

### The loop, end to end
```
Partner A's phone moves
   → significant-location-change wakes the app in the background
   → app POSTs {lat, lng} to FastAPI
   → server overwrites A's row in location_states
   → server fires a silent push to B (best effort)
   → B's phone wakes, GETs A's latest location
   → B's watch complication updates: "N mi away · updated now"

When B opens the watch app AND they're close:
   → watch polls partner location every ~2–3s (foreground)
   → watch reads live compass heading
   → arrow = bearing(B→A) − device heading, redrawn each update
```

---

## 4. Database Schema (SQLAlchemy)

| Table | Columns | Purpose |
|---|---|---|
| `users` | `id` (UUID), `auth_provider` (apple/google), `provider_subject`, `email`, `partner_id` (UUID, nullable), `apns_token` | Account + the device token needed to route silent pushes |
| `pairing_codes` | `code` (String), `creator_id` (UUID), `expires_at` | Temporary 6-character codes to link two accounts |
| `location_states` | `user_id` (UUID, PK), `lat` (Float), `lng` (Float), `updated_at` | **Overwrites itself.** Only the current known location — no history |

Note the `auth_provider` / `provider_subject` fields so one account model cleanly
handles both Apple and Google identities.

**Planned additions** (exact columns decided when each phase starts):
- Phase 6 — a display name per user, and one anniversary date per couple
  (the code creator's date wins; the joiner's is used if the creator skipped).
- Phase 8 — a diary entries table.
- Phase 9 — a photos table, plus image storage outside PostgreSQL.

---

## 5. Build Phases

The order deliberately front-loads the two riskiest, least-glamorous pieces —
background-location freshness and push delivery — so you find out in week two,
not week ten, whether the core loop can meet your bar.

✅ = complete.

### Phase 0 — De-risk the loop (skeleton only, no UI polish) ✅
Prove: phone reports on significant-location-change → backend receives → silent
push wakes the partner → partner fetches fresh data. Measure how fresh you can
actually keep it on real devices. If this can't hit your bar, you want to know now.

### Phase 1 — Backend + pairing ✅
FastAPI server, PostgreSQL, async SQLAlchemy models, Sign in with Apple **and**
Google token verification, 6-character pairing endpoints. Deploy to Render early so
you're testing against a real URL, not localhost.

### Phase 2 — iOS location engine ✅
Significant-location-change reporting, the permission onboarding screen
(explaining low-power reporting), and the POST-to-backend path.

### Phase 3 — APNs silent push fan-out ✅
Apple Developer certificates/keys, the FastAPI logic that receives A's location
and fires a silent push to B. Treat delivery as best-effort throughout.

### Phase 4 — UI & navigation design ✅
Replace the debug-button pile in ContentView with real screens and real
navigation across sign-in, pairing, and the main app. Decide what happens to
the existing test tooling (hidden dev menu, or removed). Deliberately placed
here, before the watchOS app, so both platforms build on a clean foundation
together rather than compounding more debug UI across later phases.

### Phase 5 — Distance & direction on iPhone ✅
Real distance between partners (CoreLocation's built-in calculation) and
on-device bearing math (not provided by CoreLocation - computed from both
partners' lat/lng) shown together on the home screen as an animated arrow
and a distance, with the "last active" time kept underneath. Validates the core proximity math and UX on a platform
we already have full command of, before porting it to watchOS.

### Phase 6 — Onboarding flow
A real first-launch flow that collects a display name and the relationship's
anniversary date - powers a "Day N together" counter and lets the app refer to
partners by name instead of generically. A near-universal pattern in this app
category, especially in Korean couple-app culture, which fits Hongyeon's own
theme directly.

The flow (new user) — diagram: `docs/images/onboarding-flow.svg`:
1. **Welcome** — "Get started" for new users, "I already have an account" goes
   straight to sign-in in its "Welcome back" mode.
2. **What should we call you?** — one display name, the name your partner sees
   everywhere. Asked *before* sign-in and held on the phone until sign-in
   finishes. No separate legal name or partner nickname: one name per person
   keeps the couple's account consistent.
3. **When did your story begin?** — optional anniversary, also held as a draft.
   Asked early so onboarding opens with personal questions instead of jumping
   straight to an account wall.
4. **Save your story** — Sign in with Apple (requests email only, so the name
   is never re-asked — see Section 7) or Google. The draft name and date are
   saved to the account.
5. **Connect with your partner** — "Share my code" (create → share → waiting,
   updates automatically when the partner joins) or "I have a code" (enter →
   join). Pairing is required: there is no unpaired home screen.
6. **You're connected!** — shows both partners' names. The couple's anniversary
   is settled here: the code creator's date wins; if they skipped it, the
   joiner's date is used.
7. **Enable location sharing** — explain privacy, then one button that always
   opens the system prompt ("While Using" first, "Always" later). No "Not now"
   on our own screen; a denial is handled calmly and Home shows a location-off
   state with an Open Settings button.
8. **Welcome home** — a one-time welcome on first setup, then Home.

Returning users sign in and skip setup, but are routed back into the steps
they're missing: not paired → step 5; no name (an account without one) → the
name screen with "missing name" wording; location permission never asked
(e.g. after a reinstall) → step 7. Unpairing (either partner) also returns to
step 5.

Design source: a Figma Make prototype, used as a visual reference only — the
app trims its copy and the flow above wins where they differ.

### Phase 7 — Tap-to-notify "thinking of you"
A tap on the home screen sends the partner a real, visible push
notification - the first visible (non-silent) push in the project,
distinct from every prior background/silent push.

### Phase 8 — Shared diary
A shared notes/diary page where both partners can write to each other -
a new backend data model, real CRUD endpoints, and a real read/write UI.

### Phase 9 — Shared photo wall
Partners post photos to each other, displayed hanging along a red-thread
visual (clothespin-style) - a literal nod to Hongyeon's own meaning.
Needs real new infrastructure this project hasn't touched yet: image
upload and storage.

### Phase 10 — watchOS app + complication
The watch app and the WidgetKit complication ("N mi away · updated Xm
ago"), reusing the distance/bearing math already validated in Phase 5,
plus the on-device compass-heading arrow.

### Phase 11 — Live Activity + foreground live compass
The "you're close" Live Activity as the entry point; opening the watch app gives
the real-time foreground compass (polling every ~2–3s).

### Phase 12 — Polish & later work
WebSocket upgrade, an iPhone home screen widget (showing distance via a
red-thread visual that changes based on how close/far apart the partners
are), extra features, and App Store submission prep.

### Beyond Phase 12 — Hongyeon as a couple app, not just a location app

A pure "where's my partner" app has a real ceiling: it's inherently passive,
with little to actually *do* day-to-day beyond glancing at a distance. The
long-term direction is for location/proximity to be Hongyeon's **anchor**
feature, not its only one — expanding later into things like a couple
nickname, streaks, or a shared calendar, similar to how most successful
long-distance-couple apps evolve.

This is explicitly a **future direction, not current scope** — nothing
here changes the priority of Phases 0–12 above. Location has to fully ship
first. Revisit once the core proximity loop is live and stable, not before.

### Backlog — ideas not yet assigned to a phase
Tracked as GitHub issues so they don't get lost:
- Request "Always" location permission in the real onboarding flow (#116)
- Hide the dev menu behind `#if DEBUG` before App Store submission (#117)
- QR code scan-to-pair (#106)
- Metric vs. imperial setting for distance (#123)
- Couple nickname / shared team name (#126)
- Replace the direction arrow with a custom red-thread illustration (#128)
- **Pause sharing** — promised in the v1.0 feature spec, but no phase or
  issue builds it yet
- **Email sign-in with a one-time code** — postponed from Phase 6, to become
  its own phase. Works like pairing codes: backend stores a 6-digit code with
  an expiry, emails it, verifies it, then mints the normal session JWT. Needs:
  an email-sending service (free tiers exist, e.g. Resend or Brevo), a custom
  domain (~$10–15/year) with DNS records so emails don't land in spam, and
  security limits (max ~5 guesses per code, rate-limited sending, one-time use).
  Open question: same email via Apple and via email — one account or two?

---

## 6. Risks to Watch (and where they bite)

- **Background location freshness** — the watch is poor at background location; the
  iPhone is the broadcaster for a reason. Verify freshness on physical devices early.
- **Silent push timing** — throttled by iOS; never the backbone of "live."
- **APNs setup** — certificates/keys are famously fiddly; budget time for Phase 3.
- **App Store review** — expect scrutiny on (a) location consent and clear
  mutual opt-in, (b) Guideline 4.8 requiring Sign in with Apple alongside Google,
  and (c) accurate privacy "nutrition label" disclosures. First submissions are
  often rejected once — plan for a revision cycle.
- **Asking for a name in Phase 6** — Section 7's rule says not to re-ask Sign in
  with Apple users for the name Apple already provided. Resolved by asking the
  name *before* sign-in and requesting only the email scope from Apple.
- **Permission pre-prompt wording** — a custom screen before the system location
  prompt must lead straight into it (one "Continue" button). A "Not now" button
  on our own screen is a common App Review rejection.
- **Photo storage (Phase 9)** — the first feature that stores user files, not
  just rows. Adds a new service, a new cost to the budget, and a new privacy
  disclosure.

---

## 7. Auth Compliance Note (Guideline 4.8)

Apple no longer names "Sign in with Apple" as literally mandatory, but any app
offering a third-party login must also offer an equivalent service that limits
data to name + email, allows a private email, and doesn't track for ads. Google
Sign-In doesn't meet that bar; Sign in with Apple does. **Offering both from day
one** is the clean path to approval — and one small design rule: after a user
signs in with Apple, don't re-ask for their name or email (the framework already
provides them), or you'll trip a separate review rejection.
