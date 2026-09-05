# Mystic Ledger

A personal finance app for Ethiopian users, styled as a vintage
"Archivist's Grimoire" (parchment surfaces, gold/green/oxblood palette,
slightly rotated cards, ornate copy). Multi-currency accounts,
income/expense tracking, transfers between accounts, debts, budgets,
savings vaults, tithe ("Sacred Giving"), recurring schedules, and SMS
auto-capture of bank alerts (Telebirr, CBE, Awash).

**Stack:** Flutter (Dart ≥3.3.4) · Provider (state) · Firebase Auth +
Cloud Firestore (offline-first) · `fl_chart` · `google_fonts` · English ⇄
Amharic localization · dark mode · biometric app-lock · encrypted
(AES-256-GCM) backup/restore · CSV import/export.

## Docs
See [`AUDIT.md`](./AUDIT.md) for the full architecture reference (boot
sequence, services, analyzer state) — keep it updated whenever
architecture, models, or services change.

## Status
This README replaces the Flutter starter boilerplate; content pulled from
`AUDIT.md` (last verified 2026-08-08 there).
