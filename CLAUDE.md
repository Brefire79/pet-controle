# CLAUDE.md — Projeto Vianexx PetCare

Regras específicas do Claude para este repositório. Complementa o `AGENTS.md`.

## Contexto

Projeto **PetCare** (`pet-controle`) da **Vianexx AI**. PWA Vanilla JS single-file (`index.html`) para controle de saúde de pets, com foco em **medicamentos ministrados** (cada dose = evento com data/hora). Migrando dados de `localStorage` para **Supabase** (Postgres + Auth email/senha + RLS). Ver `PRD.md`, `AGENTS.md`, `supabase/`.

## Antes de qualquer tarefa

- Leia o `PRD.md` e o trecho relevante do `index.html`.
- Faça perguntas (use o recurso de perguntas) quando algo estiver ambíguo. Não adivinhe.
- Mostre um plano curto e **espere aprovação** antes de implementar.

## Regras

- **Vanilla JS, sem frameworks** e sem etapa de build, a menos que eu peça.
- **Nunca delete arquivos** sem minha aprovação.
- **Não misture projetos** — este é o `pet-controle` / PetCareApp.
- **Não faça `git push`** — eu comito e subo. Pode preparar a mensagem de commit.
- **Sugira melhorias**, mas não implemente sem aprovação.
- **Supabase:** toda tabela nova nasce com RLS. `anon key` pode no front; `service_role` nunca.
- **Offline-first:** preserve o funcionamento sem rede em qualquer mudança de dados.

## Tom

- Descontraído e direto. Sem enrolação. Mostra código, plano, solução.
- Formal só em documentação (PRD, contrato).
- Se não entendeu, pergunta.

## Stack

Vanilla JS · Supabase (Postgres/Auth/RLS) · Tailwind/Chart.js/Lucide/html2pdf via CDN · Netlify · Capacitor · GitHub `Brefire79` · VS Code.

## Sobre mim

Breno, co-fundador da Vianexx AI (ex-AmbFusi AI), dev fullstack PWA. Formado em Ciências da Computação (UNIESP, 2009).
