# Mystic Ledger — Codebase Audit

Reference map of the app so you don't have to read every file to work on it.
**Last verified: 2026-07-26.** If you change architecture, update this file.

---

## What it is

A personal finance app for Ethiopian users — multi-currency accounts, income /
expense tracking, transfers between accounts, debts, budgets, savings, and tithe
("Sacred Giving"). Vintage "Archivist's Grimoire" visual theme: parchment
surfaces, gold/green/oxblood palette, slightly rotated cards, ornate copy.

**Stack:** Flutter 3.19.6 · Provider (state) · Firebase Auth + Cloud Firestore ·
`fl_chart` (charts) · `google_fonts` · `intl` · `shared_preferences`.
Lints: stock `package:flutter_lints/flutter.yaml`. **The analyzer is at zero —
keep it there.**

---

## Boot sequence

`main.dart` → `Firebase.initializeApp()` → enables **offline persistence**
(unlimited cache) → `MysticLedgerApp`.

- `StreamProvider<User?>` wraps the app from `authStateChanges()`.
- `FinanceService` is created in `MaterialApp.builder` **only once a user
  exists**, keyed to `user.uid`. Signing out disposes it.
- `home:` is `SplashScreen`, which routes to `AuthGate` → `AuthScreen` (signed
  out) or `MainScaffold` (signed in).

**Bottom nav (`main_scaffold.dart`, `IndexedStack`):**
`0 Journal · 1 Ledger · 2 Giving · 3 Insights · 4 Finance`

---

## Firestore layout

```
users/{uid}                        UserModel (uid, name, email, createdAt)
users/{uid}/accounts/{id}          Account
users/{uid}/transactions/{id}      Transaction   (ordered by date desc)
users/{uid}/transfers/{id}         Transfer      (ordered by date desc)
users/{uid}/debts/{id}             Debt          (ordered by date desc)
users/{uid}/budgets/{id}           Budget
users/{uid}/settings/prefs         AppSettings   (single doc)
```

`FinanceService` opens **6 snapshot listeners** (one per path above).
`_streamCount = 6` gates `isLoading` — **bump it if you add a stream.**

`UserService.createUserProfile` seeds **only** the user doc and the settings
doc. No accounts are created — the ledger starts genuinely empty and the user
adds their own vaults, because a list of accounts they may not hold reads as
demo data and has to be cleaned up before the app is usable. Screens that need
an account show `NoAccountsCard` (`lib/widgets/empty_state_card.dart`) rather
than a form whose Save is inert.

There are **no well-known account ids**. Savings is identified by
`AccountType.savings`, so there can be zero, one, or several vaults, each in
its own currency — see `savingsAccounts` / `savingsSummary`. Nothing is
structural: every account, vaults included, can be soft-deleted.

---

## The money model — read this before touching balances

Four rules that most bugs in this app would come from violating:

1. **Balances live in each account's own currency.** `Account.currency`.
   `computeAccountBalance()` never converts anything. Only *totals and reports*
   convert to `AppSettings.baseCurrency`.

2. **Every record snapshots `rateToBase` at write time.** Reports multiply by the
   stored snapshot, never the live rate table — so correcting a rate today does
   not silently rewrite last month's figures. Do **not** "simplify" this into a
   live lookup.

3. **Cross-currency transfers store both sides.** `amount`/`currency` leaves the
   source; `toAmount`/`toCurrency` arrives at the destination; `rate` is what the
   user actually got at that moment. Same-currency transfers mirror
   (`toAmount == amount`, `rate == 1.0`).

4. **Reversal never deletes.** `reverseTransfer()` writes a *new* opposing
   transfer carrying `reversalOfId`. The fee is not refunded by default (the bank
   kept it); `refundFee: true` returns it. Guards reject reversing a reversal or
   reversing the same transfer twice.

**Sign conventions in `computeAccountBalance`:**

| Event | Effect on the account |
|---|---|
| income | `+ amount` |
| expense | `− (amount + fee)` |
| transfer in | `+ toAmount` |
| transfer out | `− (amount + fee)` |

Exchange rates are **user-entered, never fetched** — deliberate. Maintained in
Currency & rates (drawer). An unset rate falls back to `1.0`, which the settings
screen flags as almost certainly wrong rather than hiding.

---

## Models (`lib/models/`)

| File | Contents |
|---|---|
| `account_model.dart` | `Account` · `AccountType {bank, mobile, cash, savings}` · `isActive` (soft-delete) · `currency` |
| `transaction.dart` | `Transaction` · `TransactionType {income, expense}` · `TransactionCategory` (8 values) · `currency`, `rateToBase`, `fee` · `amountInBase`, `feeInBase` |
| `transfer_model.dart` | `Transfer` · `TransferCategory` (7 values) · `toAmount`, `toCurrency`, `rate`, `rateToBase`, `reversalOfId` · `isCrossCurrency`, `isReversal` |
| `debt_model.dart` | `Debt` · `DebtType {owe, owed}` · `isPaid`. **No currency — implicitly base.** |
| `budget_model.dart` | `Budget` · `BudgetPeriod {weekly, monthly, yearly}` · nullable `category` (null = overall). **Base currency.** |
| `user_model.dart` | `UserModel` (uid, name, email, createdAt) |
| `currency_model.dart` | `Currency` + 8-entry `registry` (ETB default) · `ExchangeRate` |
| `app_settings.dart` | `AppSettings` (baseCurrency, titheRate, rates map) · `rateFor()` |

### Backward compatibility — do not break

Every field added during the multi-currency rework **defaults in `fromMap`**:
`currency → 'ETB'`, `rateToBase → 1.0`, `fee → 0.0`, `toAmount → amount`,
`rate → 1.0`, `category`/`reversalOfId` → null. Documents written before the
rework parse unchanged and behave exactly as they did. `test/models_migration_test.dart`
pins this contract — if you add a field, add a default and a test.

---

## `finance_service.dart` (~945 lines) — the API surface

`ChangeNotifier`, one per signed-in user.

**Reads:** `accounts` (active) · `allAccounts` · `spendableAccounts` (active,
non-savings) · `findAccount` · `transactions` · `findTransaction` · `transfers` ·
`debts` / `iOwe` / `owedToMe` · `budgets` · `allLedgerEntries` /
`recentLedgerEntries`

**Savings** (type-driven, never by id): `savingsAccounts` · `hasSavingsAccount` ·
`isSavingsAccount(id)` · `savingsTransfers` · `savingsHidden` · `savingsSummary`
→ `SavingsSummary {accounts, amount, currency, converted}`. `converted` is true
when the vaults span currencies and the total had to be converted at *current*
rates; the UI must render that with `≈` and say so.

**Currency:** `baseCurrency` · `currencyOf(accountId)` · `toBase(amount, code)` ·
`conversionRate(from, to)` · `balanceByCurrency`

**Aggregates** (all base currency unless noted): `totalBalance` ·
`accountBalance(id)` *(native currency)* · `totalIncome` / `totalExpenses` /
`totalFees` · `incomeInRange` / `expensesInRange` / `feesInRange` (nullable
`from`/`to`) · `incomeIn(period)` / `expensesIn` / `feesIn` ·
`expensesByCategoryInRange` · `balanceSeries` · `accountDistribution` ·
`trendFor(period)` · `lastNMonths(n)` · `spentInPeriod(budget)`

**Tithe:** `titheObligation` / `titheGiven` / `titheRemaining` / `titheProgress` /
`titheStatus`, all taking a `LedgerPeriod`

**Writes:** `addTransaction` / `deleteTransaction` · `addTransfer` /
`deleteTransfer` / `reverseTransfer` · `addAccount` / `deactivateAccount` /
`reactivateAccount` / `renameAccount` / `changeAccountCurrency` · `addDebt` /
`toggleDebtPaid` · `setBudget` / `deleteBudget` · `saveSettings` / `setTitheRate`
/ `setBaseCurrency` / `setRate` · `deleteAllUserData`

**Privacy (device-local, `SharedPreferences` — deliberately NOT synced;** it's
about who can see this phone's screen, not about the account): `totalHidden` ·
`isAccountHidden(id)` · `toggleTotalVisibility` · `toggleAccountVisibility` ·
`hideAll` / `showAll` / `allHidden`. Keys: `balance_hidden`, `hidden_accounts`.

**Pure functions (top-level, testable without Firebase):**
`computeAccountBalance(accountId, transactions, transfers)` ·
`computeTitheGiven(transactions, {from, to})` · `TitheStatus.of(...)`

**Shared types:** `LedgerPeriod {week, month, sixMonths, year, all}` with
`.label` / `.startFrom(now)` — used by both Giving and Insights ·
`LedgerEntry` (unified transaction+transfer row) · `MonthlySnapshot` ·
`TrendBucket` · `BalancePoint` · `AccountShare`

---

## Screens (`lib/screens/`)

| Screen | Notes |
|---|---|
| `splash_screen.dart` | Animated intro → `AuthGate` |
| `auth_screen.dart` | Sign in / sign up toggle, Google sign-in, password reset |
| `main_scaffold.dart` | 5-tab `IndexedStack` + bottom nav |
| `journal_screen.dart` | **Tab 0.** Total hero + per-account cards + 5 recent. Eye per card hides that account; hero eye hides the total; **long-press hero eye = hide/show everything** |
| `ledger_screen.dart` | **Tab 1.** Unified transaction+transfer list, filter by kind |
| `giving_screen.dart` | **Tab 2.** Tithe: obligation / given / remaining, real progress ring, editable rate, "Record Giving" writes a real tithe expense |
| `insights_screen.dart` | **Tab 3.** Period selector drives every card: summary tiles, trend bars, running-balance line, category donut (tap to drill), fees, account distribution, per-currency holdings |
| `finance_hub_screen.dart` | **Tab 4.** Action tiles + account list (edit/remove/restore) + savings & debt snapshots |
| `new_entry_screen.dart` | Add income/expense; currency follows the account; optional fee on expenses |
| `transfer_screen.dart` | Currency-aware amount, rate row + live preview when currencies differ, category chips, ⇅ swap |
| `transfer_history_screen.dart` | Full transfer record; reverse with optional fee refund; REVERSED / REVERSAL badges |
| `currency_settings_screen.dart` | Base currency + per-currency rates (drawer → Currency & rates) |
| `add_account_screen.dart` | New account with Ethiopian bank quick-picks |
| `savings_screen.dart` | Savings vault total, history, deposit sheet |
| `debt_screen.dart` | Tabbed I Owe / Owed To Me |
| `budget_screen.dart` | Budgets with progress bars |
| `profile_screen.dart` | Avatar, edit name, stats, sign out, delete account + all data |

---

## Widgets & theme

- `app_theme.dart` — `MysticColors` + `buildMysticTheme()`. `headlineStyle()`,
  `bodyStyle()`, `labelStyle()` helpers used everywhere.
- `app_feedback.dart` — `reportIfWriteFails`, `friendlyWriteError`,
  `showFeedback`. **All Firestore writes report through here** — see the next
  section. The API takes a `ScaffoldMessengerState`, not a `BuildContext`,
  because most writes report after the form has popped.
- `empty_state_card.dart` — `EmptyStateCard` + `NoAccountsCard`. The shared
  first-run/empty surface; use it instead of another private `_EmptyState`.
- `account_edit_sheet.dart` — `AccountEditSheet` + `showAccountEditSheet()`.
  Reached from both the Journal cards and the Finance Hub list.
- `app_drawer.dart` — nav + settings, incl. Currency & rates.
- `mystic_app_bar.dart`, `transaction_tile.dart`.

**Navigation:** `MainShell` (`main_scaffold.dart`) is an `InheritedWidget`
exposing `goToTab(index)` and `openDrawer()`. Every tab builds its *own*
`Scaffold` and only the shell's declares a `drawer:`, so `Scaffold.of(ctx)` from
inside a tab finds the wrong one and `openDrawer()` silently does nothing — go
through `MainShell.maybeOf(context)`.

---

## Writing to Firestore — the rule that isn't obvious

**Never `await` a Firestore write to drive navigation or a spinner.**

Offline persistence is on (`main.dart`). A write applies to the local cache
*immediately* — the snapshot listener fires and the UI updates — but its
`Future` does **not** resolve until the server acknowledges it. Awaiting one
therefore hangs the screen for the entire time the device is offline, which is
worse than no feedback at all.

The pattern everywhere is:

```dart
final messenger = ScaffoldMessenger.maybeOf(context); // capture BEFORE the pop
reportIfWriteFails(messenger, svc.addTransaction(tx));
Navigator.of(context).pop();
```

The messenger is captured first because the screen's own context is gone by the
time a server rejection arrives.

Save buttons additionally carry a `_saving` bool + `busy:` flag — without it a
double-tap wrote the entry twice.

### Chart colour — has rules

`ChartPalette` in `insights_screen.dart` is **CVD-validated** against the
parchment surface (`#F5F5DC`): every adjacent pair clears ΔE 8 under
protan/deutan/tritan, all clear 3:1 contrast, none reads grey.

- **Do not reorder or substitute without re-running** the `dataviz` skill's
  `scripts/validate_palette.js`.
- The palette this replaced put dark gold beside forest green — **ΔE 2.5 under
  protanopia**, i.e. indistinguishable.
- **Colour binds to the entity, never to sorted rank** — category by enum index,
  accounts by position in `allAccounts`. Rank-based colouring repaints series
  whenever the period filter changes ranking.

---

## Tests

```
test/models_migration_test.dart   legacy docs parse; round-trips survive
test/balance_math_test.dart       every balance sign rule + reversal invariants
test/tithe_test.dart              obligation/given/remaining/progress edges
test/widget_test.dart             ⚠️ FAILS — see below
```

`flutter test` → **34 pass, 1 fail.** The failure is pre-existing and unrelated:
`widget_test.dart` pumps `MysticLedgerApp` without `Firebase.initializeApp()`, so
it throws `[core/no-app] No Firebase App '[DEFAULT]'`. It gives no signal on
feature work. Fix it by mocking Firebase if you want a real smoke test.

`FinanceService` itself is not unit-tested (needs Firebase); that's why the
money-critical arithmetic was extracted into the pure functions listed above.

---

## Gotchas

- **`cloud_firestore` exports a lowercase `class sum`.** Hence
  `import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;` and
  why `sum` can't be a parameter name (triggers `avoid_types_as_parameter_names`).
- **`_streamCount = 6`** gates `isLoading`. Adding a listener without bumping it
  leaves the app on the spinner forever.
- **Changing an account's currency is blocked once it has entries**
  (`accountHasActivity`) — stored amounts are in that currency and would be
  silently reinterpreted.
- **Account removal is a soft delete** (`isActive: false`). History is preserved;
  restore from Finance Hub. Because it is reversible it is offered on *every*
  account, savings vaults included.
- **Editing an entry must preserve `date` and `rateToBase`.** `addTransaction`,
  `addDebt` and `setBudget` are upserts keyed by document id, so an edit is
  "prefill, keep the id, re-save" — but stamping `DateTime.now()` moves the
  entry into the current period (changing the tithe owed and budget spend for
  two months at once), and re-reading the live rate restates history, which is
  the exact thing the rate snapshot exists to prevent. Use
  `resolveRateToBase()` (`models/transaction.dart`); it re-snapshots only when
  the currency itself changed. Same shape of trap on debts: `Debt` defaults
  `isPaid: false`, so an edit must pass the existing value or it silently
  un-settles a settled debt.
- **Debts and Budgets have no currency field** — treated as base currency.
- `use_build_context_synchronously`: the codebase pattern is to capture
  `Navigator.of(context)` / `ScaffoldMessenger.of(context)` **before** an `await`
  and guard with `if (!mounted) return;`. `context.mounted` on a State's implicit
  `context` is *not* accepted by the analyzer.
- `app_theme.dart` suppresses `deprecated_member_use` for
  `background`/`onBackground` — will break on a future Flutter upgrade.
- `auth_screen.dart` `_forgotPassword()` creates a `TextEditingController` per
  dialog that is never disposed (small leak).

---

## Platform / release state

**Android and web are both configured but neither has been built or run.**

| Item | State |
|---|---|
| Signing | Credentials read from `android/key.properties` (gitignored). Copy `key.properties.example` and generate a keystore — **there is no key checked in** |
| `applicationId` | ⚠️ still `com.example.mystic_ledger` — **Play rejects `com.example.*`**, and it is permanent after the first upload |
| `targetSdk` | ⚠️ inherits Flutter 3.19.6's default of **33**; Play requires **35**. Needs a Flutter upgrade |
| R8 | `minifyEnabled`/`shrinkResources` on, with `proguard-rules.pro`. **Never verified against a real release build** |
| `firebase_options.dart` | ⚠️ **absent** — `Firebase.initializeApp()` takes no options, so **web cannot boot**. Run `flutterfire configure` |
| Google Sign-In on web | `web/index.html` has a placeholder client ID; `auth_service` still uses the Android-only plugin path |
| Firestore rules | Owner-scoped **plus schema validation**. Deploy with `firebase deploy --only firestore:rules` |
| Web layout | Phone-width; unconstrained at desktop widths |

---

## Known open items

- **Nothing has ever been run.** No device, no emulator, no `flutter run` — on
  either platform. Layout, overflow and label collisions are all unverified.
- The Play blockers in the table above (`applicationId`, `targetSdk`,
  `firebase_options.dart`) are the critical path.
- `widget_test.dart` Firebase failure (above).
- Debts and Budgets still have no `currency` field.
- Transfers are intentionally **not** editable or deletable — they are corrected
  by `reverseTransfer`, which records the opposing movement and keeps both
  halves. Tapping a transfer in the Ledger opens the reversal history.
- `balanceByCurrency` and `accountDistribution` *include* savings accounts while
  `totalBalance` excludes them. Pre-existing inconsistency; `savingsSummary` is
  kept strictly separate rather than deepening it.
- No Crashlytics, no CI, no privacy policy.
- Exchange rates are manual; no API feed (a deliberate choice, not an oversight).
- `landing_page/` is a separate Vercel-deployed site in the same repo.
