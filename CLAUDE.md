# NQ Trade Logger — CLAUDE.md

Lê este ficheiro completo antes de qualquer tarefa. É o briefing permanente do projeto.

---

## O que é este projeto

Web app de journaling profissional para trading de futuros NQ (Nasdaq Micro Futures) em prop firms (Lucid, My Funded Futures). O objetivo final é capturar trades com contexto de orderflow, descobrir edge estatístico, e gerar código de estratégia algorítmica.

**Trader:** Diogo Azevedo
**Prop firms:** Lucid, My Funded Futures
**Instrumento:** MNQ/NQ (Nasdaq Micro/Mini Futures)
**Estilo:** Macro-driven + Orderflow LTF execution (trend following)
**Plataforma de orderflow:** Deepcharts
**Análise macro:** MRKT.AI, ForexFactory, COT Reports, FedWatch

**URL live:** https://tiny-twilight-a74761.netlify.app/
**Repositório:** https://github.com/rdiogoazevedo33/nq-trade-logger

---

## Filosofia de trading — 3 Camadas de Análise

### Camada 1 — Macro & Profile Semanal (domingo/segunda)
- COT Reports — posicionamento hedge funds (commercial vs non-commercial)
- Geopolítica relevante para risk assets
- Eventos do calendário semanal com expectativas
- Fed narrative da semana
- Volume Profile semanal: POC, VAH/VAL, HVN/LVN semanais
- Delta Profile semanal: anomalias e absorção semana anterior
- Composite Volume Profile 3M: contexto médio prazo
- Bias semanal resultante

### Camada 2 — Macro & Profile Diário (manhã pré-mercado)
- Eventos do dia com expectativas e reacção esperada no NQ
- Fed narrative se houver speaker ou dados
- Volume Profile RTH: POC/VAH/VAL/HVN/LVN do dia anterior
- Delta Profile diário: anomalias, absorção
- S/R levels diários confirmados pelo semanal
- Bias diário: confirmado ou alterado face ao semanal

### Camada 3 — Execução LTF (durante e após sessão)
- Espera 15min após market open (9:30-9:45 ET)
- Confluências de orderflow na direcção do bias
- Registo no fim do dia: confluências, notas, prints, Risk/TP/SL

### Workflow diário completo
```
DOMINGO/SEGUNDA:
→ Preenche Macro & Profile Semanal na app
  - COT Reports, geopolítica, eventos semana
  - Volume Profile semanal, Delta semanal, Composite 3M
  - Bias semanal

MANHÃ PRÉ-MERCADO:
→ Preenche Pré-sessão na app
  - Profile Framing diário (POC/VAH/VAL/HVN/LVN)
  - Macro diário (eventos, Fed, sentiment, capital flow)
  - Game Plan do dia

DURANTE SESSÃO:
→ Opera no Deepcharts
→ Espera 15min após open (9:30-9:45 ET)
→ Entra na tendência com confluências de orderflow

FIM DO DIA:
→ Exporta CSV do Deepcharts
→ Importa na app (tab + CSV)
→ Para cada trade: preenche confluências, notas, prints, Risk/TP/SL
→ Documento do dia fica completo (pré-sessão + trades juntos)
```

---

## Stack técnica

- **Frontend:** Vanilla HTML/CSS/JS — ficheiro único `index.html`
- **Base de dados:** Supabase (PostgreSQL) + localStorage como fallback/cache
- **Hosting:** Netlify com deploy automático a partir do GitHub
- **Claude API:** Proxy seguro via Netlify Function (`netlify/functions/`)
- **Fonts:** IBM Plex Mono + DM Sans (Google Fonts)

## Estrutura do repositório

```
nq-trade-logger/
├── index.html              ← app completa (HTML/CSS/JS num único ficheiro)
├── CLAUDE.md               ← este ficheiro
├── netlify.toml            ← configuração Netlify
├── netlify/
│   └── functions/          ← proxy Claude API (API key não exposta no frontend)
└── README.md
```

---

## Storage keys

```javascript
const SK_A  = "nq10_a"   // accounts
const SK_T  = "nq10_t"   // trades (por conta e por data)
const SK_PS = "nq10_ps"  // pre-session data
```

Dados guardados em `localStorage` + sincronizados com Supabase via `sbPushKey()`.

---

## Estrutura de dados — Trade

```javascript
{
  id: string,
  date: "YYYY-MM-DD",
  time: "HH:MM",              // hora de entrada (ET)
  exit_time: "HH:MM",         // hora de saída (ET)
  time_slot: string,          // '09:30-10:00' | '10:00-10:30' | etc
  session: string,            // 'pre-orb' | 'orb' | 'post-orb' | 'afternoon'
  hold_time_seconds: number,
  symbol: string,             // "MNQ1!"
  direction: "Long"|"Short",
  entry: number,
  exit: number,
  qty: number,
  pnl: number,
  stop: number,
  tp: number,
  stop_ticks: number,         // stop loss em ticks
  tp_ticks: number,           // take profit em ticks
  rr: number,                 // risk/reward ratio planeado
  r: number,                  // R realizado (pnl/risk)
  confluences: JSON,          // array de {id, sr}
  score: number,              // nº de confluências
  rating: number,             // 1-5 estrelas
  notes: string,              // trade recap (texto livre)
  notes_html: string,
  screenshots: array,         // base64
  mistakes_note: string,      // erros (texto livre, opcional)
  session_date: "YYYY-MM-DD"  // referência à tabela sessions
}
```

## Estrutura de dados — Pre-Session (sessions)

```javascript
{
  date: "YYYY-MM-DD",
  account_id: string,

  // ANÁLISE SEMANAL
  weekly_cot: string,
  weekly_geopolitics: string,
  weekly_events: array,
  weekly_fed: string,
  weekly_poc: number,
  weekly_vah: number,
  weekly_val: number,
  weekly_hvn_lvn: array,
  weekly_delta: string,
  weekly_composite_poc: number,
  weekly_bias: string,
  weekly_narrative: string,

  // ANÁLISE DIÁRIA
  bias: "Bullish"|"Bearish"|"Neutro"|"Cauteloso",
  fed_narrative: "Hawkish"|"Neutral to Hawkish"|"Neutral"|"Neutral to Dovish"|"Dovish",
  fed_context: string,
  sentiment: "Risk-On"|"Risk-Off"|"Neutro",
  sentiment_narrative: string,
  capital_flow: string,
  dxy_vix_us2y_narrative: string,
  macro_events: array,        // [{name, impact, note}] — nota livre por evento
  geopolitics: string,

  // PROFILE FRAMING DIÁRIO
  poc_daily: number,
  poc_weekly: number,
  poc_composite: number,
  vah: number,
  val: number,
  hvn_levels: [{price, note}],
  lvn_levels: [{price, note}],
  delta_anomalies: [{price, type:"buy"|"sell", note}],
  supply_demand: [{type:"supply"|"demand", from, to, note}],
  sr_levels: [{price, type:"support"|"resistance", timeframe, note}],
  profile_notes: string,

  // DOCUMENTO FINAL
  narrative: string           // game plan do dia
}
```

---

## Tabs da aplicação (ordem)

1. **Dashboard** — métricas resumo + NQ Score + gráficos
2. **Diário** — lista de dias com filtros (período, bias, resultado)
3. **Trades** — lista de trades do dia selecionado
4. **+ CSV** — importação drag & drop do Deepcharts
5. **📰 Pré-sessão** — contexto diário (2 pilares)
6. **Reports** — análise estatística com sub-tabs
7. **Quant** — métricas quantitativas avançadas
8. **Calendário** — vista mensal

---

## Confluências (CONFS array)

```javascript
// Deep Trades
{ id: "dt-abs",  label: "Deep Trades + Absorption",  color: "#5b8fff", sr: false }
{ id: "dt-fol",  label: "Deep Trades + Follow Thru", color: "#18c9b0", sr: false }
{ id: "dt-sr",   label: "Deep Trades S/R",           color: "#60a5fa", sr: true  }

// Volume Profile
{ id: "hvn",     label: "HVN",                       color: "#1fd17a", sr: true  }
{ id: "lvn",     label: "LVN",                       color: "#34d399", sr: true  }
{ id: "poc",     label: "POC",                       color: "#818cf8", sr: true  }
{ id: "vsi",     label: "Vol. Stacked Imbalance",    color: "#fbbf24", sr: true  }
{ id: "fa",      label: "Failed Auction (VAL/VAH)",  color: "#fb923c", sr: true  }

// Outros
{ id: "vwap",    label: "VWAP Bounce",               color: "#9b72f5", sr: false }
{ id: "delta",   label: "Delta Anomaly",             color: "#a78bfa", sr: false }
```

Confluências com `sr: true` têm toggles S (Support) / R (Resistance).

O utilizador pode adicionar confluências customizadas via "+ Nova confluência" no review de trade. Guardadas na tabela Supabase `custom_confluences` e aparecem junto às base.

---

## Time slots e sessões

```javascript
// Time slots (buckets de 30min)
'pre-orb'      // 09:00–09:30
'09:30-10:00'  // ORB — Opening Range
'10:00-10:30'
'10:30-11:00'
'11:00-11:30'
'11:30-12:00'
'12:00+'

// Sessions (agrupamentos)
'pre-orb'    // Pré-ORB (09:00–09:30)
'orb'        // ORB (09:30–10:30)
'post-orb'   // Pós-ORB (10:30–12:00)
'afternoon'  // Tarde (12:00+)
```

---

## Reports — sub-tabs existentes

- **Overview** — métricas globais (30+ stats)
- **Detailed** — breakdown por Days/Weeks/Months/Time/Confluence/Fed
- **Wins vs Losses** — comparação e distribuição R-Multiple
- **Calendário** — vista de calendário nos reports

---

## Pré-sessão — 2 Pilares

### Pilar 1 — Profile Framing
- POC Diário, Semanal, 3M Composto
- VAH, VAL
- HVN levels (lista dinâmica)
- LVN levels (lista dinâmica)
- Delta Anomalies (lista dinâmica)
- Supply/Demand Zones (lista dinâmica)
- S/R Levels (lista dinâmica)
- Leitura do Profile (textarea livre)

### Pilar 2 — Macro & Fundamental
- Bias do dia (Bullish/Bearish/Neutro/Cauteloso)
- Fed Narrative (Hawkish → Dovish, 5 opções)
- Fed Context (textarea)
- Sentiment (Risk-On/Risk-Off/Neutro)
- Sentiment narrative, Capital flow, DXY/VIX/US2Y narrativa, Geopolítica
- Macro Events — lista dinâmica simplificada:
  - Eventos rápidos: NFP, CPI, FOMC, PCE, GDP, ISM, PPI, Retail Sales, Fed Chair Speaks, President Speaks, Average Hourly Earnings, etc.
  - Cada evento tem: nome, impacto (LOW/MED/HIGH) e nota livre (textarea pequena)
  - Sem campos Actual/Forecast/Bullish/Bearish
- Game Plan do dia (textarea grande — narrativa unificada)

---

## Funcionalidades Claude API existentes

- **✦ Edge Finder** — botão nos Reports, analisa edge por confluência
- **✦ Analisar dia** — botão na aba Trades, analisa o dia atual
- **✦ Análise semanal** — overview semanal com padrões
- Proxy via `netlify/functions/` — Claude API key não exposta no frontend

---

## NQ Score — fórmula

```javascript
winScore    = winRate * 100
pfScore     = Math.min(profitFactor / 3 * 100, 100)
sharpeScore = Math.min(sharpe / 2 * 100, 100)
nqScore     = (winScore * 0.35) + (pfScore * 0.35) + (sharpeScore * 0.30)

// Labels por amostra:
// < 10 trades:  "Amostra pequena ⚠"
// 10-30 trades: "A desenvolver"
// > 30 trades:  "Estável" (ou "Robusto" se score > 75)
```

---

## CSV format (Deepcharts)

```
Symbol;DT;Quantity;Entry;Exit;ProfitLoss
MNQ;2025-10-20 09:31:18;1;21450.75;21480.25;59.00
```

- Separador: `;`
- DT = timestamp completo (data + hora ET)
- Quantity negativa = Short
- Pode ter múltiplas linhas por trade (partial fills)
- Hora mais cedo = entry time, hora mais tarde = exit time
- Importação por drag & drop na tab `+ CSV`

---

## Contas pré-definidas

```javascript
{ id: "lucid", name: "Lucid",             emoji: "🔵" }
{ id: "mff",   name: "My Funded Futures", emoji: "🟢" }
```

---

## Design system

```css
--bg:     #07080c
--s1:     #0d0f16   /* card background */
--s2:     #131720
--s3:     #191e2a
--b1:     #222840   /* border */
--b2:     #2c3450
--text:   #dde2f0
--sub:    #8892aa
--hint:   #4a5268
--green:  #1fd17a
--red:    #f04f4f
--amber:  #f0a832
--accent: #5b8fff
--purple: #9b72f5
--teal:   #18c9b0
--mono:   'IBM Plex Mono'
--sans:   'DM Sans'
```

---

## Fases do projeto

| Fase | Descrição | Estado |
|------|-----------|--------|
| 1 | Reports — 30+ métricas | ✅ Completo |
| 2 | Daily Journal por sessão | ✅ Completo |
| 3 | Dashboard + NQ Score | ✅ Completo |
| 4 | Review: NQ Scale + Mistakes + Process Score | ✅ Completo |
| 5 | Timestamps + time slot filters nos Reports | ✅ Completo |
| — | Reestruturação Pré-sessão (2 pilares + semanal) | ✅ Completo |
| — | Tweaks UI: review redesign, macro simplificado, diário+pré-sessão link, limpar tudo | ✅ Completo |
| 6 | Edge Explorer manual (EV/WR/PF por confluência+hora+bias+Fed) | ⏳ Por fazer |
| 7 | IA Edge Finder — identificação A+ setups | ⏳ Por fazer |
| 8 | Geração código Pine Script / Python | ⏳ Por fazer |

---

## Regras de desenvolvimento — NUNCA VIOLAR

1. **Nunca criar ficheiros separados** — tudo vai no `index.html` (CSS, JS, HTML juntos)
2. **Não usar frameworks** — vanilla JS apenas, sem React/Vue/etc
3. **Não usar npm/node** — sem dependências externas além das já existentes
4. **Preservar design system** — usar sempre as CSS variables, nunca hardcode cores
5. **Supabase sync** — qualquer novo dado guardado em localStorage deve ser
   sincronizado via `sbPushKey()`
6. **Secrets seguros** — Claude API key e Supabase service key via Netlify Functions,
   nunca expostos no frontend
7. **RLS activo** — todas as tabelas têm user_id com políticas Row Level Security
8. **Português europeu** — todos os textos da UI em português europeu
9. **Não quebrar funcionalidades existentes** — listar sempre ficheiros alterados
10. **Migration SQL** — sempre incluir se alterar schema Supabase
11. **Commits descritivos** — ex: "feat: Fase 6 Edge Explorer — breakdown por confluência"

---

## Environment Variables (Netlify)

```
ANTHROPIC_API_KEY    = sk-ant-...
SUPABASE_URL         = https://xxx.supabase.co
SUPABASE_SERVICE_KEY = eyJ...
```

Configurar em: Netlify Dashboard → Site Settings → Environment Variables

---

## Próxima tarefa prioritária

**Fase 6 — Edge Explorer** — criar sub-tab nos Reports (ver secção abaixo).

---

## Review de Trade — Layout actual

**Painel esquerdo:** Símbolo, Direcção, Entry, Exit, Qty, PnL, Stop Loss (ticks + $), Take Profit (ticks + $), R-Multiple, Rating (estrelas), Confluências (chips + "+ Nova confluência").

**Cálculo ticks → $:**
- MNQ: ticks × $0.50 × qty
- NQ:  ticks × $5.00 × qty
- MCL: ticks × $1.00 × qty
- CL:  ticks × $10.00 × qty

**Painel direito (de cima para baixo):**
1. Prints do Setup (drag & drop, thumbnails com X)
2. Trade Recap (textarea livre)
3. Erros — opcional (textarea pequena; se vazio, não aparece no view)

**Confluências customizadas:** tabela Supabase `custom_confluences` (id, user_id, account_id, label, color, has_sr). Criadas via mini form inline no review.

---

## Diário — comportamento actual

Ao expandir um dia mostra no topo:
- Badge Bias + Badge Fed + Badge Sentiment (da pré-sessão)
- Primeiras 100 chars do Game Plan
- Link "Ver pré-sessão completa →" (navega para tab Pré-sessão com esse dia)
- Se sem pré-sessão: "○ Sem pré-sessão — clica para preencher →"

---

## Fase 6 — Edge Explorer

Criar nova sub-tab nos Reports com EV, Win Rate e Profit Factor por:
- Confluência (cada uma das 10)
- Time slot (pre-orb, orb, post-orb, afternoon)
- Bias do dia (Bullish, Bearish, Neutro, Cauteloso)
- Fed context (Hawkish, Neutral, Dovish)

Cruzamentos: confluência × bias, confluência × time slot, time slot × bias, etc.
Análise humana primeiro — IA por cima na Fase 7.
Amostra mínima para confiar nos números: 30+ trades por condição.
