-- An attempt is identified by a client-generated key (sessionId:questionId), so
-- a retried or replayed upload merges onto the same row instead of inflating
-- the progress counts. PostgREST can then upsert on the primary key directly.
drop view if exists public.question_progress;
drop table if exists public.attempts;

create table public.attempts (
  user_id     uuid        not null references auth.users(id) on delete cascade,
  id          text        not null,
  question_id text        not null,
  set_id      text,
  session_id  text,
  chosen      text,
  correct     boolean     not null,
  marked      boolean     not null default false,
  seconds     integer,
  answered_at timestamptz not null default now(),
  primary key (user_id, id)
);
create index attempts_by_question on public.attempts (user_id, question_id);
create index attempts_recent      on public.attempts (user_id, answered_at desc);

create view public.question_progress
with (security_invoker = on) as
select
  user_id,
  question_id,
  count(*)::int                                     as attempts,
  count(*) filter (where correct)::int              as correct,
  max(answered_at)                                  as last_at,
  (array_agg(correct order by answered_at desc))[1] as last_correct
from public.attempts
group by user_id, question_id;

alter table public.attempts enable row level security;
create policy own_rows on public.attempts
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

grant select, insert, update, delete on public.attempts to authenticated;
grant select on public.question_progress to authenticated;
