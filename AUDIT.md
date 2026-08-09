# Mystic Ledger — Codebase Audit

Reference map of the app so an AI (or a human) can work on it without reading every file.
**Last verified: 2026-08-08.** If you change architecture, models, or services, update this file.

---

## What it is

A personal finance app for Ethiopian users — multi-currency accounts, income /
expense tracking, transfers between accounts, debts, budgets, savings vaults,
tithe ("Sacred Giving"), recurring schedules, and SMS auto-capture of bank
alerts (Telebirr, CBE, Awash). Vintage "Archivist's Grimoire" visual theme:
parchment surfaces, gold/green/oxblood palette, slightly rotated cards, ornate
copy. English ⇄ Amharic localization, dark mode, biometric app-lock, encrypted
backup/restore, CSV import/export.

**Stack:** Flutter (Dart ≥3.3.4) · Provider (state) · Firebase Auth + Cloud
Firestore (offline persistence on) · `fl_chart` (charts) · `google_fonts`
(Epilogue/Manrope/Space Grotesk) · `intl` · `shared_preferences` ·
`flutter_secure_storage` (hardware-backed lock flag) · `local_auth` ·
`flutter_local_notifications` + `timezone` · `telephony` (Android SMS) ·
`home_widget` (Android) · `cryptography` (AES-256-GCM backup) · `csv` ·
`file_picker` · `share_plus` · `http` (rate fetch) · `connectivity_plus`.

**Analyzer state (verified 2026-08-08):** `flutter analyze` → **0 errors,
0 warnings, 0 info lints — “No issues found”.** All 51 pre-existing info lints
(const-preference, string interpolation, function-declaration, one
`use_build_context_synchronously`) have been cleaned up. Keep it at zero.

---

## Boot sequence (`lib/main.dart`)

`main()`:
1. `Firebase.initializeApp()` — mobile builds inherit their config from the
   native files (`google-services.json` / `GoogleService-Info.plist`); **web**
   passes `DefaultFirebaseOptions.web` from `lib/firebase_options.dart` so it
   can boot at all. Web values are placeholders until a Web app is registered
   in the Firebase console (see Platform/release state).
2. `SmsCaptureService.instance.init()` + `startListening()` — restore enabled
   flag + queued drafts; register Android incoming-SMS listener.
3. `LockService.instance.init()` — enabled flag ⇒ app starts sealed.
4. `SecurityService.instance.init()` — shield + Android FLAG_SECURE.
5. `NotificationService.instance.init()`.
6. `ThemeService.instance.init()` — restores dark mode.
7. `L10n.instance.init()` — restores English/Amharic.
8. `FirebaseFirestore.instance.settings` — offline persistence, unlimited cache.
9. `runApp(MysticLedgerApp())`.

`MysticLedgerApp` (a `StatelessWidget`):
- Takes an injectable **`AuthSource`** (`authStateChanges` stream +
  `currentUser`); the default `FirebaseAuthSource` wraps the real SDK, and
  widget tests swap in a fake so the tree renders without Firebase.
- Nested `ListenableBuilder`s: **`L10n.instance`** (outer — language flip
  rebuilds the whole tree) then **`ThemeService.instance`**.
- `StreamProvider<User?>` from `FirebaseAuth.instance.authStateChanges()`.
- `MaterialApp` with `locale: L10n.instance.locale`, global localization
  delegates, `theme`/`darkTheme`, `themeMode: ThemeService.instance.mode`.
- In `builder:` the root wraps everything in **`_SecurityShell`** (privacy
  shield + interaction tracking). When a user exists, a `LockService`
  listener swaps the tree for **`LockScreen`** while locked, and a
  `ChangeNotifierProvider<FinanceService>` is created (keyed to `user.uid`,
  disposed on sign-out).
- `CloudSyncService.instance.ensure(user?.uid)` is called on every build
  (no-op while bound) to keep the sync indicator on the current user.

`AuthGate` (shown after the splash): reads `OnboardingService.isComplete(uid)`
(per-uid, cached per check) and routes:
- signed out → `AuthScreen`
- signed in, first run → `OnboardingScreen`
- signed in → `MainScaffold`

**Bottom nav (`main_scaffold.dart`, `IndexedStack` so tab state survives):**
`0 Journal · 1 Ledger · 2 Giving · 3 Insights · 4 Finance`.

`MainShell` is an **`InheritedWidget`** exposing `goToTab(index)` and
`openDrawer()`. Every tab builds its *own* `Scaffold`; only the shell's
declares a `drawer:`. **Never use `Scaffold.of(ctx)` to open the drawer from a
tab** — it finds the tab's own Scaffold and silently does nothing. Go through
`MainShell.maybeOf(context)`.

---

## Firestore layout

```
users/{uid}                        UserModel (uid, name, email, createdAt)
users/{uid}/accounts/{id}          Account   (type, isActive soft-delete, currency, targetAmount)
users/{uid}/transactions/{id}      Transaction (ordered by date desc)
users/{uid}/transfers/{id}         Transfer    (ordered by date desc)
users/{uid}/debts/{id}             Debt        (ordered by date desc)
users/{uid}/budgets/{id}           Budget
users/{uid}/recurring/{id}         RecurringTransaction
users/{uid}/settings/prefs         AppSettings (single doc)
```

`FinanceService` opens **7 snapshot listeners** (accounts, transactions,
transfers, debts, budgets, recurring, settings). `_streamCount = 7` gates
`isLoading` — **bump it if you add a stream.** An 8-second `_loadingWatchdog`
releases the gate even if a stream never delivers (fresh offline install).

`UserService.createUserProfile` seeds **only** the user doc + settings doc.
**No accounts are created** — the ledger starts genuinely empty and the user
adds their own vaults. Screens that need an account show `NoAccountsCard`
(`lib/widgets/empty_state_card.dart`) rather than a dead form.

There are **no well-known account ids**. Savings is identified by
`AccountType.savings` (zero, one, or several vaults, each in its own currency)
— see `savingsAccounts` / `savingsSummary`. Every account (vaults included)
can be soft-deleted (`isActive: false`); history is preserved and it can be
restored from the Finance Hub.

**Firestore rules (`firestore.rules`)**: ownership-scoped (uid) **plus schema
validation** (type-and-range per collection: `validAccount`,
`validTransaction`, `validTransfer` — which forbids self-transfers —,
`validDebt`, `validBudget`, `validSettings`). Deliberately *not* an exact
field whitelist so optional model fields don't require a rules deploy.
`isRate` requires strictly positive rates. Deploy with
`firebase deploy --only firestore:rules`.

---

## Models (`lib/models/`)

| File | Contents |
|---|---|
| `account_model.dart` | `Account` · `AccountType {bank, mobile, cash, savings}` · `isActive` (soft-delete) · `currency` · `targetAmount` (savings goal) · `copyWith` |
| `transaction.dart` | `Transaction` · `TransactionType {income, expense}` · `TransactionCategory` (16 values, with `label`/`mystiqueLabel`/`icon` via `TransactionCategoryDisplay`) · `currency`, `rateToBase`, `fee`, **`tags`** (List<String>), **`splits`** (List<TransactionSplit>) · `amountInBase`, `feeInBase`, `isSplit` · top-level `resolveRateToBase()` (see money rules) · `TransactionSplit {category, amount, note}` |
| `transfer_model.dart` | `Transfer` · `TransferCategory` (7 values, with `label`/`icon`) · `toAmount`, `toCurrency`, `rate`, `rateToBase`, `reversalOfId` · `isCrossCurrency`, `isReversal` · `copyWith` (note/category only) |
| `debt_model.dart` | `Debt` · `DebtType {owe, owed}` · `dueDate` (nullable) · `daysUntilDue`, `isOverdue` · `isPaid`. **No currency — implicitly base.** |
| `budget_model.dart` | `Budget` · `BudgetPeriod {weekly, monthly, yearly}` · nullable `category` (null = overall). **Base currency.** |
| `recurring_transaction.dart` | `RecurringTransaction` · `RecurrenceFrequency {daily, weekly, monthly, yearly}` (with `label`) · `currency`, `nextDue`, `isActive` · `nextOccurrence(from)` (month-end clamped) · `copyWith` |
| `user_model.dart` | `UserModel` (uid, name, email, createdAt) · `copyWith` |
| `currency_model.dart` | `Currency` + 8-entry `registry` (ETB, USD, EUR, GBP, AED, SAR, KES, DJF — ETB default) · `byCode()` (never crashes on unknown codes) · `ExchangeRate` |
| `app_settings.dart` | `AppSettings` (baseCurrency, titheRate=0.10, rates map) · `rateFor()` (unknown → 1.0) · `copyWith` |

### Backward compatibility — do not break

Every field added post-multi-currency **defaults in `fromMap`**:
`currency → 'ETB'`, `rateToBase → 1.0`, `fee → 0.0`, `toAmount → amount`,
`rate → 1.0`, `tags → const []`, `splits → const []`,
`category`/`reversalOfId`/`dueDate`/`targetAmount` → null, `isPaid → false`,
`isActive → true`. Documents written before the rework parse unchanged.
`test/models_migration_test.dart` pins this contract — **if you add a field,
add a default and a test.**

---

## Services (`lib/services/`)

### `finance_service.dart` (~1200 lines) — the API surface

`ChangeNotifier`, one per signed-in user. Pure arithmetic is extracted as
top-level functions so it's testable without Firebase.

**Reads:** `accounts` (active) · `allAccounts` · `spendableAccounts` (active,
non-savings) · `findAccount` · `transactions` / `recentTransactions` ·
`filteredBy(type)` · `findTransaction` · `transfers` · `transfersForAccount` ·
`debts` / `iOwe` / `owedToMe` (outstanding, **soonest-due first** via
`_sortByDue`; undated debts trail) · `budgets` · `recurring` /
`activeRecurring` · `allLedgerEntries` / `recentLedgerEntries` (unified
transaction+transfer rows, newest first).

**Savings** (type-driven, never by id): `savingsAccounts` · `hasSavingsAccount`
· `isSavingsAccount(id)` · `savingsTransfers` (one pass, vault↔vault listed
once) · `savingsHidden` · `savingsSummary` → `SavingsSummary {accounts, amount,
currency, converted}`. `converted` is true when the vaults span currencies and
the total had to be converted at *current* rates; the UI renders that with `≈`
and says so.

**Currency:** `baseCurrency` · `currencyOf(accountId)` · `toBase(amount, code)`
(live rates only — historical figures must use `amountInBase`) ·
`conversionRate(from, to)` · `balanceByCurrency`.

**Aggregates** (all base currency unless noted): `totalBalance` (active,
non-savings, converted live) · `accountBalance(id)` *(native currency)* ·
`totalIncome`/`totalExpenses`/`totalFees` · `incomeInRange`/`expensesInRange`/
`feesInRange` (nullable `from`/`to`, `to` exclusive) · `incomeIn(period)`/
`expensesIn`/`feesIn` · `weeklyIncome`/`monthlyIncome` ·
`expensesByCategory` / `expensesByCategoryInRange` (split-aware) ·
`balanceSeries` (running net income−expenses−fees) · `accountDistribution`
(includes savings; `totalBalance` excludes them — pre-existing inconsistency)
· `lastNMonths(n)` · `trendFor(period)` / `trendBetween(from, to)` ·
`spentInPeriod(budget)` / `spentInRange` / `budgetHistory(budget, periods: 6)`.

**Tithe:** `titheObligation` / `titheGiven` / `titheRemaining` /
`titheProgress` / `titheStatus`, all taking a `LedgerPeriod`.

**Writes:** `addTransaction` / `deleteTransaction` (upsert keyed by id) ·
`addTransfer` / `reverseTransfer` (no deleteTransfer — see money rules) ·
`isReversed` / `findTransfer` / `canReverse` · `addAccount` /
`deactivateAccount` / `reactivateAccount` / `renameAccount` /
`setAccountTarget` / `changeAccountCurrency` (blocked if
`accountHasActivity`) · `addDebt` / `toggleDebtPaid` / `deleteDebt` ·
`setBudget` / `deleteBudget` · `addRecurring` / `deleteRecurring` /
`toggleRecurring` · `saveSettings` / `setTitheRate` / `setBaseCurrency` /
`setRate` · `restoreAll` (wipe-then-write, batched) · `importAll` (merge,
batched) · `deleteAllUserData` (wipes every collection + settings + user doc,
chunked ≤400/batch) · `proposeDueRecurring` (queues due schedules as drafts,
advances `nextDue`) · `rearmNotifications` (idempotent local alerts from
budgets/debts/tithe/recurring).

**Privacy (device-local, `SharedPreferences` — deliberately NOT synced):**
`totalHidden` · `isAccountHidden(id)` · `toggleTotalVisibility` ·
`toggleAccountVisibility` · `hideAll` / `showAll` / `allHidden`.
Keys: `balance_hidden`, `hidden_accounts`.

**Pure functions (top-level, testable):**
`computeAccountBalance` · `computeTitheGiven` · `TitheStatus.of` ·
`computeSavingsSummary` · `computeSpentAgainstBudget` ·
`computeTrendFor` / `computeTrendBetween` · `categoryAllocations(t)`.

**Shared types:** `LedgerPeriod {week, month, sixMonths, year, all}` with
`.label` / `.startFrom(now)` (week = Mon–Sun) · `LedgerEntry` /
`LedgerEntryKind {income, expense, transfer}` · `MonthlySnapshot` ·
`TrendBucket` · `BalancePoint` · `AccountShare` · `BudgetHistoryPeriod` ·
`SavingsSummary`.

### Other services

| Service | Role |
|---|---|
| `auth_service.dart` | Thin `FirebaseAuth` wrapper: signUp/signIn/signOut/resetPassword/deleteAccount/signInWithGoogle (returns null on cancel) + `friendlyError()` mapping codes to user copy. |
| `user_service.dart` | `createUserProfile` (user doc + settings doc in one batch), `getUser`, `userStream`, `updateName`. |
| `l10n.dart` | `L10n` singleton (`ChangeNotifier`): English ⇄ Amharic. `L10n.t(en)` static lookup (falls back to English), `L10n.date(d, pattern)` / `dateTime` locale-aware. Keys live in `lib/l10n/am_strings.dart` (~600+ entries keyed by exact English string). `supportedLocales = [en, am]`, pref key `app_locale`. |
| `theme_service.dart` | Dark-mode preference (`theme_dark`). Calls `MysticColors.useDark()/useLight()` which swap the static palette; `MaterialApp` reads `mode`. |
| `lock_service.dart` | Biometric/PIN app lock. Flag lives in **`flutter_secure_storage`** (hardware-backed), migrated from SharedPreferences on first read. `canUse` checks *enrollment* (not just capability). `authenticate()` uses `stickyAuth: false` so a cancelled attempt can't suppress later prompts. `requireAuth()` re-verifies before sensitive actions (delete/export/import/restore). |
| `security_service.dart` | Privacy hardening: (1) `covered` shield state driven by app lifecycle; (2) Android FLAG_SECURE via MethodChannel `mystic_ledger/security` `setSecure` (native `MainActivity.kt`); (3) inactivity auto-lock timer (`auto_lock_minutes`, default 1) fed by the root shell's `onPointerDown`. |
| `sms_parser.dart` | Parses Telebirr/CBE/Awash alert texts (regexes tuned on real forwarded messages). `detectBank` (sender strongest, then body fingerprints), `parseSms` (never throws, never null — low confidence fallback), `smsSignature` (stable FNV-1a dedup key), `SmsConfidence {high, medium, low}`, `CapturedDirection`, `CapturedBank`. Fees: Telebirr = service fee + VAT; CBE = `total of` − amount; Awash = charge + VAT + EDRRF. |
| `sms_capture_store.dart` | On-device persistence (`SharedPreferences`): draft queue, processed-signature dedup set (capped 5000), enabled flag. All **static** so the `telephony` background isolate and the foreground service share one path. `captureIncoming()` = gate → detectBank → dedup → parse → skip noise (no amount AND no direction) → queue → mark processed. `addRecurringDraft` builds a draft whose id encodes the occurrence date (idempotent). |
| `sms_capture_service.dart` | Orchestrates capture; exposes `pendingDrafts`/`pendingCount`/`isEnabled`/`supported` (Android only). `backfillInbox()` scans the inbox per bank-fingerprint query (one failing query never aborts the scan), returns -1 on no access. `smsBackgroundHandler` (top-level, required by the plugin) funnels into the store. App-scoped singleton (drafts belong to no account until approved). |
| `backup_service.dart` | `.mlbackup` encrypted archive. Payload = plain JSON of all collections + settings; **AES-256-GCM** under a PBKDF2-HMAC-SHA256 key (150 000 iterations, random salt), envelope carries salt/nonce/MAC. `shareBackup`, `decryptFileBytes`, `parsePayload` (throws on unsupported version). Only known date keys are ISO-string-converted (a note that looks like a date is untouched). |
| `cloud_sync_service.dart` | `CloudSyncState {synced, saving, offline}` + `online` ValueNotifier. Watches `connectivity_plus` + Firestore `includeMetadataChanges` snapshots (`hasPendingWrites`, `isFromCache` per collection) for the app-bar pill. Pure `computeSyncState(online, anyPending)` is unit-tested. 3-second grace before `fromCache` is trusted as offline (avoids flashing the banner on a normal launch). |
| `data_exporter.dart` | CSV export: one file with `TRANSACTIONS` (incl. JSON-encoded `tags`/`splits` columns) / `TRANSFERS` / `DEBTS` / `BUDGETS` / `RECURRING` sections, explicit `\n` eol, shares via `share_plus` (browser download on web). |
| `csv_importer.dart` | Parses the exporter's CSV (and tolerates bare transaction tables). **Fresh ids on import = merge, never overwrite.** Account columns matched by name; unknown accounts → `skipped` list. Missing/corrupt tags/splits degrade to empty rather than skipping the row. |
| `rate_fetcher.dart` | Live rates from `https://open.er-api.com/v6/latest/{base}` (no key, CORS-enabled). Returns `ratesToBase` (inverted) or null. Used by the Currency & rates screen's refresh button. |
| `notification_service.dart` | Local alerts (nothing leaves the device): budget at 80%/100% of limit at period end, debt day-before + day-of, tithe month-end, recurring due-day prompt. Idempotent stable ids; `zonedSchedule` with Africa/Addis_Ababa tz; inexact alarms fallback. Each alert carries a routing payload (`budget:<id>` / `debt:<id>` / `tithe:<y>-<m>` / `recurring:<id>`) exposed via `onTap`; `MainScaffold` navigates on tap. Cold-start launch-from-notification (`getNotificationAppLaunchDetails`) is not yet handled. |
| `home_widget_service.dart` | Bridge to the Android home-screen widget (`BalanceWidgetProvider`): pushes `balance`/`label` strings and triggers redraw; exposes `onWidgetClicked` and `initiallyLaunchedFromWidget` for the `mysticledger://addEntry` deep link. No-ops off Android. |
| `onboarding_service.dart` | Per-uid first-run flag in SharedPreferences (`onboarding_done_$uid`). `ChangeNotifier` so `AuthGate` rebuilds when the wizard completes. |

---

## Screens (`lib/screens/`)

| Screen | Notes |
|---|---|
| `splash_screen.dart` | Animated journal-cover intro → `AuthGate`. |
| `auth_screen.dart` | Sign in / sign up toggle, name field on sign-up, password reset dialog, Google sign-in, friendly error box. |
| `onboarding_screen.dart` | 3-step wizard (base currency → first account → SMS capture; non-Android last step becomes a "you're ready" note). Choices applied only at the end. |
| `main_scaffold.dart` | 5-tab `IndexedStack` + custom bottom nav + offline strip (reads `CloudSyncService`) + home-widget sync (debounced) + lifecycle lock + notification-tap routing. **Cold-start arm:** `proposeDueRecurring()` + `rearmNotifications()` also run once the ledger first finishes loading (previously only on resume, so a fresh launch never armed them). |
| `journal_screen.dart` | **Tab 0.** `_CaptureBanner` (SMS review queue, only when pending) + balance hero (eye = hide/show all, long-press-free; per-account eye on each card) + account cards (pairs, last full-width) + 5 recent entries. Defines shared `entrySlideUpRoute` (slide-up page transition). FAB → `NewEntryScreen`. |
| `ledger_screen.dart` | **Tab 1.** Unified list (transactions + transfers). Type filter chips, category filter (expense only), #tag filter, free-text search (title/note/tags), 20-at-a-time paging. Transactions: tap to edit (from the real `Transaction` — `LedgerEntry` is lossy), swipe to delete. Transfers: tap → `TransferHistoryScreen` (reversal is the only mutation). |
| `giving_screen.dart` | **Tab 2.** Tithe: period toggle (All/Month/Week(Mon–Sun)/Custom), income card, obligation/given/remaining + progress ring (`_ProgressRingPainter`), editable rate (0–100% enforced), Record Giving writes a real `Tithe` expense, giving history, Archivist's Note. |
| `insights_screen.dart` | **Tab 3.** Period selector (presets + custom range) drives every card: income/expense/net/fees summary grid, income-vs-expense bar chart (`trendFor`/`trendBetween`), running-balance line, category donut (tap slice → drilldown sheet), fees card, account distribution. `ChartPalette` is **CVD-validated** — see Chart colour below. |
| `finance_hub_screen.dart` | **Tab 4.** Action tiles (Transfer/Savings/Debts/Add Account/Budgets/Transfer Record) + savings snapshot card (`≈` when converted) + all-accounts list (edit sheet, restore hidden) + debt overview. |
| `new_entry_screen.dart` | Add/edit entry (upsert). Doubles as the SMS-draft confirm form (`draft:` param). Amount (account currency), fee (expenses only), title, type cards, category picker (expense vs income lists), account picker, note, **tags** (`TagsField`), **splits** (`SplitToggle` + `SplitEditor`, must sum to total ±0.005). Edit preserves `date` + `rateToBase` via `resolveRateToBase`. Warns when an edited entry moves to another currency (number is reinterpreted, not converted). |
| `transfer_screen.dart` | Transfer between two accounts (savings included). Cross-currency shows a rate row with live "what arrives" preview; swap ⇅ clears the rate; insufficient-balance guard; `_saving` guards double-tap. |
| `transfer_history_screen.dart` | Full transfer record + fee summary. REVERSED / REVERSAL badges, strikethrough on reversed originals. Reverse dialog with optional fee-refund checkbox (`CheckboxActivated`). |
| `savings_screen.dart` | Vault hero (goal progress bar, `≈` conversion note, hiding), per-vault breakdown (multi-vault only), deposit history (deposits +/withdrawals −), deposit bottom sheet (from spending account → vault; cross-currency uses the maintained rate). |
| `debt_screen.dart` | Tabbed I Owe / Owed To Me, summary banner, due-date labels (overdue in red), add/edit sheet with due date, mark-paid toggle. |
| `budget_screen.dart` | Budget cards with period progress bars, add/edit sheet, **budget history sheet** (last 6 periods per budget via `budgetHistory`). |
| `recurring_screen.dart` | Manage recurring schedules (add/edit, pause/resume, delete, next-due display). Due schedules surface as drafts in the capture queue on resume. |
| `add_account_screen.dart` | New account; `initialType` presets the selector (savings screens land on Savings); Ethiopian bank quick-picks. |
| `currency_settings_screen.dart` | Base currency picker + per-currency rate table, plus a refresh button that calls `RateFetcher` (writes live rates into settings — user can always override). |
| `account_detail_screen.dart` | Single account: hero (native balance, hide eye), edit sheet entry (rename/currency — locked once activity exists —, savings goal), transaction list (delete via swipe/dialog), transfer history for the account. |
| `captured_screen.dart` | SMS review queue: sort (newest/oldest/amount), search, bank + direction filter chips, confidence badges, raw-message expansion, RECORD (pre-fills `NewEntryScreen`) / IGNORE. |
| `profile_screen.dart` | Avatar + edit name, stats row, SMS capture card (permission, backfill, review), data tools (recurring, CSV export, CSV import), encrypted backup card (create/restore `.mlbackup`), appearance (dark mode), language (EN/አማ), security (app lock + auto-lock minutes), notifications toggle, info, sign out, delete account (re-verified + confirmed). |
| `lock_screen.dart` | Sealed gate: full-screen replacement (nothing visible behind it), UNLOCK via biometric/PIN, "turn off the lock" escape when nothing is enrolled. |
| `account_detail_screen.dart` | See above. |

---

## Widgets & theme

- `app_theme.dart` — `MysticColors` (mutable static palette, `useLight()`/
  `useDark()` swap) + `buildMysticTheme()` / `buildMysticDarkTheme()` (Material
  3, `background`/`onBackground` uses carry `// ignore: deprecated_member_use`)
  + style helpers `headlineStyle()` (Epilogue), `bodyStyle()` (Manrope),
  `labelStyle()` (Space Grotesk) + `readableOn(color)`.
- **Repaint contract (important):** because the palette and `L10n.t` strings
  are mutable statics read inside `build()`, a const-identical widget is
  skipped by the framework on a theme/locale flip. **Every screen/shared
  widget that reads these statics must call `Theme.of(context)` and
  `Localizations.localeOf(context)` in its build** (or be constructed
  non-const). Guarded by `test/theme_locale_repaint_test.dart`.
- `app_feedback.dart` — `showFeedback`, `friendlyWriteError` (maps
  `FirebaseException` codes to user copy), `reportIfWriteFails`. **All
  Firestore writes report through here** — see the write pattern below.
- `empty_state_card.dart` — `EmptyStateCard` (shared empty surface, optional
  CTA) + `NoAccountsCard` (first-run case; `presetType` lands the user on the
  right account-type tab).
- `account_edit_sheet.dart` — `showAccountEditSheet` + `AccountEditSheet`
  (rename, currency [locked with activity], savings goal, soft-delete).
- `app_drawer.dart` — profile header (initials, balance), financial tools
  (Transfer/Savings/Debt/Add Account/Budget/Recurring), settings (Profile,
  Currency & rates), sign out, version footer.
- `mystic_app_bar.dart` — shared tab AppBar: hamburger (via `MainShell`),
  cloud sync pill (`CloudSyncState`), avatar → Profile.
- `transaction_tile.dart` — one transaction row (Journal + Ledger).
- `entry_tags_splits.dart` — `TagsField` (#tag chips + input), `SplitToggle`,
  `SplitEditor`/`SplitDraft`/`_SplitRow` (live sum vs total feedback).

---

## The money model — read this before touching balances

Four rules that most bugs in this app would come from violating:

1. **Balances live in each account's own currency.** `Account.currency`.
   `computeAccountBalance()` never converts anything. Only *totals and reports*
   convert to `AppSettings.baseCurrency`.

2. **Every record snapshots `rateToBase` at write time.** Reports multiply by
   the stored snapshot, never the live rate table — correcting a rate today
   does not silently rewrite last month's figures. `resolveRateToBase()`
   re-snapshots **only** when the currency itself changed. Do **not**
   "simplify" this into a live lookup.

3. **Cross-currency transfers store both sides.** `amount`/`currency` leaves
   the source; `toAmount`/`toCurrency` arrives at the destination; `rate` is
   what the user actually got. Same-currency transfers mirror
   (`toAmount == amount`, `rate == 1.0`).

4. **Reversal never deletes.** `reverseTransfer()` writes a *new* opposing
   transfer carrying `reversalOfId`. The fee is not refunded by default (the
   bank kept it); `refundFee: true` returns it. Guards reject reversing a
   reversal or reversing the same transfer twice. There is deliberately **no
   `deleteTransfer`** — a deleted transfer would orphan any reversal pointing
   at it.

**Sign conventions in `computeAccountBalance`:**

| Event | Effect on the account |
|---|---|
| income | `+ amount` |
| expense | `− (amount + fee)` |
| transfer in | `+ toAmount` |
| transfer out | `− (amount + fee)` |

**Splits & tags:** a transaction without splits reports under `category` for
its full `amountInBase`; a split transaction is allocated across its line
items (`categoryAllocations`, `_allocatedIn` — both used by category reports,
tithe, and budgets). Fees ride with their entry. Tags are lowercase, trimmed,
de-duplicated; they are searchable and filterable in the Ledger.

Exchange rates are **user-entered** by default (manual table); an optional
refresh button fetches live rates via `RateFetcher`. An unset rate falls back
to `1.0`, which the settings screen flags as almost certainly wrong.

---

## Writing to Firestore — the rule that isn't obvious

**Never `await` a Firestore write to drive navigation or a spinner.**

Offline persistence is on (`main.dart`). A write applies to the local cache
*immediately* — the snapshot listener fires and the UI updates — but its
`Future` does **not** resolve until the server acknowledges it. Awaiting one
therefore hangs the screen for the entire time the device is offline.

The pattern everywhere is:

```dart
final messenger = ScaffoldMessenger.maybeOf(context); // capture BEFORE the pop
reportIfWriteFails(messenger, svc.addTransaction(tx));
Navigator.of(context).pop();
```

The messenger is captured first because the screen's own context is gone by
the time a server rejection arrives. Save buttons additionally carry a
`_saving` bool + `busy:` flag — without it a double-tap wrote the entry twice.
(Exceptions: restore/import/delete-account *do* await — they must complete
before the UI moves on, and offline they simply wait.)

`use_build_context_synchronously`: capture `Navigator`/`ScaffoldMessenger`
before an `await` and guard with `if (!mounted) return;`. `context.mounted`
on a State's implicit `context` is not accepted by the analyzer — use the
captured objects.

### Chart colour — has rules

`ChartPalette` in `insights_screen.dart` is **CVD-validated** against the
parchment surface: every adjacent pair clears ΔE 8 under
protan/deutan/tritan, all clear 3:1 contrast, none reads grey.

- **Do not reorder or substitute without re-validating.**
- **Colour binds to the entity, never to sorted rank** — category by enum
  index (`ChartPalette.forCategory`), never by position in a sorted list.
  Rank-based colouring repaints series whenever the period filter changes
  ranking.

---

## Tests (`test/`)

Verified **2026-08-08**: `flutter test` → **all 100+ tests pass** (including
the `widget_test` smoke test, which now renders the tree against a fake
`AuthSource` instead of a live Firebase connection).

| File | Pins |
|---|---|
| `models_migration_test.dart` | Legacy (pre-multi-currency) docs parse; multi-currency round-trips; settings defaults. |
| `balance_math_test.dart` | Every balance sign rule + reversal invariants (incl. fee refund, cross-currency). |
| `tithe_test.dart` | Obligation/given/remaining/progress edges; split-aware tithe; foreign-currency snapshot. |
| `rate_snapshot_test.dart` | `resolveRateToBase`: edit keeps snapshot; currency change re-snapshots. |
| `budget_trend_test.dart` | `computeSpentAgainstBudget` + `computeTrendFor`/`computeTrendBetween` bucketing. |
| `savings_summary_test.dart` | `computeSavingsSummary`: single-currency exact, mixed-currency `converted` flag. |
| `backup_service_test.dart` | Encrypt→decrypt round-trip, wrong password, fresh salt/nonce, ISO-date mapping, date-like notes untouched. |
| `csv_importer_test.dart` | Transaction/transfer parsing, account resolution, skip unknown accounts, fresh ids, bare tables. |
| `cloud_sync_state_test.dart` | `computeSyncState` truth table. |
| `sms_parser_test.dart` | Real Telebirr/CBE/Awash samples (amount, counterparty, fee, reference), synthetic tolerance, signature stability. |
| `sms_capture_store_test.dart` | Gate/dedup/noise-skip/persistence/prune behaviour of `captureIncoming`. |
| `theme_locale_repaint_test.dart` | Dark mode / Amharic flips actually repaint const-identical widgets (guards the `Theme.of`/`Localizations` contract). |
| `widget_test.dart` | Smoke test — pumps `MysticLedgerApp` with a fake `AuthSource` (no Firebase needed) and asserts the app + `SplashScreen` render. |

`FinanceService` itself is not unit-tested (needs Firebase) — that's why the
money-critical arithmetic is extracted into the pure functions listed above.

---

## Platform / release state

| Item | State |
|---|---|
| Android | Configured: `MainActivity.kt` (FLAG_SECURE channel), `BalanceWidgetProvider.kt` + `balance_widget.xml`, SMS receiver/service (`telephony`), notifications receivers (incl. boot), biometric permission, manifest permissions all declared. |
| iOS / macOS / Windows / Linux | Present but not the focus; lock + notifications supported on iOS; most device features are Android-only no-ops elsewhere. |
| Web | Boots: `Firebase.initializeApp(options: DefaultFirebaseOptions.web)` in `lib/firebase_options.dart` (Android values in the same file match `google-services.json`). **Web API key + App ID are placeholders** — no Web app is registered in the Firebase console, so sign-in stays broken until the real config is pasted. `flutter build web` verified ✓. Google Sign-In placeholder client ID in `web/index.html`. |
| Signing | Credentials read from `android/key.properties` (gitignored). Copy `key.properties.example` and generate a keystore — **no key is checked in**. |
| `applicationId` | `com.mattathiasa.mysticledger` (renamed from `com.example.*` 2026-08-09 — Play rejects `com.example.*`). Bundle ids on iOS/macOS/linux updated to match. **Re-register the Android app in the Firebase console under this package name + the debug SHA-1 `09:41:C9:67:8A:45:F0:B3:0D:31:0C:95:B1:1E:FF:51:E2:69:D6:E3`, then re-download `google-services.json`** (the local file's `package_name` was edited to keep builds green until then). |
| `targetSdk` | 36 (`compileSdk 36`) — matches Play's Aug 2026 requirement. Bumped from Flutter 3.19's default of 33/34 on 2026-08-09; release build verified against it. |
| R8 | `minifyEnabled`/`shrinkResources` on, with `proguard-rules.pro`. Release APK built + verified 2026-08-09 (60.3 MB). |
| Firebase rules | Owner-scoped + schema validation (see above). Deploy: `firebase deploy --only firestore:rules`. Emulators configured in `firebase.json`. |
| `landing_page/` | Separate Vercel-deployed marketing site in the same repo (`vercel.json` builds `landing_page/`), APK download from GitHub Releases. |
| `stitch_mystic_ledger_ui_design/` | Static HTML design mockups (monthly observations, cipher journal, splash, dashboard, new entry, giving, all entries) — the visual source of truth for the theme. |

---

## Gotchas (read before changing things)

- **`cloud_firestore` exports a lowercase `class sum`.** Hence
  `import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;`
  and why `sum` can't be a parameter name (`avoid_types_as_parameter_names`) —
  `finance_service.dart` uses `acc` in `fold` callbacks instead.
- **`_streamCount = 7`** gates `isLoading`. Adding a listener without bumping
  it leaves the app on the spinner forever (there is an 8s watchdog as a
  safety net).
- **Changing an account's currency is blocked once it has entries**
  (`accountHasActivity`) — stored amounts are in that currency and would be
  silently reinterpreted. Editing an entry to an account in another currency
  is allowed but the number is *not* converted (the UI warns).
- **Account removal is a soft delete** (`isActive: false`). History is
  preserved; restore from Finance Hub. Offered on every account, vaults
  included.
- **Editing an entry must preserve `date` and `rateToBase`.** Upserts keyed by
  id: an edit is "prefill, keep the id, re-save". Stamping `DateTime.now()`
  moves the entry into the current period (changing tithe owed and budget
  spend for two months at once); re-reading the live rate restates history.
  `Debt` edits must pass the existing `isPaid` (defaults false) or a settled
  debt silently un-settles. `Transfer.copyWith` only allows note/category.
- **Debts and Budgets have no currency field** — treated as base currency.
- **SMS drafts are on-device only and belong to no account** until approved.
  Nothing is recorded automatically; `captureIncoming` skips messages with
  neither amount nor direction (OTPs/promos).
- **The background SMS handler must stay a top-level function** in
  `sms_capture_service.dart` (the plugin needs a stable `CallbackHandle`).
- **Recurring proposals are idempotent** — the draft id encodes the occurrence
  date, and `nextDue` advances after proposing, so re-checks never duplicate.
- **`LockService.canUse` checks enrollment**, not just hardware capability,
  so a sensor without enrolled fingerprints doesn't seal the user in.
- **Privacy shield vs lock:** the shield covers the app-switcher snapshot on
  iOS (`inactive`/`hidden`/`paused`) and Android (`paused`/`hidden`); the
  lock seals on resume. Android `inactive` is deliberately ignored for both
  (benign overlays like the notification shade shouldn't flash anything).
- **`GoogleFonts` are fetched at runtime** (pubspec has no bundled font
  assets); the privacy shield/lock screens hard-code `fontFamily: 'Epilogue'`
  which resolves via `google_fonts`.
- **`app_theme.dart` suppresses `deprecated_member_use`** for
  `background`/`onBackground` — will break on a future Flutter upgrade.
- **Savings is excluded from `totalBalance`, `balanceByCurrency`, and
  `accountDistribution` alike** (fixed 2026-08-09) — Insights totals always
  agree with the Journal hero. Savings lives strictly in `savingsSummary`.
- **`flutter analyze` is clean (0/0/0)**. Do not introduce new warnings/errors.
- **Landing page & widget deep link** used the old `com.example.mystic_ledger`
  package name; renamed to `com.mattathiasa.mysticledger` across
  `HomeWidgetService._qualifiedName`, the Kotlin package of
  `BalanceWidgetProvider`, `build.gradle`, `google-services.json`, and the
  iOS/macOS/linux/windows bundle ids.

---

## Known open items

- **Nothing has been run on a physical device or emulator** (per prior audit;
  landing page is deployed on Vercel). Layout/overflow at real sizes
  unverified.
- Play blockers remaining: **no release keystore** (`key.properties` absent — release falls back to debug signing), Google Sign-In on Android (no OAuth client in `google-services.json`), web Google Sign-In + **web Firebase app** (apiKey/App ID placeholders in `firebase_options.dart` until a Web app is registered), and the **iOS `GoogleService-Info.plist` is missing** (iOS crashes at `Firebase.initializeApp()` until it is added).
- Debts and Budgets still have no `currency` field.
- No Crashlytics, no CI, no privacy policy.
- Exchange rates are manual by default (live fetch is a user-initiated
  refresh, not automatic).
- The web deployment (`landing_page/` on Vercel) does not yet host the Flutter
  web app; `firebase_options.dart` is ready for when it does.
