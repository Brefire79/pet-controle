# AGENTS.md — Vianexx PetCare

Instruções para agentes de IA que trabalham neste repositório (`pet-controle`).
Formato neutro/multiplataforma. O `CLAUDE.md` complementa com regras específicas do Claude.

## Sobre o projeto

- **Produto:** PetCare — PWA de saúde do pet (medicamentos, vacinas, peso, consultas, dieta).
- **Empresa:** Vianexx AI.
- **Foco do produto:** controle fiel de **medicamentos ministrados** (cada dose é um evento com data/hora). Ver `PRD.md`.

## Stack

- **Frontend:** Vanilla JS (sem frameworks), PWA **single-file** em `index.html`.
- **CSS/UI:** Tailwind via CDN, Lucide (ícones), Chart.js (gráficos), html2pdf (PDF).
- **Backend/Dados:** Supabase (Postgres + Auth + RLS). Cliente via CDN `@supabase/supabase-js@2`.
- **Auth:** email + senha.
- **Deploy:** Netlify (web) + Capacitor (lojas). GitHub: `Brefire79/pet-controle`.

## Regras de ouro

1. **Não introduza frameworks** (React, Vue, etc.) nem etapa de build. Mantém-se Vanilla JS single-file, salvo pedido explícito.
2. **Não delete arquivos** sem aprovação.
3. **Não misture projetos** — este é o `pet-controle` / PetCareApp.
4. **Dados sensíveis:** nunca commitar chaves. A `anon key` do Supabase pode ir no front (a segurança é a RLS); a `service_role` **jamais** no front.
5. **Offline-first:** qualquer mudança na camada de dados deve preservar o funcionamento sem rede (cache local + fila de sync).
6. **RLS sempre:** toda tabela nova no Supabase nasce com Row Level Security e policy de pertencimento ao dono.

## Convenções de código

- JS em português nos nomes de domínio (`registrarDose`, `getProximaDose`), seguindo o código existente.
- Estado do app em memória + persistência; ao migrar para Supabase, isolar acesso a dados numa camada de repositório (não espalhar chamadas `sb.from(...)` pela UI).
- Datas de doses sempre em ISO (`toISOString`) e ordenadas cronologicamente.
- Renderização por funções `renderX()` que reconstroem o HTML da seção.

## Estrutura

```
index.html            # o app inteiro (PWA single-file)
PRD.md                # visão de produto (Vianexx)
AGENTS.md             # este arquivo
CLAUDE.md             # regras específicas do Claude
supabase/schema.sql   # tabelas + RLS
supabase/MIGRACAO.md  # plano de migração localStorage -> Supabase
AVALIACAO-MEDICAMENTOS.md  # avaliação técnica do módulo de medicamentos
```

## Fluxo de trabalho esperado

1. Antes de mexer, leia `PRD.md` e o trecho relevante de `index.html`.
2. Proponha um plano curto e espere aprovação antes de implementar.
3. Faça mudanças pequenas e revisáveis; explique o que mudou.
4. Não faça `git push` sem combinar — o dono comita.
