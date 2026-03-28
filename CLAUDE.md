# NQ Trade Logger — CLAUDE.md

Lê este ficheiro completo antes de qualquer tarefa. É o briefing permanente do projeto.

---

## O que é este projeto

Web app de journaling profissional para trading de futuros NQ (Nasdaq Micro Futures) em prop firms (Lucid, My Funded Futures). O objetivo final é capturar trades com contexto de orderflow, descobrir edge estatístico, e gerar código de estratégia algorítmica.

**URL live:** https://tiny-twilight-a74761.netlify.app/
**Repositório:** https://github.com/rdiogoazevedo33/nq-trade-logger

---

## Stack técnica

- **Frontend:** Vanilla HTML/CSS/JS — ficheiro único `index.html` (3955 linhas)
- **Base de dados:** Supabase (PostgreSQL) + localStorage como fallback/cache
- **Hosting:** Netlify com deploy automático a partir do GitHub
- **Claude API:** Proxy seguro via Netlify Function (`netlify/functions/`)
- **Fonts:** IBM Plex Mono + DM Sans (Google Fonts)

## Estrutura do repositório

```
nq-trade-logger/
├── index.html              ← app completa (HTML/CSS/JS num único ficheiro)
├── netlify.toml            ← configuração Netlify
├── netlify/
│   └── functions/          ← proxy Claude API (API key não exposta no frontend)
└── README.md
```

---

## Storage

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
  time: "HH:MM",           // hora de entrada (ET)
  exit_time: "HH:MM",      // hora de saída (ET)
  hold_time_seconds: number,
  symbol: string,          // "MNQ1!"
  direction: "Long"|"Short",
  entry: number,
  exit: number,
  qty: number,
  pnl: number,
  stop: number,
  tp: number,
  rr: number,              // risk/reward ratio
  confluences: JSON,       // array de {id, sr}
  notes: string,
  mistakes: array,
  process_score: number    // 0-4
}
```

## Estrutura de dados — Pre-Session

```javascript
{
  date: "YYYY-MM-DD",
  bias: "Bullish"|"Bearish"|"Neutro"|"Cauteloso",
  fed: "Hawkish"|"Neutral to Hawkish"|"Neutral"|"Neutral to Dovish"|"Dovish",
  fedCtx: string,
  sentiment: "Risk-On"|"Risk-Off"|"Neutro",
  sentiment_narrative: string,
  capital_flow: string,
  dxy_vix_narrative: string,
  geopolitics: string,
  narrative: string,
  poc_daily: number,
  poc_weekly: number,
  poc_3m: number,
  vah: number,
  val: number,
  hvn_levels: [{price, note}],
  lvn_levels: [{price, note}],
  delta_anomalies: [{price, type:"buy"|"sell", note}],
  supply_demand_zones: [{type:"supply"|"demand", from, to, note}],
  sr_levels: [{price, type:"support"|"resistance", note}],
  profile_notes: string,
  macroEvents: array
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

---

## Time slots e sessões (Fase 5 — já implementado)

```javascript
// Time slots (30min buckets)
'pre-orb' | '09:30' | '10:00' | '10:30' | '11:00' | '11:30' | '12:00+'

// Sessions
'pre-orb' → Pré-ORB
'orb'     → ORB (9:30–10:30)
'post-orb'→ Pós-ORB (10:30–12:00)
'afternoon'→ Tarde (12:00+)
```

---

## Reports — sub-tabs existentes

- **Overview** — métricas globais
- **Detailed** — breakdown detalhado
- **Wins vs Losses** — comparação
- **Calendário** — vista de calendário nos reports
- **⏱ Tempo** — análise por time slot (Fase 5)

---

## Pré-sessão — 2 Pilares

**Pilar 1 — Profile Framing**
- POC Diário, Semanal, 3M Composto
- VAH, VAL
- HVN levels (dinâmico)
- LVN levels (dinâmico)
- Delta Anomalies (dinâmico)
- Supply/Demand Zones (dinâmico)
- S/R Levels (dinâmico)
- Leitura do Profile (textarea)

**Pilar 2 — Macro & Fundamental**
- Bias do dia (Bullish/Bearish/Neutro/Cauteloso)
- Fed Narrative (Hawkish → Dovish, 5 opções)
- Fed Context (textarea)
- Sentiment Risk-On/Off/Neutro
- Sentiment narrative, Capital flow, DXY/VIX narrative, Geopolitics
- Macro Events (calendário)

---

## Funcionalidades Claude API existentes

- **✦ Edge Finder** — botão nos Reports, analisa edge por confluência
- **✦ Analisar dia** — botão na aba Trades, analisa o dia atual
- Proxy via `netlify/functions/` — Claude API key não exposta

---

## Fases do projeto

| Fase | Descrição | Estado |
|------|-----------|--------|
| 1 | Reports — 30+ métricas | ✅ Completo |
| 2 | Daily Journal | ✅ Completo |
| 3 | Dashboard + NQ Score | ✅ Completo |
| 4 | Review enhancements (mistakes, process score) | ✅ Completo |
| 5 | Timestamps + time slot filters em Reports | ✅ Estrutura criada, refinar |
| 6 | Edge Explorer — EV/WR/PF por confluência + time slot + bias + Fed | ⏳ Por fazer |
| 7 | AI Edge Finder melhorado — identificação A+ setups | ⏳ Por fazer |
| 8 | Geração de código Pine Script / Python | ⏳ Por fazer |

---

## NQ Score — fórmula

```javascript
NQ Score = (winRate × 0.35) + (min(PF/3 × 100, 100) × 0.35) + (min(sharpe/2 × 100, 100) × 0.30)
```

---

## CSV format (Deepcharts)

```
Symbol;DT;Quantity;Entry;Exit;ProfitLoss
```
- Separador: `;`
- DT = timestamp completo (data + hora)
- Importação por drag & drop na aba `+ CSV`

---

## Design system

```css
--bg: #07080c
--s1: #0d0f16    /* card background */
--s2: #131720
--s3: #191e2a
--b1: #222840    /* border */
--b2: #2c3450
--text: #dde2f0
--sub: #8892aa
--hint: #4a5268
--green: #1fd17a
--red: #f04f4f
--amber: #f0a832
--accent: #5b8fff
--purple: #9b72f5
--teal: #18c9b0
--mono: 'IBM Plex Mono'
--sans: 'DM Sans'
```

---

## Regras de desenvolvimento

1. **Nunca criar ficheiros separados** — tudo vai no `index.html` (CSS, JS, HTML juntos)
2. **Não usar frameworks** — vanilla JS apenas, sem React/Vue/etc
3. **Não usar npm/node** — sem dependências externas além das já existentes
4. **Preservar o design system** — usar sempre as CSS variables existentes
5. **Supabase sync** — qualquer novo dado guardado em localStorage deve também ser sincronizado via `sbPushKey()`
6. **Testar antes de fazer deploy** — verificar que não quebra funcionalidades existentes
7. **Commits descritivos** — ex: "feat: Fase 6 Edge Explorer — breakdown por confluência"

---

## Contas pré-definidas

```javascript
{ id: "lucid", name: "Lucid", emoji: "🔵" }
{ id: "mff",   name: "My Funded Futures", emoji: "🟢" }
```

---

## Próxima tarefa prioritária

**Fase 6 — Edge Explorer**
Criar nova sub-tab nos Reports com tabela de EV, Win Rate e Profit Factor quebrados por:
- Confluência (cada uma das 10)
- Time slot (pre-orb, orb, post-orb, afternoon)
- Bias do dia (Bullish, Bearish, Neutro, Cauteloso)
- Fed context (Hawkish, Neutral, Dovish)

Cruzamentos: confluência × bias, confluência × time slot, etc.
