-- NQ Trade Logger — Supabase Storage v1
-- Corre no Supabase SQL Editor (Dashboard → SQL Editor → New query)
-- Cria bucket "prints" e políticas RLS para armazenar prints por utilizador

-- ─────────────────────────────────────────
-- Criar bucket "prints" (privado)
-- ─────────────────────────────────────────
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'prints',
  'prints',
  false,
  10485760,  -- 10 MB por ficheiro
  array['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
on conflict (id) do nothing;

-- ─────────────────────────────────────────
-- Políticas RLS do bucket
-- Path: {user_id}/trades|sessions|weekly/...
-- O utilizador só acede aos ficheiros dentro da sua pasta (user_id)
-- ─────────────────────────────────────────

drop policy if exists "prints_select" on storage.objects;
drop policy if exists "prints_insert" on storage.objects;
drop policy if exists "prints_update" on storage.objects;
drop policy if exists "prints_delete" on storage.objects;

create policy "prints_select"
  on storage.objects for select
  using (bucket_id = 'prints' AND auth.uid()::text = (storage.foldername(name))[1]);

create policy "prints_insert"
  on storage.objects for insert
  with check (bucket_id = 'prints' AND auth.uid()::text = (storage.foldername(name))[1]);

create policy "prints_update"
  on storage.objects for update
  using (bucket_id = 'prints' AND auth.uid()::text = (storage.foldername(name))[1]);

create policy "prints_delete"
  on storage.objects for delete
  using (bucket_id = 'prints' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ─────────────────────────────────────────
-- Verificação
-- ─────────────────────────────────────────
select id, name, public from storage.buckets where id = 'prints';
