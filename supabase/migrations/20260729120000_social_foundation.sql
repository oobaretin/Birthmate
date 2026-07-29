-- Phase 1–4 social foundation: auth-linked profiles, favorites, friends, activity.

alter table public.birthday_circle
  add column if not exists user_id uuid unique references auth.users (id) on delete cascade,
  add column if not exists famous_twin_name text,
  add column if not exists famous_twin_wiki_title text;

create table if not exists public.favorite_birthmates (
  user_id uuid not null references auth.users (id) on delete cascade,
  wiki_title text not null,
  display_name text not null,
  created_at timestamptz not null default now(),
  primary key (user_id, wiki_title)
);

create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references auth.users (id) on delete cascade,
  addressee_id uuid not null references auth.users (id) on delete cascade,
  status text not null check (status in ('pending', 'accepted', 'declined')),
  created_at timestamptz not null default now(),
  unique (requester_id, addressee_id),
  check (requester_id <> addressee_id)
);

create index if not exists friendships_addressee_status_idx
  on public.friendships (addressee_id, status);

create index if not exists friendships_requester_status_idx
  on public.friendships (requester_id, status);

create table if not exists public.activity_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  event_type text not null,
  title text not null,
  detail text,
  created_at timestamptz not null default now()
);

create index if not exists activity_events_user_created_idx
  on public.activity_events (user_id, created_at desc);

alter table public.favorite_birthmates enable row level security;
alter table public.friendships enable row level security;
alter table public.activity_events enable row level security;

drop policy if exists "Anyone can read discoverable profiles" on public.birthday_circle;
drop policy if exists "Anyone can upsert their profile" on public.birthday_circle;
drop policy if exists "Anyone can update their profile" on public.birthday_circle;
drop policy if exists "Anyone can delete their profile" on public.birthday_circle;

create policy "read_discoverable_or_own_profile"
  on public.birthday_circle for select
  using (is_discoverable = true or user_id = auth.uid());

create policy "insert_own_profile"
  on public.birthday_circle for insert
  with check (user_id = auth.uid());

create policy "update_own_profile"
  on public.birthday_circle for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "delete_own_profile"
  on public.birthday_circle for delete
  using (user_id = auth.uid());

drop policy if exists "read_own_favorites" on public.favorite_birthmates;
create policy "read_own_favorites"
  on public.favorite_birthmates for select
  using (user_id = auth.uid());

drop policy if exists "write_own_favorites" on public.favorite_birthmates;
create policy "write_own_favorites"
  on public.favorite_birthmates for insert
  with check (user_id = auth.uid());

drop policy if exists "delete_own_favorites" on public.favorite_birthmates;
create policy "delete_own_favorites"
  on public.favorite_birthmates for delete
  using (user_id = auth.uid());

drop policy if exists "read_own_friendships" on public.friendships;
create policy "read_own_friendships"
  on public.friendships for select
  using (requester_id = auth.uid() or addressee_id = auth.uid());

drop policy if exists "insert_friend_requests" on public.friendships;
create policy "insert_friend_requests"
  on public.friendships for insert
  with check (requester_id = auth.uid());

drop policy if exists "update_incoming_friendships" on public.friendships;
create policy "update_incoming_friendships"
  on public.friendships for update
  using (addressee_id = auth.uid())
  with check (addressee_id = auth.uid());

drop policy if exists "delete_own_friendships" on public.friendships;
create policy "delete_own_friendships"
  on public.friendships for delete
  using (requester_id = auth.uid() or addressee_id = auth.uid());

drop policy if exists "read_own_activity" on public.activity_events;
create policy "read_own_activity"
  on public.activity_events for select
  using (user_id = auth.uid());

drop policy if exists "insert_own_activity" on public.activity_events;
create policy "insert_own_activity"
  on public.activity_events for insert
  with check (user_id = auth.uid());
