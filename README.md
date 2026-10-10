# Mony 💰

> **AI-powered cross-platform personal finance, expense tracking & wealth management**

[![Flutter](https://img.shields.io/badge/Flutter-3.22%2B-blue?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.4%2B-blue?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20macOS%20%7C%20Windows%20%7C%20Web-informational)](https://flutter.dev/multi-platform)

---

## What is Mony?

Mony is a privacy-first, offline-capable personal finance application that runs natively on **Android, iOS, macOS, Windows, Linux, and Web** from a single Flutter codebase.

It goes beyond simple expense tracking — Mony combines daily spending records, intelligent SMS auto-capture, portfolio & net worth tracking, wealth planning, CSV reconciliation, and full **AI/MCP integration** so any AI model can query and manage your finances through a structured tool interface.

---

## Feature Highlights

| Area | Capabilities |
|---|---|
| **Transactions** | Income/expense/transfer, inline calculator, smart autocomplete, batch entry, receipt attachments, pending/uncleared state |
| **Accounts** | Bank, cash, credit card, e-wallet; multi-currency with live FX rates |
| **Budgets** | Per-category, weekly/monthly/custom, rollover, home-screen widget |
| **Goals** | Target + deadline, linked account, milestone celebrations, forecast |
| **Portfolio** | Stocks, MFs, ETFs, crypto, FDs; XIRR/CAGR, benchmark comparison, SIP tracking |
| **Net Worth** | Real-time assets − liabilities, historical graph |
| **Analytics** | Category breakdown, day-of-week heatmap, trend graphs, period comparison, pattern detection, forecasting |
| **SMS Capture** | Auto-parse bank SMS (Android), 50+ bank regex templates, user-defined rules, approval queue |
| **Templates** | Reusable transaction templates, quick-apply, recurring link |
| **CSV Reconciliation** | Import + column mapper + fuzzy-match diff engine + conflict resolution + audit log |
| **Wealth Planning** | FIRE calculator, Monte Carlo simulation, debt payoff planner, scenario analysis |
| **Bill Splitting** | Group expenses, who-owes-whom, settle + export |
| **AI / MCP** | MCP 2 server with tool calling — any AI model can read, write, and analyze your finances |
| **Privacy** | 100% offline-first, biometric lock, no account required, optional backup |

---

## Architecture

```
Flutter (Dart) — single codebase for 6 platforms
│
├── Feature-first Clean Architecture
│   ├── data/        (Drift DAOs, remote sources, DTOs)
│   ├── domain/      (models, use cases, repository interfaces)
│   └── presentation (Riverpod providers, screens, widgets)
│
├── State: Riverpod 2 + AsyncNotifier
├── DB:    Drift (SQLite, type-safe, reactive)
├── Nav:   go_router (deep links, web URL support)
└── AI:    MCP 2 protocol server (JSON-RPC over stdio/HTTP)
```

See [`docs/`](docs/) for full C4, high-level, low-level, and flow diagrams *(local only, not tracked in git)*.

---

## Build Sections

| # | Section | Branch | Status |
|---|---|---|---|
| 1 | Core Transaction Engine | `feat/core-transaction-engine` | 🔜 |
| 2 | Budgets & Goals | `feat/budgets-goals` | 🔜 |
| 3 | Analytics & Reports | `feat/analytics-reports` | 🔜 |
| 4 | SMS Auto-Capture | `feat/sms-capture` | 🔜 |
| 5 | CSV Import & Reconciliation | `feat/csv-reconciliation` | 🔜 |
| 6 | Portfolio & Net Worth | `feat/portfolio-networth` | 🔜 |
| 7 | Wealth Planning | `feat/wealth-planning` | 🔜 |
| 8 | AI / MCP Integration | `feat/ai-mcp` | 🔜 |

---

## Getting Started

```bash
# Prerequisites: Flutter 3.22+, Dart 3.4+
git clone https://github.com/rajanraj2/mony.git
cd mony
flutter pub get
flutter run                         # default device
flutter run -d chrome               # web
flutter run -d macos                # macOS desktop
```

### Code Generation
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Project Structure

```
lib/
├── core/              # theme, router, DI, error handling, utils
├── features/
│   ├── transactions/  # entry, list, search, filter
│   ├── accounts/      # account CRUD + multi-currency
│   ├── budgets/       # budget engine + rollover
│   ├── goals/         # savings goals + milestones
│   ├── portfolio/     # assets, live prices, XIRR/CAGR
│   ├── analytics/     # charts, trends, reports, export
│   ├── import/        # CSV import + reconciliation
│   ├── sms/           # SMS parsing + approval queue
│   ├── recurring/     # scheduled transactions
│   ├── split/         # bill splitting
│   ├── planning/      # FIRE, Monte Carlo, scenarios
│   ├── ai_mcp/        # MCP 2 server + tool definitions
│   └── settings/      # backup, security, preferences
└── shared/            # widgets, extensions, constants
```

---

## AI / MCP Integration

Mony exposes a **Model Context Protocol v2 server** that any compliant AI model can connect to. Available tools:

- `mony.add_transaction` — create an expense/income/transfer
- `mony.list_transactions` — query with filters (date, category, account, amount range)
- `mony.get_summary` — spending summary for a period
- `mony.get_net_worth` — current net worth snapshot
- `mony.analyze_patterns` — detect spending patterns
- `mony.get_budget_status` — budget progress per category
- `mony.add_goal` / `mony.get_goals` — manage savings goals
- `mony.forecast` — project end-of-month balance

---

## License

MIT © 2026 Mony Contributors
