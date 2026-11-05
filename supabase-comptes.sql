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

-- ---------------------------------------------------------------------------
-- Pseudos uniques (insensible à la casse) : « Yanis » et « yanis » ne peuvent pas coexister
create unique index if not exists profiles_pseudo_unique on public.profiles (lower(pseudo));

-- Vérification du pseudo AVANT la création du compte (appelable sans être connecté).
-- Renvoie true si le pseudo est libre. Ne révèle aucune autre donnée des profils.
create or replace function public.pseudo_disponible(p text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select not exists (
    select 1 from public.profiles
    where lower(pseudo) = lower(trim(p))
      and id <> coalesce(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
  );
$$;
revoke all on function public.pseudo_disponible(text) from public;
grant execute on function public.pseudo_disponible(text) to anon, authenticated;
