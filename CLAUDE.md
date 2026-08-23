# NQ Trade Logger

Personal trade journal for discretionary and semi-auto NQ/MNQ futures trading.
Single-file vanilla web app. Rebuilt from scratch in August 2026.

Live: https://tiny-twilight-a74761.netlify.app
Repo: https://github.com/rdiogoazevedo33/nq-trade-logger

## Purpose

This journal measures EXECUTION ADHERENCE. It compares realised performance
against the expected performance of an already-validated setup, and diagnoses
where execution leaks it: stops too tight, entries without required orderflow
confirmation, emotional re-entries, winners cut short.

It does NOT discover edge. Any feature that mines logged trades for new
if-then rules is out of scope — that is data mining on a small sample and
produces noise. If asked for something that drifts into that, say so before
implementing.

Algorithmic trading is entirely out of scope for this app. There is no human
decision to evaluate, and mixing the two P&L streams corrupts both.

## Non-negotiable conventions

- Everything lives in a single index.html — HTML, CSS and JS together.
  Never create separate files.
- Vanilla JS only. No frameworks, no React, no Vue, no npm, no bundler,
  no build step.
- Preserve the existing design system CSS variables: --bg, --accent, --green,
  --red, --purple, --mono, --sans. Do not introduce a parallel palette.
- Any new data written to localStorage MUST also sync to Supabase via
  sbPushKey(). localStorage-only state is a bug, not a shortcut.
- Code and comments in English. Responses to the user in European Portuguese.
- Match existing patterns in the file. Read surrounding code before adding.

## Stack

Netlify (auto-deploy from main) + Supabase (Postgres + Storage).
Netlify Function proxies the Anthropic API.
Local repo: C:\Users\Utilizador\Documents\nq-trade-logger

## Supabase

Project: nq-trade-logger (ref zjwpfldjpcjigywbrxtw, eu-west-1)

Schema verified live on 23/08/2026. Four tables, all with RLS enabled and
all EMPTY at rebuild time — there is no legacy data to migrate.

  trades       id, user_id, account_id, data (jsonb), screenshots (jsonb),
               updated_at. PK (id, user_id)
  sessions     date, user_id, data (jsonb), screenshots (jsonb), updated_at.
               PK (date, user_id). NOTE: account_id is missing and must be added.
  weekly_prep  week_start, user_id, account_id, screenshot/notes columns
  user_data    key/value store (jsonb). Holds settings and the error catalogue.

Trade and session fields live inside the jsonb `data` blob, so adding fields
requires no schema migration.

SAFETY RULES:
- Before any direct write, confirm table and column names by live query.
  Never assume from a spec file, from this document, or from memory.
- Before any direct write, confirm the correct account_id. Lucid Trading and
  My Funded Futures are separate accounts and have been confused before.
  account_id separates prop firms — never discretionary from algo.
- After any direct write, refresh the app. Without a refresh the app's own
  sbPushKey overwrites the change with stale in-memory state.

## Trade record

From the Rithmic CSV, automatically:
  date, entry time, exit time, duration, symbol, direction, entry price,
  exit price, quantity, P&L, order number (for idempotent re-import)

Entered manually:
  planned stop, planned target, grade, error codes, recap text, screenshots

Computed:
  planned R, realised R

## Rithmic CSV import

Source: "Recent Orders" export. Format quirks:
- Two sections in one file (Working Orders, Completed Orders) with DIFFERENT
  headers, separated by blank lines. Parser must handle both.
- It is an ORDERS export, not a trades export. Trades must be reconstructed
  from order pairs.
- There is NO P&L column and no floating profit. P&L is computed from fill
  prices.
- Timestamps are GMT and must be converted to ET.
- Order Number is unique and stable — use it to prevent duplicate imports.
- Partial fills are ambiguous (only "Qty To Fill" is present).
- Cancelled limit orders are bracket targets. Not currently used.

## Risk fields

Planned stop and target can be entered in ticks OR in dollars.
Dollar dropdown: 30 / 35 / 40 / 45 / 50, plus free entry.

Conversion: MNQ is $0.50 per tick PER CONTRACT. Always use the contract
quantity from the imported trade to convert — never assume 1 contract, or the
R calculation breaks whenever size changes.

## Grading

Single four-grade scale, measuring how much of the trade's available value was
captured. Dropdown, with the definition shown on selection.

  A+  Reached 2R or more with clean execution throughout. Minimal drawdown,
      entry at the intended level, management by plan, full move taken.
  A   Good thesis and execution, but stopped out in profit before target.
      It won, and the winner was cut.
  B   Any stop loss, or any winner too short to bring value to the account.
      Thesis quality does not lift a stopped trade out of B.
  F   No process. Deserved stop, no organisation, no thesis. Gambling.

There is no separate star rating. The grade already carries execution quality.

## Error codes

Behaviour, not outcome. A losing trade that was well executed carries no code;
a winning trade that was badly managed does.

One primary code per trade, secondary codes where genuinely distinct.
A trade with no codes is a clean trade — there is no tag for that.

Initial catalogue, user-editable and extensible from the UI:

  BE_PREMATURO   Stop moved to break-even on a dollar trigger rather than a
                 structural pivot failing
  FOMO           Entered a trade recognised in the moment as lacking
                 confluence, driven by frustration from prior trades
  REVENGE        Entered to recover a loss rather than because the zone
                 justified it

Codes are never generated automatically. AI may suggest; the user confirms.

## Pre-session

Screenshots plus one free-text box for the pre-market plan.
No structured confluence fields, no checkboxes, no grading widgets.

## Session Recap

One free-text box per trading day. By convention the text carries four blocks:
Sessão · Erros · Setups Perdidos · Plano vs Sessão.

Separately, a small yes/no flag recording whether the pre-market bias was
correct — so it becomes countable. Prose cannot be counted.

Also stored per day: P&L, trade count, whether the daily loss limit was hit.

## Export

A compact text export of trades, errors and session recaps for a chosen date
range, for weekend review with AI. This is the primary analysis path — the
in-app reports exist to surface metrics, not to replace it.

## Deprecated — do not implement

The numbered roadmap in previous versions of this file is dead as of
14/08/2026. Specifically abandoned:

- AI Edge Finder returning if-then rules by confluence and time of day
- Pine Script codification and Python backtesting against Deepcharts data
  (Deepcharts does not export tick data; validation happens in MultiCharts)
- Confluence tagging (thirty tags, built for edge mining)
- Notebook and Progress Tracker features
- Star rating separate from grade

If asked for work that depends on any of these, flag the conflict before
starting.
