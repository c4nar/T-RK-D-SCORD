-- Run once in Supabase Dashboard > SQL Editor. Never expose the service_role key.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique check (char_length(username) between 3 and 24),
  created_at timestamptz not null default now()
);
create table if not exists public.servers (
  id uuid primary key default gen_random_uuid(), name text not null check (char_length(name) between 1 and 40),
  owner_id uuid not null references auth.users(id) on delete cascade, created_at timestamptz not null default now()
);
create table if not exists public.server_members (
  server_id uuid not null references public.servers(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check(role in ('owner','member')),
  primary key(server_id,user_id)
);
create table if not exists public.channels (
  id uuid primary key default gen_random_uuid(), server_id uuid not null references public.servers(id) on delete cascade,
  name text not null check(char_length(name) between 1 and 40), created_at timestamptz not null default now()
);
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(), channel_id uuid not null references public.channels(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade, content text not null default '' check(char_length(content)<=4000),
  file_path text, file_name text, created_at timestamptz not null default now(),
  check ((file_path is null) or (file_name is not null))
);
create index if not exists messages_channel_created on public.messages(channel_id,created_at);
create table if not exists public.friend_requests (
  id uuid primary key default gen_random_uuid(), sender_id uuid not null references auth.users(id) on delete cascade,
  recipient_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending' check(status in ('pending','accepted')),
  created_at timestamptz not null default now(), check(sender_id<>recipient_id), unique(sender_id,recipient_id)
);

create or replace function public.new_profile() returns trigger language plpgsql security definer set search_path=public as $$
begin
  insert into public.profiles(id,username) values(new.id, coalesce(nullif(new.raw_user_meta_data->>'username',''),split_part(new.email,'@',1)))
  on conflict(id) do nothing;
  return new;
end $$;
drop trigger if exists auth_user_profile on auth.users;
create trigger auth_user_profile after insert on auth.users for each row execute procedure public.new_profile();

alter table public.profiles enable row level security;
alter table public.servers enable row level security;
alter table public.server_members enable row level security;
alter table public.channels enable row level security;
alter table public.messages enable row level security;
alter table public.friend_requests enable row level security;

-- SECURITY DEFINER helpers avoid recursive row-security checks on server_members.
create or replace function public.is_server_member(sid uuid) returns boolean
language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.server_members where server_id=sid and user_id=auth.uid())
$$;
create or replace function public.is_server_owner(sid uuid) returns boolean
language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.server_members where server_id=sid and user_id=auth.uid() and role='owner')
$$;
revoke all on function public.is_server_member(uuid) from public, anon;
revoke all on function public.is_server_owner(uuid) from public, anon;
grant execute on function public.is_server_member(uuid) to authenticated;
grant execute on function public.is_server_owner(uuid) to authenticated;

-- Private voice signaling is available only to signed-in members of its channel's server.
drop policy if exists "server members receive voice signals" on realtime.messages;
create policy "server members receive voice signals" on realtime.messages for select to authenticated
using (realtime.topic() like 'voice:%' and exists (
  select 1 from public.channels c where c.id::text=split_part(realtime.topic(),':',2) and public.is_server_member(c.server_id)
));
drop policy if exists "server members send voice signals" on realtime.messages;
create policy "server members send voice signals" on realtime.messages for insert to authenticated
with check (realtime.topic() like 'voice:%' and exists (
  select 1 from public.channels c where c.id::text=split_part(realtime.topic(),':',2) and public.is_server_member(c.server_id)
));

drop policy if exists "profiles visible to signed in users" on public.profiles;
create policy "profiles visible to signed in users" on public.profiles for select to authenticated using(true);
drop policy if exists "profile owner updates own" on public.profiles;
create policy "profile owner updates own" on public.profiles for update to authenticated using(id=auth.uid()) with check(id=auth.uid());

drop policy if exists "members read servers" on public.servers;
create policy "members read servers" on public.servers for select to authenticated using(public.is_server_member(id));
drop policy if exists "authenticated create own server" on public.servers;
create policy "authenticated create own server" on public.servers for insert to authenticated with check(owner_id=auth.uid());
drop policy if exists "owner updates server" on public.servers;
create policy "owner updates server" on public.servers for update to authenticated using(owner_id=auth.uid()) with check(owner_id=auth.uid());
drop policy if exists "owner deletes server" on public.servers;
create policy "owner deletes server" on public.servers for delete to authenticated using(owner_id=auth.uid());

drop policy if exists "members read memberships" on public.server_members;
create policy "members read memberships" on public.server_members for select to authenticated using(public.is_server_member(server_id));
drop policy if exists "server owner adds members" on public.server_members;
create policy "server owner adds members" on public.server_members for insert to authenticated with check(exists(select 1 from public.servers s where s.id=server_id and s.owner_id=auth.uid()) or (user_id=auth.uid() and exists(select 1 from public.servers s where s.id=server_id and s.owner_id=auth.uid())));
drop policy if exists "member leaves or owner removes" on public.server_members;
create policy "member leaves or owner removes" on public.server_members for delete to authenticated using(user_id=auth.uid() or exists(select 1 from public.servers s where s.id=server_id and s.owner_id=auth.uid()));

drop policy if exists "members read channels" on public.channels;
create policy "members read channels" on public.channels for select to authenticated using(public.is_server_member(server_id));
drop policy if exists "members create channels" on public.channels;
create policy "members create channels" on public.channels for insert to authenticated with check(public.is_server_owner(server_id));
drop policy if exists "server owners delete channels" on public.channels;
create policy "server owners delete channels" on public.channels for delete to authenticated using(public.is_server_owner(server_id));

drop policy if exists "members read messages" on public.messages;
create policy "members read messages" on public.messages for select to authenticated using(exists(select 1 from public.channels c where c.id=channel_id and public.is_server_member(c.server_id)));
drop policy if exists "members send messages" on public.messages;
create policy "members send messages" on public.messages for insert to authenticated with check(user_id=auth.uid() and exists(select 1 from public.channels c where c.id=channel_id and public.is_server_member(c.server_id)));
drop policy if exists "authors delete messages" on public.messages;
create policy "authors delete messages" on public.messages for delete to authenticated using(user_id=auth.uid());

drop policy if exists "users read own friend requests" on public.friend_requests;
create policy "users read own friend requests" on public.friend_requests for select to authenticated using(sender_id=auth.uid() or recipient_id=auth.uid());
drop policy if exists "users send friend requests" on public.friend_requests;
create policy "users send friend requests" on public.friend_requests for insert to authenticated with check(sender_id=auth.uid());
drop policy if exists "recipients accept requests" on public.friend_requests;
create policy "recipients accept requests" on public.friend_requests for update to authenticated using(recipient_id=auth.uid() and status='pending') with check(recipient_id=auth.uid() and status='accepted');

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('uploads','uploads',false,15728640,array['image/*','application/pdf','text/plain','application/zip','audio/*','video/*'])
on conflict(id) do update set public=false,file_size_limit=15728640;
drop policy if exists "server members read uploads" on storage.objects;
create policy "server members read uploads" on storage.objects for select to authenticated using(bucket_id='uploads' and public.is_server_member((storage.foldername(name))[1]::uuid));
drop policy if exists "members upload to own server folder" on storage.objects;
create policy "members upload to own server folder" on storage.objects for insert to authenticated with check(bucket_id='uploads' and (storage.foldername(name))[2]=auth.uid()::text and public.is_server_member((storage.foldername(name))[1]::uuid));

-- Enable message inserts in Supabase Realtime (idempotent).
do $$ begin alter publication supabase_realtime add table public.messages; exception when duplicate_object then null; end $$;
