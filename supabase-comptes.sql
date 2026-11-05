-- Clash of Quonze : comptes joueurs (à exécuter une seule fois dans Supabase → SQL Editor → Run)
-- Chaque joueur a une ligne « profiles » liée à son compte (auth.users.id) contenant toute sa progression.

create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  pseudo      text not null default 'Soldat' check (char_length(pseudo) between 1 and 18),
  save        jsonb not null default '{}'::jsonb,   -- trophées, collection, deck, coffres, stats, amis…
  updated_at  timestamptz not null default now()
);

-- Sécurité : chaque joueur ne peut lire et modifier QUE sa propre progression
alter table public.profiles enable row level security;

drop policy if exists "profil : lecture par son propriétaire" on public.profiles;
drop policy if exists "profil : création par son propriétaire" on public.profiles;
drop policy if exists "profil : modification par son propriétaire" on public.profiles;

create policy "profil : lecture par son propriétaire" on public.profiles
  for select using (auth.uid() = id);
create policy "profil : création par son propriétaire" on public.profiles
  for insert with check (auth.uid() = id);
create policy "profil : modification par son propriétaire" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);
