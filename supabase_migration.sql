-- NQ Trade Logger — Supabase Migration
-- Corre este SQL no Supabase SQL Editor (Dashboard → SQL Editor → New query)

-- ─────────────────────────────────────────
-- Tabela user_data (armazena todos os dados da app por utilizador)
-- ─────────────────────────────────────────
create table if not exists public.user_data (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  key         text not null,
  value       jsonb,
  updated_at  timestamptz default now(),
  unique (user_id, key)
);

-- Índice para queries por user_id
create index if not exists user_data_user_id_idx on public.user_data(user_id);

-- Activar RLS
alter table public.user_data enable row level security;

-- Remover políticas antigas se existirem
drop policy if exists "user_data_select" on public.user_data;
drop policy if exists "user_data_insert" on public.user_data;
drop policy if exists "user_data_update" on public.user_data;
drop policy if exists "user_data_delete" on public.user_data;
drop policy if exists "user_data_upsert" on public.user_data;

-- Políticas RLS: cada utilizador só vê/modifica os seus próprios dados
create policy "user_data_select"
  on public.user_data for select
  using (auth.uid() = user_id);

create policy "user_data_insert"
  on public.user_data for insert
  with check (auth.uid() = user_id);

create policy "user_data_update"
  on public.user_data for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "user_data_delete"
  on public.user_data for delete
  using (auth.uid() = user_id);

-- ─────────────────────────────────────────
-- Verificação: deve retornar a tabela criada
-- ─────────────────────────────────────────
select table_name, row_security
from information_schema.tables
where table_schema = 'public' and table_name = 'user_data';
