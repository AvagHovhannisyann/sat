-- Questions in `questions` mirror the library and disappear with their set.
-- Anything actually answered is archived here instead, keyed by the College
-- Board question id, so the review of past work never loses its text.
create table if not exists public.answered_questions (
  user_id     uuid        not null references auth.users(id) on delete cascade,
  question_id text        not null,
  test        text,
  domain      text,
  skill       text,
  difficulty  text,
  data        jsonb       not null,
  first_seen  timestamptz not null default now(),
  primary key (user_id, question_id)
);
create index if not exists answered_by_skill on public.answered_questions (user_id, skill);

alter table public.answered_questions enable row level security;
drop policy if exists own_rows on public.answered_questions;
create policy own_rows on public.answered_questions
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

grant select, insert, update, delete on public.answered_questions to authenticated;
