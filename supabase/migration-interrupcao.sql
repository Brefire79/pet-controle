-- =====================================================================
-- Migração: interrupção de tratamento (parar medicamento em uso)
-- Rodar no [SUPABASE SQL EDITOR] em bancos que já tinham a tabela medicamentos.
-- Bancos novos já vêm com essas colunas via schema.sql.
-- Idempotente: pode rodar mais de uma vez sem erro.
-- =====================================================================

alter table public.medicamentos
  add column if not exists interrompido       boolean not null default false,
  add column if not exists motivo_interrupcao text,
  add column if not exists data_interrupcao   timestamptz;
