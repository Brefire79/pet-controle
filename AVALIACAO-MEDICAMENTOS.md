# Avaliação PetCare — Controle de Medicamentos e Consultas

Análise do `index.html` (app PWA single-file, Vanilla JS + localStorage).
Foco: controle de medicamentos **ministrados** e consultas.

---

## 1. Como o controle de medicamento funciona hoje

Modelo de dados por medicamento:

```js
{ id, nome, dose, freqHoras, diasTotais, dosesTomadas, dataInicio, active, alert }
```

Fluxo atual:
- "Dar Dose" / "Registrar Dose" chama `registrarDoseMed()` → faz **só** `med.dosesTomadas++`.
- `getDosesInfo()` calcula `totalDoses = (24/freqHoras) * diasTotais` e a barra de progresso.
- Quando `dosesTomadas >= totalDoses` → `active = false` ("finalizado").

## 2. Problemas e lacunas no "medicamentos ministrados" (o ponto crítico)

1. **Não existe registro de QUANDO cada dose foi dada.** É só um contador. Não dá pra
   saber se você já deu a dose de agora, que horas foi a última, nem auditar o histórico.
   Esse é o gap nº 1 — "ministrado" hoje é um número, não um evento.
2. **`freqHoras` não agenda nada.** A frequência existe no dado mas nunca é usada pra
   calcular a próxima dose nem horário. Não há "próxima dose em Xh".
3. **O toggle "Criar Alerta" (`med.alert`) é decorativo.** É salvo mas nenhuma
   notificação é criada (sem Notification API, sem agendamento). Promete e não entrega.
4. **Sem proteção contra dose dupla.** Dá pra tocar "Dar Dose" várias vezes seguidas;
   o contador só sobe, sem checar intervalo.
5. **Mensal (720h) tem matemática frágil.** `24/720 = 0,033` dose/dia. Com `Math.max(1,...)`
   um tratamento mensal vira ~1 dose. Mistura "frequência em horas" com "mensal" mal.
6. **`dataInicio` é salvo e nunca usado** — daria pra derivar o cronograma.
7. **Sem "dose perdida"/pular**, sem editar, sem nota por dose (deu com comida, vomitou, recusou).
8. **O PDF não lista as doses ministradas** — mostra o tratamento, não o log de administração.

## 3. Consultas — lacunas

- Consulta fica dentro de "Registros Clínicos" (`modal-registro`, tipo "Consulta de Rotina").
- **Sem campo de data** — usa sempre `new Date()` (hoje). Não dá pra registrar consulta passada.
- **Sem agendamento da próxima consulta** — não há lembrete de retorno (as vacinas têm reforço, consultas não).
- **Sem vet/clínica/custo** no registro de consulta.
- **Sem anexo** (foto de exame/receita).

## 4. Técnico (fora do escopo, mas importante)

- **Só localStorage.** Sem Firebase, apesar da sua stack. Um device, dados podem sumir.
- **Service Worker não faz cache real.** `CACHE_NAME` é declarado e nunca usado; o `fetch`
  é network-only com fallback de texto "Offline". O app não funciona offline de verdade.
- Ícones do manifest 192 e 512 apontam pro mesmo `icon.png`.

---

## 5. Melhorias recomendadas (prioridade)

### Prioridade ALTA — controle de doses ministradas
1. **Log de doses com timestamp.** Trocar o contador por uma lista:
   ```js
   med.doses = [{ ts: "2026-06-22T08:00:00", nota: "" }]
   // dosesTomadas = med.doses.length (derivado)
   ```
2. **Próxima dose.** `proxima = ultimaDose.ts + freqHoras` → exibir "Próxima dose em Xh",
   estado "Dar agora" / "Atrasada" (cores como já fazem nas vacinas).
3. **Guarda anti-dose-dupla.** Avisar se for dar dose antes do intervalo terminar.
4. **Notificação real.** Notification API quando a dose vence (dentro dos limites de PWA),
   e no mínimo estado visual "vence agora".

### Prioridade MÉDIA
5. Histórico de doses por tratamento + incluir no PDF.
6. Nota por dose (com comida / vomitou / recusou).
7. Permitir retroagir/editar dose.
8. Corrigir tratamento "mensal".

### Consultas
9. Campo de data na consulta (permitir registro retroativo).
10. Agendamento de retorno com lembrete (igual ao reforço de vacina).
11. Campos vet/clínica/custo.

### Infra
12. Sincronizar com Firebase (sua stack) pra não depender de um só device.
13. Cache real no Service Worker pra offline funcionar.

---

## 6. Sugestão de modelo de dados novo (medicamento)

```js
{
  id, nome, dose,
  freqHoras, diasTotais,
  dataInicio,
  active,
  alert,
  doses: [            // NOVO: cada administração é um evento
    { ts, nota }
  ]
  // dosesTomadas vira derivado: doses.length
}
```

Compatibilidade: na migração, criar `doses` vazio e preencher com N entradas
genéricas a partir de `dosesTomadas` antigo (sem timestamp real, marcadas como "importado").
