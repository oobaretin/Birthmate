-- Birthday Circle table for Birthmate (Supabase)
-- Run in the Supabase SQL editor.

create table if not exists public.birthday_circle (
  client_id text primary key,
  display_name text not null check (char_length(display_name) between 1 and 32),
  birth_month int not null check (birth_month between 1 and 12),
  birth_day int not null check (birth_day between 1 and 31),
  is_discoverable boolean not null default true,
  updated_at timestamptz not null default now()
);

create index if not exists birthday_circle_month_day_idx
  on public.birthday_circle (birth_month, birth_day)
  where is_discoverable = true;

alter table public.birthday_circle enable row level security;

create policy "Anyone can read discoverable profiles"
  on public.birthday_circle
  for select
  using (is_discoverable = true);

create policy "Anyone can upsert their profile"
  on public.birthday_circle
  for insert
  with check (true);

create policy "Anyone can update their profile"
  on public.birthday_circle
  for update
  using (true)
  with check (true);

create policy "Anyone can delete their profile"
  on public.birthday_circle
  for delete
  using (true);

-- Add SUPABASE_URL and SUPABASE_ANON_KEY to Birthmate/Resources/Info.plist
-- (replace YOUR_SUPABASE_URL and YOUR_SUPABASE_ANON_KEY).
