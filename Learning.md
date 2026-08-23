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

*(To be continued as we go...)*
