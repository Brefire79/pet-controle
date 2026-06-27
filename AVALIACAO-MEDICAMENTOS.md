# Avaliação PetCare — Controle de Medicamentos e Consultas

Análise do `index.html` (app PWA single-file, Vanilla JS + localStorage + sync Supabase).
Foco: controle de medicamentos **ministrados** e consultas.

> **Atualizado em 27/06/2026.** Boa parte das lacunas originais já foi implementada.
> Esta versão marca o que está **✅ feito**, **🟡 parcial** e **🔲 pendente**.

---

## 1. Como o controle de medicamento funciona hoje

Modelo de dados por medicamento (já evoluído para log de eventos):

```js
{
  id, nome, dose, freqHoras, diasTotais, dataInicio, active, alert,
  doses: [ { ts, nota, imported } ],   // cada administração = evento com data/hora
  dosesTomadas                         // derivado de doses.length
}
```

Fluxo atual:
- **Registrar Dose** (`abrirModalDose` → `confirmarDose`) grava `{ ts, nota }` no horário escolhido
  (já vem "agora", permite ajustar/retroagir) e reordena cronologicamente.
- `getDosesInfo()` calcula total de doses e progresso; `getStatusDose()` deriva
  "Dar agora" / "Atrasada Xh" / "Próxima em Xh" a partir de `última + freqHoras`.
- Quando `doses.length >= totalDoses` → `active = false` ("concluído").
- A UI mostra a **cartela de pips** (assinatura visual): doses tomadas, próxima e pendentes.

## 2. Estado das lacunas originais do "medicamentos ministrados"

| # | Lacuna original | Estado |
|---|---|---|
| 1 | Registro de QUANDO cada dose foi dada | ✅ `med.doses[{ts,nota}]` com timestamp |
| 2 | `freqHoras` não agendava próxima dose | ✅ `getProximaDose` / `getStatusDose` |
| 3 | Toggle "Criar Alerta" decorativo | 🟡 `pedirPermissaoNotificacao` + `checkDoseNotifications` (limitado a app aberto / limites de PWA) |
| 4 | Sem proteção anti-dose-dupla | ✅ confirma se o horário é antes da próxima prevista |
| 5 | Matemática do "mensal" frágil | ✅ mensal (720h × 30d) = 1 dose, via `Math.max/round` |
| 6 | `dataInicio` salvo e nunca usado | 🟡 salvo e migrado; cronograma deriva da última dose, não do início |
| 7 | Sem editar / nota por dose / pular | ✅ **edição de tratamento** (modo novo/editar) + nota por dose; 🔲 "pular dose" |
| 8 | PDF não listava doses ministradas | 🟡 PDF lista tratamentos; log de doses por dose ainda resumido |

## 3. Consultas

- Consulta fica em "Registros Clínicos" (`modal-registro`).
- ✅ **Campo de data própria** (default hoje, permite registrar consulta passada).
- ✅ **Retorno** com lembrete colorido (hoje / atrasado / em Xd), igual ao reforço de vacina.
- ✅ **Vet / clínica / custo** no formulário, na listagem e no PDF.
- 🔲 Sem anexo (foto de exame/receita).

## 4. Técnico / infra

- ✅ **Supabase** integrado: Auth email+senha, tabelas com RLS, push de migração local→nuvem.
  Enquanto `SUPABASE_URL`/`SUPABASE_ANON` estão vazios, roda em **modo local** (como antes).
- 🟡 **Sync é one-shot manual** (`enviarParaNuvem`): só INSERT, sem upsert/dedup nem
  sincronização das edições posteriores. Ver "data-integrity" na revisão de segurança.
- 🔲 **Service Worker** ainda sem cache real (offline depende do localStorage).
- 🔲 Ícones do manifest 192/512 apontam pro mesmo `icon.png`.

---

## 5. Próximas melhorias recomendadas (prioridade)

### ALTA
1. **Sync bidirecional / idempotente** — trocar o push one-shot por upsert por `id`
   estável, para editar/registrar dose direto na nuvem sem duplicar (base do offline-first do PRD).
2. **Escapar HTML** dos dados do usuário ao renderizar (XSS armazenado) — ver revisão de segurança.

### MÉDIA
3. ✅ ~~Consulta com data própria + retorno + vet/clínica/custo~~ (feito).
4. Incluir o log de doses ministradas detalhado no PDF.
5. "Pular dose" / marcar dose perdida.
6. Anexo de exame/receita na consulta; deleção que propaga e sync bidirecional entre devices.

### BAIXA
6. Cache real no Service Worker (offline de verdade).
7. Ícones distintos 192/512 no manifest.

---

## 6. Modelo de dados (medicamento) — atual

Já implementado conforme a sugestão original; `doses` é a fonte de verdade e
`dosesTomadas` é derivado. A migração (`migrarDosesParaLog`) converte contadores
antigos em entradas `imported: true` sem timestamp real.
