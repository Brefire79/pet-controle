-- =====================================================================
-- Vianexx PetCare — Esquema Supabase (Postgres)
-- Login: email + senha (Supabase Auth)
-- Modelo: multi-pet por conta, isolamento por Row Level Security (RLS)
-- Rodar no SQL Editor do Supabase.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Helper: updated_at automático
-- ---------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end; $$;

-- ---------------------------------------------------------------------
-- PETS  (cada pet pertence a um usuário do auth.users)
-- ---------------------------------------------------------------------
create table if not exists public.pets (
  id            uuid primary key default gen_random_uuid(),
  owner_id      uuid not null references auth.users(id) on delete cascade,
  nome          text not null,
  especie_raca  text,
  nascimento    date,
  castracao     date,
  avatar_url    text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create index if not exists idx_pets_owner on public.pets(owner_id);

create trigger trg_pets_updated before update on public.pets
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------
-- MEDICAMENTOS  (tratamentos)
-- ---------------------------------------------------------------------
create table if not exists public.medicamentos (
  id           uuid primary key default gen_random_uuid(),
  pet_id       uuid not null references public.pets(id) on delete cascade,
  nome         text not null,
  dose         text not null,
  freq_horas   integer not null default 24,
  dias_totais  integer not null default 1,
  data_inicio  timestamptz not null default now(),
  active       boolean not null default true,
  alert        boolean not null default true,
  interrompido boolean not null default false,        -- tratamento parado antes do fim
  motivo_interrupcao text,                             -- ex: Orientação do veterinário
  data_interrupcao   timestamptz,                      -- quando foi interrompido
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index if not exists idx_med_pet on public.medicamentos(pet_id);

create trigger trg_med_updated before update on public.medicamentos
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------
-- DOSES MINISTRADAS  (núcleo: cada administração é um evento com horário)
-- ---------------------------------------------------------------------
create table if not exists public.doses (
  id              uuid primary key default gen_random_uuid(),
  medicamento_id  uuid not null references public.medicamentos(id) on delete cascade,
  ts              timestamptz not null default now(),   -- data/hora da administração
  nota            text,                                  -- ex: com comida, vomitou
  imported        boolean not null default false,
  created_at      timestamptz not null default now()
);
create index if not exists idx_doses_med on public.doses(medicamento_id);
create index if not exists idx_doses_ts  on public.doses(ts);

-- ---------------------------------------------------------------------
-- VACINAS
-- ---------------------------------------------------------------------
create table if not exists public.vacinas (
  id              uuid primary key default gen_random_uuid(),
  pet_id          uuid not null references public.pets(id) on delete cascade,
  nome            text not null,
  data_aplicacao  date not null,
  data_reforco    date,
  veterinario     text,
  created_at      timestamptz not null default now()
);
create index if not exists idx_vac_pet on public.vacinas(pet_id);

-- ---------------------------------------------------------------------
-- REGISTROS CLÍNICOS / CONSULTAS
-- (evolução do PRD: data própria, retorno, vet e custo)
-- ---------------------------------------------------------------------
create table if not exists public.registros (
  id                  uuid primary key default gen_random_uuid(),
  pet_id              uuid not null references public.pets(id) on delete cascade,
  tipo                text not null,   -- Consulta de Rotina, Sintoma, Exame, Cirúrgico
  descricao           text not null,
  data                date not null default current_date,
  proximo_retorno     date,
  veterinario         text,
  clinica             text,
  custo               numeric(10,2),
  created_at          timestamptz not null default now()
);
create index if not exists idx_reg_pet on public.registros(pet_id);

-- ---------------------------------------------------------------------
-- PESOS
-- ---------------------------------------------------------------------
create table if not exists public.pesos (
  id          uuid primary key default gen_random_uuid(),
  pet_id      uuid not null references public.pets(id) on delete cascade,
  valor       numeric(6,2) not null,
  data        timestamptz not null default now(),
  created_at  timestamptz not null default now()
);
create index if not exists idx_pesos_pet on public.pesos(pet_id);

-- ---------------------------------------------------------------------
-- ALIMENTAÇÃO / DIETA
-- ---------------------------------------------------------------------
create table if not exists public.alimentacao (
  id          uuid primary key default gen_random_uuid(),
  pet_id      uuid not null references public.pets(id) on delete cascade,
  nome        text not null,
  quantidade  text not null,
  data        timestamptz not null default now(),
  created_at  timestamptz not null default now()
);
create index if not exists idx_alim_pet on public.alimentacao(pet_id);

-- =====================================================================
-- ROW LEVEL SECURITY
-- Regra: o usuário só enxerga/mexe nos dados dos próprios pets.
-- =====================================================================

alter table public.pets        enable row level security;
alter table public.medicamentos enable row level security;
alter table public.doses       enable row level security;
alter table public.vacinas     enable row level security;
alter table public.registros   enable row level security;
alter table public.pesos       enable row level security;
alter table public.alimentacao enable row level security;

-- PETS: dono direto
create policy "pets_owner_all" on public.pets
  for all using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

-- Helper de pertencimento para tabelas-filhas (pet do usuário logado)
-- Usado nas policies abaixo via subselect.

-- MEDICAMENTOS
create policy "med_owner_all" on public.medicamentos
  for all using (
    pet_id in (select id from public.pets where owner_id = auth.uid())
  ) with check (
    pet_id in (select id from public.pets where owner_id = auth.uid())
  );

-- DOSES (via medicamento -> pet -> dono)
create policy "doses_owner_all" on public.doses
  for all using (
    medicamento_id in (
      select m.id from public.medicamentos m
      join public.pets p on p.id = m.pet_id
      where p.owner_id = auth.uid()
    )
  ) with check (
    medicamento_id in (
      select m.id from public.medicamentos m
      join public.pets p on p.id = m.pet_id
      where p.owner_id = auth.uid()
    )
  );

-- VACINAS
create policy "vac_owner_all" on public.vacinas
  for all using (
    pet_id in (select id from public.pets where owner_id = auth.uid())
  ) with check (
    pet_id in (select id from public.pets where owner_id = auth.uid())
  );

-- REGISTROS
create policy "reg_owner_all" on public.registros
  for all using (
    pet_id in (select id from public.pets where owner_id = auth.uid())
  ) with check (
    pet_id in (select id from public.pets where owner_id = auth.uid())
  );

-- PESOS
create policy "pesos_owner_all" on public.pesos
  for all using (
    pet_id in (select id from public.pets where owner_id = auth.uid())
  ) with check (
    pet_id in (select id from public.pets where owner_id = auth.uid())
  );

-- ALIMENTAÇÃO
create policy "alim_owner_all" on public.alimentacao
  for all using (
    pet_id in (select id from public.pets where owner_id = auth.uid())
  ) with check (
    pet_id in (select id from public.pets where owner_id = auth.uid())
  );

-- =====================================================================
-- FIM
-- =====================================================================
