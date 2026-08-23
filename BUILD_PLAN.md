# Hongyeon — Build Plan & Feature Spec (v2)

*A long-distance proximity app for two people. See how far apart you are and
which way to turn — glanceable on your wrist — without a battery-draining live map.*

This document supersedes the original PRD. It bakes in the architecture
corrections we worked through and locks the stack you chose. Paste it into a new
Claude session to start generating code phase by phase.

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
- Pair with your partner using a 6-digit code.
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

### Later (v2+ / portfolio flourishes)
- Swap polling for **WebSockets** for a genuinely live compass.
- iPhone home-screen widget (same data, bigger canvas).
- A lightweight **"thinking of you" nudge** (a tap that sends your partner a gentle ping).
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

4. **The arrow's rotation is computed on-device.**
   Direction needs the viewer's live compass heading (Core Location's heading),
   which only the device has. The server can compute distance; the watch owns the
   bearing math and combines it with live heading to rotate the arrow.

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
| `pairing_codes` | `code` (String), `creator_id` (UUID), `expires_at` | Temporary 6-digit codes to link two accounts |
| `location_states` | `user_id` (UUID, PK), `lat` (Float), `lng` (Float), `updated_at` | **Overwrites itself.** Only the current known location — no history |

Note the `auth_provider` / `provider_subject` fields so one account model cleanly
handles both Apple and Google identities.

---

## 5. Build Phases

The order deliberately front-loads the two riskiest, least-glamorous pieces —
background-location freshness and push delivery — so you find out in week two,
not week ten, whether the core loop can meet your bar.

### Phase 0 — De-risk the loop (skeleton only, no UI polish)
Prove: phone reports on significant-location-change → backend receives → silent
push wakes the partner → partner fetches fresh data. Measure how fresh you can
actually keep it on real devices. If this can't hit your bar, you want to know now.

### Phase 1 — Backend + pairing
FastAPI server, PostgreSQL, async SQLAlchemy models, Sign in with Apple **and**
Google token verification, 6-digit pairing endpoints. Deploy to Render early so
you're testing against a real URL, not localhost.

### Phase 2 — iOS location engine
Significant-location-change reporting, the permission onboarding screen
(explaining low-power reporting), and the POST-to-backend path.

### Phase 3 — APNs silent push fan-out
Apple Developer certificates/keys, the FastAPI logic that receives A's location
and fires a silent push to B. Treat delivery as best-effort throughout.

### Phase 4 — watchOS app + complication + math
The watch app, the WidgetKit complication ("N mi away · updated Xm ago"), the
haversine distance calc, and the on-device bearing + compass-heading arrow.

### Phase 5 — Live Activity + foreground live compass
The "you're close" Live Activity as the entry point; opening the watch app gives
the real-time foreground compass (polling every ~2–3s).

### Phase 6 — Polish & later work
WebSocket upgrade, iPhone widget, extra features, and App Store submission prep.

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

---

## 7. Auth Compliance Note (Guideline 4.8)

Apple no longer names "Sign in with Apple" as literally mandatory, but any app
offering a third-party login must also offer an equivalent service that limits
data to name + email, allows a private email, and doesn't track for ads. Google
Sign-In doesn't meet that bar; Sign in with Apple does. **Offering both from day
one** is the clean path to approval — and one small design rule: after a user
signs in with Apple, don't re-ask for their name or email (the framework already
provides them), or you'll trip a separate review rejection.

---

## Suggested Kickoff Prompt for the Next Session

> **Role:** Act as a Senior Backend and iOS Systems Engineer.
> **Context:** I'm building "Hongyeon," an Apple Watch + iPhone proximity app for
> couples. The build plan is attached. Stack: FastAPI, PostgreSQL (async
> SQLAlchemy), Sign in with Apple + Google, deployed on Render.
> **Task:** Start with **Phase 1: Backend + pairing**. No UI code yet.
> Generate: (1) the async SQLAlchemy models for `users`, `pairing_codes`, and
> `location_states`; (2) the async FastAPI routes to create a user (verifying
> both Apple and Google identity tokens), generate a pairing code, and link two
> users; (3) a Swift `NetworkManager` for those endpoints. Keep it
> production-ready and modular, and wait for my approval before Phase 2.