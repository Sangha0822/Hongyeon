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

*(To be continued as we go...)*
