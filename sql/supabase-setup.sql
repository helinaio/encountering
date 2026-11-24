-- 照片墙 · 从零建库（Supabase Dashboard → SQL Editor 整段执行）
-- 建：photos 表、公开存储桶 photos、匿名读写策略

-- 1. 照片表
create table if not exists public.photos (
  id uuid primary key default gen_random_uuid(),
  nickname text not null default '',
  message text not null default '',
  photo_url text not null default '',
  event text not null default 'mufriends-2026-11-06',
  deleted boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.photos enable row level security;

create policy "photos anon read" on public.photos
  for select to anon using (true);

create policy "photos anon insert" on public.photos
  for insert to anon with check (true);

create policy "photos anon update" on public.photos
  for update to anon using (true) with check (true);

-- 2. 存储桶：公开读
insert into storage.buckets (id, name, public)
values ('photos', 'photos', true)
on conflict (id) do nothing;

-- 3. 存储策略：匿名可读可传
create policy "photos bucket anon read" on storage.objects
  for select to anon using (bucket_id = 'photos');

create policy "photos bucket anon insert" on storage.objects
  for insert to anon with check (bucket_id = 'photos');
