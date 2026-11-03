-- Execute no Supabase: SQL Editor > New query > Run
create table if not exists public.professores (
  user_id uuid primary key references auth.users(id) on delete cascade
);
create table if not exists public.config (
  id int primary key default 1 check (id = 1),
  plano jsonb,
  atualizado_em timestamptz default now()
);
create table if not exists public.alunos (
  id uuid primary key default gen_random_uuid(),
  token text not null unique default replace(gen_random_uuid()::text, '-', ''),
  nome text not null,
  contato text,
  ativo boolean not null default true,
  plano jsonb,                         -- null = usa o treino da turma (config.plano)
  progresso jsonb not null default '{}'::jsonb,
  criado_em timestamptz default now(),
  atualizado_em timestamptz default now()
);

alter table public.professores enable row level security;
alter table public.config      enable row level security;
alter table public.alunos      enable row level security;

create or replace function public.is_prof() returns boolean
language sql stable security definer set search_path = public as
$$ select exists (select 1 from public.professores where user_id = auth.uid()) $$;

drop policy if exists prof_self on public.professores;
create policy prof_self on public.professores for select to authenticated using (user_id = auth.uid());
drop policy if exists prof_config on public.config;
create policy prof_config on public.config for all to authenticated using (public.is_prof()) with check (public.is_prof());
drop policy if exists prof_alunos on public.alunos;
create policy prof_alunos on public.alunos for all to authenticated using (public.is_prof()) with check (public.is_prof());

-- Acesso do aluno: somente via token, sem ler tabelas diretamente
create or replace function public.aluno_get(p_token text) returns jsonb
language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'nome', a.nome,
    'plano', coalesce(a.plano, (select plano from public.config where id = 1)),
    'progresso', a.progresso)
  from public.alunos a where a.token = p_token and a.ativo
$$;

create or replace function public.aluno_save(p_token text, p_progresso jsonb) returns void
language plpgsql security definer set search_path = public as $$
begin
  if length(p_progresso::text) > 200000 then raise exception 'payload grande demais'; end if;
  update public.alunos set progresso = p_progresso, atualizado_em = now()
  where token = p_token and ativo;
end $$;

revoke all on function public.aluno_get(text), public.aluno_save(text, jsonb) from public;
grant execute on function public.aluno_get(text), public.aluno_save(text, jsonb) to anon, authenticated;
