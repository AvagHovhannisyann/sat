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

**Builds a real module, at the level you want.** Given exports covering all four
domains it assembles a 27-question Reading and Writing module on the published
blueprint: the College Board domain mix, the fixed order — Craft and Structure,
Information and Ideas, Standard English Conventions, Expression of Ideas —
grouped by skill and running easiest to hardest inside each domain, with
Standard English Conventions ordered by difficulty alone.

| Level | Mix | Mirrors |
|---|---|---|
| Easy | 55% easy, 35% medium, 10% hard | the easier second module |
| Medium | 30 / 40 / 30 | the balanced first module everyone sits |
| Hard | 0% easy, 20% medium, 80% hard | the hard second module |

The clock defaults to the real 32 minutes and can be set to anything, or removed.
If the pool is short it says exactly which domains are missing instead of
pretending, and opens the custom builder so there is no dead end.

**Remembers what you have done.** Every answer is recorded against the College
Board question ID. Questions you have already practised are left out of new
sets by default; you can include them, or drill only those. Re-import an
overlapping export and it says how many repeats it found.

**Shows where the points are going.** A progress page reports accuracy and pace
by difficulty, domain and skill, run-by-run accuracy, a day streak, and the
skills you are under 70% on — with one button to drill exactly those.

**Keeps every question you have answered.** A searchable library of your
practised questions, full text and official rationale included, filterable to
the ones you got wrong or flagged, and re-runnable as a set.

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
connection. Saving is automatic — there is no sync button. Changes are queued to
Supabase and the queue survives being offline, a reload, or a closed tab; a
request that can never succeed is discarded rather than blocking the ones behind
it. Signing in on a new device pulls prefs, progress, history, and any question
bank not held locally. Removing a set removes it from the account too, while
keeping the answer history that came from it.
