# SAT Practice

A digital-SAT practice interface for PDFs exported from the College Board
[SAT Question Bank](https://satsuitequestionbank.collegeboard.org/). Drop an
export in and it becomes a working test: passages, answer choices, cross-out,
highlighting, mark for review, the clock, and the official rationales on review.

Installable on iOS and Android. Signing in mirrors everything to Supabase, so a
question bank uploaded on one device is there on the next.

## What it does

**Reads the export properly.** The Question Bank PDF is a layout, not data. The
parser rebuilds each question from text runs and their coordinates, recovers
underlined spans from the drawing operators, and repairs the words the exporter
splits mid-token. Metadata is read by column position rather than gap width,
which is what makes long domain names like *Standard English Conventions* come
through intact.

**Remembers what you have done.** Every answer is recorded against the College
Board question ID. Re-import the same export, or a different one that overlaps,
and it says how many you have already practised and offers to leave them out.
Practice sets can include repeats, skip them, or drill only those.

**Builds a real module.** Given exports covering all four domains it assembles a
27-question Reading and Writing module on the published blueprint: the College
Board domain mix, the fixed order — Craft and Structure, Information and Ideas,
Standard English Conventions, Expression of Ideas — grouped by skill and running
easiest to hardest inside each domain, with Standard English Conventions ordered
by difficulty alone. 32 minutes, answers held to the end. Module 1, and both
Module 2 difficulty bands. If the pool is short it says exactly which domains
are missing instead of pretending.

## Layout

    index.html                     the whole app, one file
    manifest.webmanifest           installable-app metadata
    sw.js                          offline shell
    assets/icon.b64                app icon source (PNGs cannot be committed as text)
    scripts/build.mjs              renders the icons and assembles public/
    supabase/migrations/           database schema

## Running it

    npm install
    npm run build     # emits public/
    npx serve public

A static host is all it needs. On Vercel the build command is `npm run build`
and the output directory is `public`.

## Database

The migrations create six tables and a view. Row level security is on everywhere
and every policy is `user_id = auth.uid()`, so the publishable key in
`index.html` is safe to ship — it grants nothing without a session.

| Table | Holds |
|---|---|
| `sets`, `questions` | uploaded question banks |
| `attempts` | every answer: choice, correct, seconds, marked |
| `results` | finished runs, for the history screen |
| `prefs`, `session_state` | interface settings, and a run left unfinished |
| `question_progress` (view) | per-question totals, derived from `attempts` |

Progress is an append-only log rather than a counter, so it can be re-sliced by
skill, week or set later without a migration. Each attempt carries a client-side
key of `sessionId:questionId`, so a retried upload merges onto the same row
instead of inflating the counts.

## Sync model

Local storage stays the source of truth; the app works with no account and no
connection. When signed in, changes are also queued to Supabase and the queue
survives being offline, a reload, or a closed tab. Signing in on a new device
pulls prefs, progress, history, and any question bank not held locally.
