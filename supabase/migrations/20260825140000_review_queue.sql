-- A question answered wrongly is scheduled to come back. `due` and the clock
-- it is compared against are both counted in questions answered, not in days.
create table if not exists public.review_queue (
  user_id     uuid        not null references auth.users(id) on delete cascade,
  question_id text        not null,
  step        int         not null default 0,
  due         int         not null default 0,
  misses      int         not null default 0,
  updated_at  timestamptz not null default now(),
  primary key (user_id, question_id)
);

alter table public.review_queue enable row level security;
drop policy if exists own_rows on public.review_queue;
create policy own_rows on public.review_queue
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

grant select, insert, update, delete on public.review_queue to authenticated;

-- the review clock travels with the rest of the preferences
alter table public.prefs add column if not exists clock int not null default 0;
