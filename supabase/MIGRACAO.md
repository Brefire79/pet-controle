# Migração para Supabase — Vianexx PetCare

Plano para sair do `localStorage` (single-device, sem login) para **Supabase** (Postgres + Auth email/senha + RLS), mantendo o app como **Vanilla JS PWA single-file** e a experiência offline.

---

## 1. Setup do projeto Supabase

1. Criar projeto no [supabase.com](https://supabase.com).
2. **Authentication → Providers → Email**: habilitar **Email + senha**. Decidir se exige confirmação de email (recomendado: sim em produção).
3. **SQL Editor**: rodar `supabase/schema.sql` (tabelas + RLS).
4. Copiar **Project URL** e **anon public key** (Settings → API). A anon key é segura no front por causa da RLS.

## 2. Incluir o cliente Supabase (CDN, sem build)

No `<head>` do `index.html`:

```html
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
```

E inicializar:

```js
const SUPABASE_URL  = 'https://SEU-PROJETO.supabase.co';
const SUPABASE_ANON = 'SUA_ANON_KEY';
const sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON);
```

> A anon key fica exposta no front — é o esperado. A segurança real é a RLS no banco.

## 3. Tela de login (email + senha)

Adicionar um overlay simples de auth (mesma estética dos modais). Funções:

```js
async function signUp(email, senha) {
  const { data, error } = await sb.auth.signUp({ email, password: senha });
  return { data, error };
}
async function signIn(email, senha) {
  const { data, error } = await sb.auth.signInWithPassword({ email, password: senha });
  return { data, error };
}
async function signOut() { await sb.auth.signOut(); }

sb.auth.onAuthStateChange((_event, session) => {
  if (session) iniciarApp(session.user);
  else mostrarTelaLogin();
});
```

Fluxo: sem sessão → tela de login; com sessão → carrega os pets do usuário e renderiza.

## 4. Camada de dados (abstrair `appData`)

Hoje tudo passa por `appData` + `saveData()` (localStorage). A migração troca isso por um **repositório** que fala com o Supabase, mantendo localStorage como **cache offline**.

Padrão sugerido por entidade (exemplo doses, o núcleo):

```js
// Registrar dose ministrada
async function addDose(medicamentoId, ts, nota) {
  // 1) grava local na hora (UX instantânea / offline)
  cacheAddDose(medicamentoId, { ts, nota });
  // 2) tenta sincronizar
  const { error } = await sb.from('doses')
    .insert({ medicamento_id: medicamentoId, ts, nota });
  if (error) filaPendente.push({ tabela: 'doses', op: 'insert', payload: { medicamento_id: medicamentoId, ts, nota } });
}

// Carregar doses de um tratamento
async function getDoses(medicamentoId) {
  const { data, error } = await sb.from('doses')
    .select('*').eq('medicamento_id', medicamentoId).order('ts', { ascending: true });
  return error ? cacheGetDoses(medicamentoId) : data;
}
```

Mapa de campos (app atual → tabela Supabase):

| App (localStorage) | Tabela | Observação |
|---|---|---|
| `perfil` | `pets` | vira 1+ pets por conta |
| `medicamentos[]` | `medicamentos` | `freqHoras`→`freq_horas`, `diasTotais`→`dias_totais` |
| `medicamentos[].doses[]` | `doses` | **núcleo**: `{ts, nota, imported}` |
| `vacinas[]` | `vacinas` | `dataAplicacao`→`data_aplicacao` |
| `registros[]` | `registros` | + `data`, `proximo_retorno`, `veterinario`, `custo` |
| `pesos[]` | `pesos` | |
| `alimentacao[]` | `alimentacao` | |

## 5. Importar dados existentes do tutor

No primeiro login, oferecer migrar o que já está no localStorage (`petcare_data_v3`):

1. Criar um `pet` com os dados de `appData.perfil`.
2. Para cada medicamento, inserir em `medicamentos` e depois suas `doses` (preservando `ts` e marcando `imported = true` quando vier da migração antiga sem horário real).
3. Inserir vacinas, registros, pesos e alimentação vinculados ao `pet_id`.
4. Confirmar sucesso e manter o backup local até a sincronização completar.

```js
async function migrarLocalParaSupabase(user) {
  const local = JSON.parse(localStorage.getItem('petcare_data_v3') || '{}');
  if (!local.perfil) return;
  const { data: pet } = await sb.from('pets').insert({
    owner_id: user.id,
    nome: local.perfil.nome, especie_raca: local.perfil.raca,
    nascimento: local.perfil.nascimento || null, castracao: local.perfil.castracao || null
  }).select().single();

  for (const m of (local.medicamentos || [])) {
    const { data: med } = await sb.from('medicamentos').insert({
      pet_id: pet.id, nome: m.nome, dose: m.dose,
      freq_horas: m.freqHoras, dias_totais: m.diasTotais,
      data_inicio: m.dataInicio, active: m.active, alert: m.alert
    }).select().single();
    if (m.doses?.length) {
      await sb.from('doses').insert(
        m.doses.map(d => ({ medicamento_id: med.id, ts: d.ts, nota: d.nota || null, imported: !!d.imported }))
      );
    }
  }
  // ... repetir para vacinas, registros, pesos, alimentacao
  localStorage.setItem('petcare_migrado', '1');
}
```

## 6. Sync offline (fila de escrita)

Manter uma fila de operações pendentes em localStorage. Ao voltar a conexão (`window.addEventListener('online', ...)`), reenviar a fila e limpar o que confirmar. Leituras caem no cache local quando offline. Isso preserva o caráter offline-first do PWA.

## 7. Ordem de execução recomendada

1. Rodar `schema.sql` no Supabase e validar a RLS (testar com 2 contas que uma não vê os dados da outra).
2. Adicionar o cliente Supabase e a tela de login (sem mexer no resto).
3. Implementar a camada de repositório por entidade, começando por **pets** e **medicamentos/doses** (o núcleo).
4. Implementar a importação do localStorage no primeiro login.
5. Adicionar a fila offline.
6. Migrar as demais entidades (vacinas, registros, pesos, alimentação).

## 8. Checklist de segurança

- [ ] RLS habilitada em **todas** as tabelas.
- [ ] Testado isolamento entre duas contas.
- [ ] Confirmação de email habilitada em produção.
- [ ] Anon key no front, service_role **nunca** no front.
- [ ] Política de exclusão de conta/dados (LGPD) definida.
