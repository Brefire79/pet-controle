# PRD — Vianexx PetCare

**Produto:** PetCare (repo `pet-controle`)
**Empresa:** Vianexx AI
**Autor:** Breno Luis (co-fundador)
**Versão do documento:** 1.0
**Data:** 22/06/2026
**Status:** Em definição

---

## 1. Visão

PetCare é o app de saúde do pet da Vianexx: um PWA leve, offline-first, que dá ao tutor o controle real da rotina de cuidados do animal — medicamentos, vacinas, peso, consultas e dieta — com foco no que hoje quase nenhum app faz bem: **o registro fiel de cada dose ministrada, com data e hora**.

A aposta é simplicidade radical (estética Apple, sem fricção) somada a um histórico clínico confiável que vale como prontuário — algo que o tutor pode levar ao veterinário e exportar em PDF.

## 2. Problema

Tutores esquecem doses, perdem reforços de vacina e chegam ao veterinário sem histórico. As soluções existentes ou são cadernos de papel (sem alerta, sem backup) ou apps inchados de agenda/loja que pedem cadastro pesado e não tratam o controle de medicação com seriedade. Falta uma ferramenta que responda com precisão: *"Já dei o remédio hoje? Que horas foi a última dose? Quantas faltam?"*

## 3. Objetivos e métricas de sucesso

O objetivo central é que o tutor confie no app como fonte única da saúde do pet. Traduzindo em métricas:

| Métrica | Meta (6 meses pós-lançamento) |
|---|---|
| Tutores ativos semanais (WAU) | 2.000 |
| Retenção D30 | ≥ 35% |
| Doses registradas por tratamento ativo / semana | ≥ 80% das previstas |
| Tratamentos concluídos sem dose esquecida | ≥ 60% |
| Exportações de prontuário (PDF) por usuário ativo / mês | ≥ 0,5 |
| Contas com mais de 1 pet | ≥ 25% |

Não-objetivos nesta fase: marketplace de produtos, telemedicina, agenda de clínicas, rede social de pets.

## 4. Público-alvo

O usuário primário é o **tutor responsável** — pessoa que cuida do dia a dia do animal e quer organização. Secundário, o **tutor cuidador temporário** (familiar, pet sitter) que precisa saber se a dose já foi dada. Mais à frente, o **veterinário** como leitor do prontuário exportado. O app nasce mobile-first (PWA instalável via Capacitor para lojas).

## 5. Escopo do produto

### 5.1 Contas e multi-pet (novo)

Hoje o app é single-device e sem login. A virada é introduzir **conta por email e senha** (Supabase Auth) com dados na nuvem, permitindo:

- Um tutor com **vários pets** na mesma conta, alternando entre eles.
- Sincronização entre dispositivos (celular + tablet + web).
- Backup automático (fim do risco de perder tudo ao limpar o navegador).

### 5.2 Controle de medicamentos ministrados (núcleo)

Cada administração é um **evento com data, hora e observação**, não um contador. O app calcula a próxima dose (última + frequência), sinaliza "dar agora" / "atrasada", avisa por notificação e protege contra dose dupla. Histórico completo por tratamento, exportável. Esta é a feature de maior valor e diferenciação.

### 5.3 Vacinas

Carteira de vacinação com data de aplicação, reforço e veterinário responsável; contadores e alertas de reforço próximo/atrasado.

### 5.4 Consultas e registros clínicos (a evoluir)

Registro de consultas, sintomas, exames e procedimentos. Evoluções planejadas: **data própria** (permitir registrar consulta passada), **lembrete de retorno** (agendar próxima consulta como faz o reforço de vacina), e campos de **veterinário, clínica e custo**.

### 5.5 Peso e dieta

Gráfico de evolução de peso e histórico de dieta/ração, com variação entre pesagens.

### 5.6 Prontuário PDF

Exportação de um documento de saúde consolidado: perfil, vacinas, ocorrências, tratamentos e **log de doses ministradas**.

## 6. Requisitos funcionais (resumo)

O sistema deve permitir ao tutor autenticado: criar e alternar entre pets; cadastrar tratamentos com nome, dose, frequência e duração; registrar cada dose escolhendo data/hora e observação; ver próxima dose e progresso; receber notificação quando a dose vence; desfazer a última dose; registrar vacinas com reforço; lançar peso, dieta, consultas e exames; exportar o prontuário em PDF; e ter todos os dados sincronizados e protegidos por conta.

## 7. Requisitos não-funcionais

O app deve ser **offline-first** (funcionar sem rede e sincronizar ao reconectar), responsivo mobile-first, instalável como PWA, e respeitar a privacidade dos dados (cada conta só acessa os próprios dados, via RLS no Supabase). Desempenho de carga inicial inferior a 2s em 4G. Acessibilidade básica (contraste, toque mínimo 44px).

## 8. Arquitetura técnica

Mantém-se a stack atual da Vianexx, de forma incremental:

- **Frontend:** Vanilla JS, PWA single-file (`index.html`), Tailwind via CDN, Chart.js, html2pdf, Lucide.
- **Backend/Dados:** Supabase (Postgres + Auth + Row Level Security), via `@supabase/supabase-js` carregado por CDN.
- **Auth:** email + senha (Supabase Auth).
- **Empacotamento:** Netlify (web) + Capacitor (lojas).
- **Sync offline:** cache local (localStorage como fila/cache) + escrita no Supabase ao reconectar; o esquema e o plano de migração estão em `supabase/MIGRACAO.md`.

A migração do localStorage para o Supabase é gradual: a camada de dados atual (`appData` + `saveData`) é abstraída para um módulo de repositório que decide entre cache local e nuvem, preservando a experiência offline.

## 9. Roadmap (Now / Next / Later)

**Now** — Autenticação email+senha, modelo Supabase com RLS, migração dos dados locais para a conta, multi-pet básico. Manter todas as features atuais funcionando.

**Next** — Sync offline robusto (fila de escrita), evolução de consultas (data própria, retorno, vet/custo), notificações mais confiáveis, compartilhamento de pet entre cuidadores.

**Later** — App nas lojas via Capacitor, prontuário compartilhável por link com o veterinário, lembretes inteligentes, planos pagos (backup estendido, múltiplos cuidadores, relatórios).

## 10. Monetização (hipótese)

Modelo freemium: grátis para 1 pet com todas as features de controle; plano Vianexx PetCare+ (assinatura mensal) para múltiplos pets, múltiplos cuidadores por conta, histórico ilimitado e prontuário compartilhável. A validar com os números de retenção e de contas multi-pet antes de investir.

## 11. Riscos e mitigação

O maior risco técnico é a **confiabilidade das notificações** em PWA (limitações de background em iOS) — mitigação: reforço visual forte de "dose atrasada" ao abrir o app, e avaliação de notificações nativas via Capacitor. O risco de produto é **fricção do login** afastar quem hoje usa sem cadastro — mitigação: permitir uso local e oferecer criar conta para sincronizar, migrando os dados existentes sem perda. Risco de dados: garantir RLS correto desde o início para isolamento entre contas.

## 12. Questões em aberto

Definir se haverá modo "convidado" (uso local sem conta) no lançamento ou se o login será obrigatório. Definir política de retenção/exclusão de dados (LGPD). Definir se compartilhamento de pet entra no Next ou Later.
