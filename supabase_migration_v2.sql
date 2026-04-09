-- NQ Trade Logger — Migration v2
-- Corre no Supabase SQL Editor (Dashboard → SQL Editor → New query)
-- Cria tabelas individuais para trades e sessions (em vez de um JSON gigante)

-- ─────────────────────────────────────────
-- Tabela trades (uma linha por trade)
-- ─────────────────────────────────────────
create table if not exists public.trades (
  id          text not null,
  user_id     uuid not null references auth.users(id) on delete cascade,
  account_id  text not null,
  data        jsonb not null default '{}'::jsonb,
  screenshots jsonb default '[]'::jsonb,
  updated_at  timestamptz default now(),
  primary key (user_id, id)
);

create index if not exists trades_user_id_idx    on public.trades(user_id);
create index if not exists trades_account_id_idx on public.trades(account_id);

alter table public.trades enable row level security;

drop policy if exists "trades_select" on public.trades;
drop policy if exists "trades_insert" on public.trades;
drop policy if exists "trades_update" on public.trades;
drop policy if exists "trades_delete" on public.trades;

create policy "trades_select" on public.trades for select using (auth.uid() = user_id);
create policy "trades_insert" on public.trades for insert with check (auth.uid() = user_id);
create policy "trades_update" on public.trades for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "trades_delete" on public.trades for delete using (auth.uid() = user_id);

-- ─────────────────────────────────────────
-- Tabela sessions (uma linha por data)
-- ─────────────────────────────────────────
create table if not exists public.sessions (
  date        text not null,
  user_id     uuid not null references auth.users(id) on delete cascade,
  data        jsonb not null default '{}'::jsonb,
  screenshots jsonb default '[]'::jsonb,
  updated_at  timestamptz default now(),
  primary key (user_id, date)
);

create index if not exists sessions_user_id_idx on public.sessions(user_id);

alter table public.sessions enable row level security;

drop policy if exists "sessions_select" on public.sessions;
drop policy if exists "sessions_insert" on public.sessions;
drop policy if exists "sessions_update" on public.sessions;
drop policy if exists "sessions_delete" on public.sessions;

create policy "sessions_select" on public.sessions for select using (auth.uid() = user_id);
create policy "sessions_insert" on public.sessions for insert with check (auth.uid() = user_id);
create policy "sessions_update" on public.sessions for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "sessions_delete" on public.sessions for delete using (auth.uid() = user_id);

-- ─────────────────────────────────────────
-- Verificação
-- ─────────────────────────────────────────
select table_name, row_security
from information_schema.tables
where table_schema = 'public' and table_name in ('trades', 'sessions', 'user_data');
