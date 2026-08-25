-- SAT practice — cloud sync schema.
-- Every table is keyed by auth.uid() and locked with RLS, so the publishable
-- key is safe to ship in the client.

create table if not exists public.sets (
  user_id        uuid        not null references auth.users(id) on delete cascade,
  id             text        not null,
  name           text        not null,
  tests          text[]      not null default '{}',
  question_count integer     not null default 0,
  created_at     timestamptz not null default now(),
  synced_at      timestamptz not null default now(),
  primary key (user_id, id)
);

create table if not exists public.questions (
  user_id     uuid    not null,
  set_id      text    not null,
  question_id text    not null,
  ord         integer not null default 0,
  test        text,
  domain      text,
  skill       text,
  difficulty  text,
  data        jsonb   not null,
  primary key (user_id, set_id, question_id),
  foreign key (user_id, set_id) references public.sets(user_id, id) on delete cascade
);
create index if not exists questions_by_question on public.questions (user_id, question_id);
create index if not exists questions_by_domain   on public.questions (user_id, test, domain, difficulty);

create table if not exists public.results (
  user_id     uuid        not null references auth.users(id) on delete cascade,
  id          text        not null,
  title       text,
  mode        text,
  total       integer     not null default 0,
  correct     integer     not null default 0,
  elapsed_s   integer,
  skills      jsonb       not null default '{}'::jsonb,
  started_at  timestamptz,
  finished_at timestamptz not null default now(),
  primary key (user_id, id)
);
create index if not exists results_recent on public.results (user_id, finished_at desc);

create table if not exists public.prefs (
  user_id    uuid        primary key references auth.users(id) on delete cascade,
  data       jsonb       not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.session_state (
  user_id    uuid        primary key references auth.users(id) on delete cascade,
  data       jsonb,
  updated_at timestamptz not null default now()
);

alter table public.sets          enable row level security;
alter table public.questions     enable row level security;
alter table public.results       enable row level security;
alter table public.prefs         enable row level security;
alter table public.session_state enable row level security;

do $$
declare t text;
begin
  foreach t in array array['sets','questions','results','prefs','session_state'] loop
    execute format('drop policy if exists own_rows on public.%I', t);
    execute format($f$
      create policy own_rows on public.%I
        for all to authenticated
        using (user_id = (select auth.uid()))
        with check (user_id = (select auth.uid()))
    $f$, t);
  end loop;
end $$;

grant select, insert, update, delete
  on public.sets, public.questions,
     public.results, public.prefs, public.session_state
  to authenticated;
grant usage, select on all sequences in schema public to authenticated;
