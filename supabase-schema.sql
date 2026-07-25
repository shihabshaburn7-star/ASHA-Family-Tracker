-- ============================================================
-- ASHA Family Tracker — Supabase schema
-- Run this once in your Supabase project's SQL Editor
-- (Dashboard → SQL Editor → New query → paste all → Run)
-- ============================================================

create extension if not exists "pgcrypto";

-- One row per household
create table if not exists families (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid() references auth.users(id) on delete cascade,
  house_no     text,
  house_name   text,
  address      text,
  area         text,
  description  text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- One row per person, linked to a household
create table if not exists members (
  id                   uuid primary key default gen_random_uuid(),
  family_id            uuid not null references families(id) on delete cascade,
  name                 text not null,
  role                 text,       -- e.g. "House Owner / Head of Family", "Father", "Wife", etc.
  gender               text,       -- Male / Female / Other
  date_of_birth        date,       -- age is calculated live from this, so it's always accurate
  phone                text,
  aadhar               text,
  job                  text,
  disease              text,
  is_pregnant          boolean not null default false,
  pregnancy_start_date date,       -- LMP date; pregnancy month is calculated live from this
  vaccinations         jsonb not null default '{}'::jsonb,  -- { vaccine_key: "date given" }, only relevant under 18
  other_vaccine_notes  text,       -- free text for SIA/pulse polio rounds etc.
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);

-- ------------------------------------------------------------
-- MIGRATION: if you already ran an earlier version of this
-- script (with an "age" column, or a single "polio_given" flag,
-- instead of the full immunization schedule), this block safely
-- brings an existing table up to date without deleting your
-- household data. It's safe to re-run.
-- ------------------------------------------------------------
alter table members add column if not exists date_of_birth date;
alter table members add column if not exists is_pregnant boolean not null default false;
alter table members add column if not exists pregnancy_start_date date;
alter table members add column if not exists vaccinations jsonb not null default '{}'::jsonb;
alter table members add column if not exists other_vaccine_notes text;
alter table members drop column if exists age;
alter table members drop column if exists pregnancy_month;
alter table members drop column if exists polio_given;

-- MIGRATION: adds per-user ownership so different logins each see
-- only their own households, instead of everyone sharing one pool
-- of data. Safe to re-run.
alter table families add column if not exists user_id uuid references auth.users(id) on delete cascade;
alter table families alter column user_id set default auth.uid();

-- ------------------------------------------------------------
-- ⚠️ ONE-TIME MANUAL STEP if you already had households saved
-- before this update: they currently have no owner, so they'd
-- become invisible to everyone. Assign them to yourself:
--
-- 1. Go to Authentication → Users, click your user, and copy its
--    "User UID".
-- 2. Uncomment the line below, paste your User UID in place of
--    the placeholder, then run just that one line.
--
-- update families set user_id = 'PASTE-YOUR-USER-UID-HERE' where user_id is null;
-- ------------------------------------------------------------

create index if not exists idx_members_family_id on members(family_id);
create index if not exists idx_families_area on families(area);
create index if not exists idx_families_user_id on families(user_id);

-- ============================================================
-- SECURITY: this data includes Aadhaar numbers, phone numbers
-- and health information. Row Level Security is turned on so
-- that ONLY a logged-in (authenticated) user can read or write
-- data — and, as of this update, each user can only see and
-- manage their OWN households and members, not anyone else's.
-- The anon public key alone (used by the web page) is not
-- enough — a user must sign in first, and even then only their
-- own data is visible.
-- ============================================================

alter table families enable row level security;
alter table members  enable row level security;

drop policy if exists "authenticated full access" on families;
drop policy if exists "users manage their own families" on families;
create policy "users manage their own families" on families
  for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "authenticated full access" on members;
drop policy if exists "users manage their own members" on members;
create policy "users manage their own members" on members
  for all
  using (exists (select 1 from families f where f.id = members.family_id and f.user_id = auth.uid()))
  with check (exists (select 1 from families f where f.id = members.family_id and f.user_id = auth.uid()));

-- ============================================================
-- After running this file:
-- 1. Go to Authentication → Users → Add user, and create a
--    login (email + password) for each ASHA worker who needs
--    their own separate set of households. Each login now gets
--    its own private data automatically — nothing to configure
--    per user beyond creating their account.
-- 2. Go to Authentication → Providers → Email, and turn OFF
--    "Confirm email" if you want to add users instantly without
--    them needing to click a confirmation link.
-- 3. If you had existing households before this update, don't
--    forget the one-time manual step above to assign them to
--    your user, or they won't show up for anyone.
-- ============================================================
