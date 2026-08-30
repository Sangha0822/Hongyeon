# Hongyeon — Learning Log

A running record of concepts I asked about while building this, and the
reasoning behind them. Updated as we go through each phase.

---

## Phase 0 — De-risk the core loop

### Architecture: is significant-location-change the right call?

**Q: Is there a better way to do the location fetching than what the build plan proposes?**

Significant-location-change (SLC) is genuinely the right primitive, not a
compromise. Continuous background updates drain battery and draw App Store
scrutiny; geofencing only tells you when *you* cross a line, not distance
to your partner; the Visits API is too laggy. SLC + best-effort silent
push is the standard pattern for battery-friendly background proximity
apps.

---

### Issue #1 — Bare FastAPI server (health check)

**Virtual environments**

A virtual environment (venv) is a self-contained folder holding just one
project's Python packages, isolated from the system-wide Python and from
other projects.

```bash
python3.12 -m venv venv
source venv/bin/activate
```

Without it, `pip install` pollutes the system Python, which can break
other tools or require sudo.

**GET vs POST, and why 404s aren't always errors**

Hitting `/` or `/favicon.ico` in a browser returns 404 because no route
was defined for those paths — that's FastAPI correctly saying "nothing
here," not a bug. Only routes you explicitly define (like `/health`) will
respond.

---

### Issue #2 — Location POST/GET endpoints (in-memory store)

**POST endpoints and Pydantic models**

POST is for the client *sending* data (vs. GET, which only requests it).
Pydantic models describe the expected shape of that data as a Python
class; FastAPI validates incoming JSON against it automatically before
your function even runs — no manual parsing/validation code needed.

**Understanding check: what happens on restart?**

*Q: If the server restarts, what happens to data stored in a plain Python variable?*

Answer (confirmed correct): it's gone. A plain variable only lives in the
server process's RAM — restart, crash, or redeploy wipes it. This is
exactly the limitation issues #3–5 exist to fix, by moving storage into
Postgres, which persists to disk.

---

### Issue #3 — Local PostgreSQL + async SQLAlchemy connection

**Choosing a local Postgres setup**

Installed Postgres 16 natively via Homebrew (`brew services start
postgresql@16`) rather than running it in Docker. Docker is closer to how
many teams run it and easier to reset, but would have introduced
container concepts not otherwise part of this build plan. Kept it simple.

**async def / await**

*Q: Does `async def` mean the function can work on other things while waiting for data?*

Refined: not quite the function itself — it's the *server* (uvicorn) that
can go handle *other incoming requests* while this one waits. Analogy: a
waiter who puts in your order then goes to take another table's order,
instead of standing at the kitchen window doing nothing until your food's
ready.

Also: it's not optional once a function needs `await` inside it — `await`
is illegal syntax inside a plain `def`, so `async def` becomes mandatory
the moment you need it.

**.env files and secrets**

`DATABASE_URL` (and later, real secrets like API keys) never get
hardcoded into source files. They live in `.env`, which is gitignored,
and get loaded into the environment at runtime via `python-dotenv`.

---

### Issue #4 — location_states model + Alembic migration

**SQLAlchemy vs. Alembic**

*Q: Is SQLAlchemy just what translates Python into SQL to create tables instead of writing CREATE TABLE by hand?*

Refined: SQLAlchemy's job is broader — it translates Python ↔ SQL for
*all* database operations (queries, inserts, updates), not just table
creation; e.g. `conn.execute(text("SELECT 1"))` back in issue #3 was
already SQLAlchemy at work. The specific "generate CREATE TABLE" job
belongs to **Alembic**, which compares a SQLAlchemy model against the
database's actual current state and writes a versioned migration script
recording the difference — giving a reproducible, rollback-able history
instead of one-off manual schema changes.

**Declarative models**

A "declarative model" is a Python class where each attribute becomes a
database column; SQLAlchemy reads the class definition to know how to
generate matching SQL. Used the modern SQLAlchemy 2.0 style
(`Mapped[...]` / `mapped_column(...)`) since this project started fresh
with a current SQLAlchemy version.

---

### Issue #5 — Swap in-memory store for real Postgres reads/writes

**Timezone-aware vs. naive timestamps**

A model column declared as plain `DateTime` maps to Postgres's
`TIMESTAMP WITHOUT TIME ZONE` — a "naive" type with no concept of
timezone. Trying to insert a timezone-*aware* Python value
(`datetime.now(timezone.utc)`) into it fails, because Postgres won't
silently guess whether that offset should be kept or dropped.

Fixed by declaring `DateTime(timezone=True)` instead (→ `TIMESTAMP WITH
TIME ZONE`), rather than just stripping the timezone off the Python
value. Reasoning: with a naive column, nothing stops a future write from
accidentally inserting a *local* time instead of UTC — Postgres can't
tell the difference. A timezone-aware column enforces correctness at the
database level instead of relying on every future line of code
remembering a convention. Since a partner could be in a different
timezone, this isn't a hypothetical.

Changing a column's type on a table that already exists needs a second
Alembic migration (`op.alter_column`) — editing the model alone doesn't
touch the real database.

**How the upsert avoids duplicating rows**

The whole "overwrite, not duplicate" behavior comes down to one line:
`session.get(LocationState, FIXED_USER_ID)` looks up a row by primary
key *before* deciding what to do. If it finds one, `session.add()` never
runs again for that user — only the existing object's attributes get
changed, which SQLAlchemy turns into an `UPDATE` on commit instead of a
second `INSERT`.

---

### Issues #6–8 — Deploying to Render

**Why the start command differs from local (`0.0.0.0` and `$PORT`)**

Locally, `uvicorn`'s default host (`127.0.0.1`) only accepts connections
from your own machine. A public server needs to accept connections from
the outside internet, so it must bind to `0.0.0.0` (all network
interfaces). Similarly, Render assigns the actual port dynamically and
exposes it via the `$PORT` environment variable — it can't be hardcoded
like the `8000` used locally.

**Internal vs. External database URL**

Render gives two connection strings for the same database. The
*Internal* URL only works for other services inside Render's own private
network (e.g. the web service talking to its database) — faster, and
doesn't leave Render's infrastructure. The *External* URL is reachable
from anywhere, including a personal laptop — needed here once, to run
Alembic migrations against the remote database from a local machine
(Render's free tier has no SSH/shell access to run commands on the
server itself).

**Same code, different config per environment**

Local `.env` and Render's environment variable panel both set
`DATABASE_URL` for the exact same code (`main.py`), but to two different
databases — and that's deliberate, not an oversight. This is *why*
`DATABASE_URL` was never hardcoded in the first place: the same
application code runs in multiple places, and each place supplies its
own value for "which database to talk to." Also used a temporary,
one-off environment variable override (prefixing a single shell command)
to point Alembic at the remote database just for the migration step,
without ever writing the production URL into any file on disk.

---

### Issue #9 — Xcode project + location permission prompt

First Swift/iOS work in the project — new language, new frameworks.

**ObservableObject and @Published — how SwiftUI knows to redraw**

iOS's location APIs don't return an answer immediately; permission
results and location updates arrive later, asynchronously. SwiftUI needs
a way to know "something changed, please redraw" when that happens.
`ObservableObject` is a protocol that lets a class broadcast "I changed."
`@Published` marks one specific property as "watch this one — notify
observers whenever it changes." Analogy: `@Published` is a walkie-talkie
strapped to a variable; changing it automatically radios out "I changed!"
to anything listening. A plain `var` without `@Published` has no such
walkie-talkie.

**The delegate pattern**

`CLLocationManagerDelegate` + `manager.delegate = self` is a common
Apple-framework design, distinct from anything in the Python/FastAPI
side of this project. "Delegate" means "the object I hand a task off
to." Instead of polling "has anything happened yet?", you register an
object to be notified when something does. `func
locationManagerDidChangeAuthorization(...)` is a method *required* by
that delegate protocol — never called directly; iOS calls it
automatically whenever permission status actually changes (e.g. right
after the user taps Allow/Don't Allow).

**@StateObject**

`@StateObject private var locationManager = LocationManager()` in a View
means "this screen creates and *owns* one instance, keeping it alive for
as long as the screen exists." Combined with `@Published` above, this is
what makes the screen automatically redraw when `authorizationStatus`
changes — no manual "refresh the UI" code needed anywhere.

**Recurring error pattern: missing imports**

Hit the same class of error twice in a row: `@Published` requires
`import Combine` (it's not core Swift, it's a separate Apple toolkit),
and `CLAuthorizationStatus` (used in a `switch` in `ContentView`)
required `import CoreLocation` in *that* file specifically — importing a
type in one file doesn't make it available in another. Both errors
explicitly named "missing import of defining module" in the message,
which was the direct clue both times.

**Why "When In Use" first, not "Always"**

iOS deliberately does not allow requesting "Always" location access
upfront — apps must first request "When In Use," and can only *later*
request an upgrade to "Always," which triggers a separate second system
prompt. This app's whole premise (reporting location while backgrounded)
needs "Always" eventually, but the upgrade step is deliberately deferred
to issue #11, once significant-location-change (the feature that
actually requires "Always") is being wired up — not requested speculatively
here.

---

### Issue #10 — Manual POST on button tap to Render URL

**Local vs. Render aren't "old vs. new" — they're two permanently separate copies**

Got genuinely confused before writing this issue's code, so slowed down
to map the whole picture out. There are two independent running copies
of the same backend code: local (`localhost:8000` → local Postgres) and
Render (`hongyeon-api.onrender.com` → Render Postgres). They never talk
to each other — posting to one never affects the other's data. Local
exists so *I* can iterate fast and break things safely; Render is the
permanently-running public version. Both stay useful going forward —
local for trying new backend changes safely before they're ever exposed
publicly, Render as the real thing.

The iOS app is a *third*, fully separate program — it doesn't run
FastAPI or Postgres itself, it just sends HTTP requests to whichever URL
it's told to. The Simulator technically *could* reach `localhost`
(since it runs on the same Mac), but a real phone anywhere else never
could — so the app deliberately points at the Render URL even while
testing in the Simulator, to make Phase 0 an honest test of the real
loop (two separate devices, talking over the real internet to one
shared server) rather than a shortcut that only proves "my simulator
can talk to my own laptop."

**Swift also has async/await, for the same reason Python does**

`func sendLocation() async` + `try await URLSession.shared.data(for:
request)` — direct parallel to FastAPI's `async def` / `await` from the
backend. `await` pauses just this function while waiting on the network,
without blocking the rest of the app. `URLRequest` builds an HTTP
request (method, headers, body) the same way `curl` commands have been
doing manually all along, just in code.

**Optionals and `guard let`, in practice**

`lastLocation: CLLocation?` might not have a value yet (`nil`) — Swift
forces this to be handled explicitly rather than risking a crash later.
`guard let location = lastLocation else { return ... }` means "unwrap a
real value, or bail out early here if there isn't one." After that line,
`location` is guaranteed non-optional for the rest of the function.

**A real SwiftUI lesson, not just a typo: defining a property doesn't display it**

Added a `locationText` computed property, but forgot to actually place
`Text(locationText)` inside the `body`/`VStack`. Nothing crashed or
errored — the screen just silently didn't show it, because SwiftUI only
renders what's explicitly placed in the view hierarchy. Defining a
computed property that *describes* what to show is a separate step from
*placing* it on screen — unlike a `print()` statement, which runs
wherever it's written, a SwiftUI property does nothing until it's
actually referenced inside `body`.

---

### Issue #11 — Replace button with significant-location-change trigger

**Upgrading to "Always" needs a second, separate Info.plist key**

Adding `requestAlwaysAuthorization()` alone wasn't enough — Settings
didn't even show "Always" as an option until a *second* privacy string,
`NSLocationAlwaysAndWhenInUseUsageDescription`, was added, distinct from
`NSLocationWhenInUseUsageDescription` from issue #9. iOS requires apps to
justify background access separately from foreground access. Also
observed: once that key existed, tapping the in-app "Upgrade to Always"
button did trigger a real native system prompt directly — going through
Settings manually turned out not to be necessary once the actual missing
piece (the Info.plist key) was fixed.

**Significant-location-change has no fixed distance or time threshold**

Confirmed through real use, not just documentation: SLC is triggered by
hardware signals (cell tower handoffs, WiFi network changes) that only
*loosely* correlate with distance — there's no fixed "500 meters" rule
guaranteed to fire consistently. Real data from a weekend of normal use
(commute, midday, a soccer trip) showed 4 independent triggers, each
reflecting genuine movement — but the return drive from soccer produced
*zero* new updates, despite obviously moving. Not a bug; this is
expected, real behavior of an opportunistic, signal-based trigger.

**The status bar location arrow only reflects active use, not dormant registration**

Expected the location arrow (top-left of the status bar) to stay visibly
"on" while the app was backgrounded and registered for SLC. It didn't —
and that's correct behavior, not a sign anything was broken. The
indicator reflects the app *actively* using location right now; while
dormant/suspended waiting for a significant change, there's nothing
active to indicate. It would only briefly flash at the exact moment an
SLC event wakes the app. The database (`psql` against the live table),
not the phone's UI, was the only reliable way to confirm this was
actually working.

**Why "how often does this fire" gets answered on-device, not server-side**

Wanted a full log of every fire event (timestamp + coordinates) to
characterize frequency properly. The backend deliberately can't do this
— `location_states` overwrites on purpose; storing history there, even
temporarily "just for testing," would compromise the actual privacy
design the whole app is built around ("only the most recent location is
ever stored — never a history"). Any such diagnostic logging belongs
on-device only, and is scoped to issue #16 rather than bolted onto #11.

---

### Issue #12 — APNs key setup + send one test silent push

**AppDelegate and @UIApplicationDelegateAdaptor**

SwiftUI's `App`/`Scene` system doesn't cover everything — a handful of
low-level system events, including push notification registration, are
only ever delivered through the older, pre-SwiftUI `AppDelegate`
mechanism. `@UIApplicationDelegateAdaptor(AppDelegate.self)` in
`HongyeonApp.swift` creates one instance of a delegate class and wires
it into the running app; without that line, `AppDelegate.swift`'s
methods would just be dead code nobody ever calls. Same underlying
"delegate" pattern as `CLLocationManagerDelegate`, just Apple's original,
app-lifecycle-level version of it.

**Personal Team vs. a real paid Developer Program team**

Push Notifications capability was invisible in Xcode's capability
picker, even after searching — not a UI bug. Xcode was still signing
with the free "Personal Team," which structurally cannot support Push
Notifications at all (a hard Apple platform restriction, not a missing
setting). Even after the paid enrollment was approved, Xcode kept
showing "(Personal Team)" because it caches account status locally and
doesn't proactively re-check with Apple's servers — a full restart
forced it to re-fetch and show the real paid team.

**Key content vs. a path to the key — a real bug, not a typo**

`aioapns` needed the actual PEM key *content* (the real cryptographic
material) but was handed the key's file *path* as a string instead —
which it then tried to parse literally as if the path text itself were
a cryptographic key, failing with an unhelpful-looking
"Unable to load PEM file" error. Fixed by explicitly opening and reading
the file first (`open(path).read()`), rather than trusting the library
to resolve a path on its own. Worth remembering as a category of
mistake distinct from a typo: passing the *reference* to something where
the *thing itself* was expected.

**Silent pushes are invisible by design, and "sent" ≠ "received"**

A silent push (`{"aps": {"content-available": 1}}`, no `alert`/`sound`/
`badge`) never shows anything on the device — no banner, no notification
center entry, nothing. The only way to observe delivery is a
`print()` inside `didReceiveRemoteNotification`, watched live in Xcode's
console. Also: the backend script reporting `Success: True` only proves
*Apple's servers accepted the push for delivery* — it does not prove the
device received it. Those are two separate, decoupled steps, and actual
delivery can be delayed by iOS at its own discretion (matches the build
plan's "best-effort, never assumed real-time" framing for push).

**Treating the device token as semi-sensitive**

Caught before committing: an APNs device token was about to be
hardcoded directly into a script meant for the public repo. Not as
sensitive as the actual signing key (a token alone can't be used to send
anything without valid APNs credentials too), but it's still a
per-device identifier that shouldn't sit in public source — moved to
`.env` alongside everything else, rather than assuming "not a password"
means "fine to commit."

---

*(To be continued as we go...)*
