# Bold Budget — Net Worth Redesign Roadmap

_Turning Bold Budget from a spending ledger into a full picture of net worth, while keeping "add a transaction" the fastest thing you can do._

**Companion mockups:** [net-worth-redesign-mockups.html](net-worth-redesign-mockups.html) — five phone screens in the app's signature look. Open in a browser.

---

## 1. The problem

The app today is a clean **transaction ledger**: a `Budget` holds `Transaction`s, `Category`s, and `RecurringExpense`s. There is no concept of *where money lives*, so it can't answer "what's my checking balance?" or "what's my net worth?" — the exact questions the retirement spreadsheet exists to answer.

Priorities for the redesign (in order of how often each is used):

1. **Add a transaction** — the overwhelmingly common action; must stay instant.
2. **Check balances & net worth** — the spreadsheet's job, moved into the app.
3. **Cohesion** — transactions should link to accounts and move their balances automatically.

---

## 2. The core idea: `Account` as a first-class entity

One new primitive that everything else hangs off of.

```
Account
  id, name              "America First", "Robinhood", "CX-30 Loan"
  class:   .asset | .liability
  type:    .checking .savings .cash .hysa .brokerage .retirement
           .creditCard .loan .mortgage .other
  trackingMode: .ledger | .snapshot         ← the key distinction
  balance: SignedMoney
  snapshots: [BalanceSnapshot(date, value)]  // for .snapshot accounts
```

**The insight that makes this fit real behavior:** retirement/investment accounts aren't tracked transaction-by-transaction — you punch in a number every month. That's a `.snapshot` account, and it *is* the spreadsheet (America First, Vanguard, 401k, Betterment, Robinhood are all snapshot accounts with a monthly value history). Checking/credit are `.ledger` accounts where every transaction moves the balance. Supporting both is what lets the app retire the spreadsheet **and** deliver the cohesion, instead of forcing everything into one model.

**Net worth** then falls out for free: `assets − liabilities`, with a `NetWorthSnapshot` time series driving the chart that replaces the spreadsheet's Total row.

---

## 3. Cohesion: transactions move accounts

`Transaction` gains an explicit `kind` and account links:

| Kind | Account fields | Effect |
| --- | --- | --- |
| **Expense** | `accountId` | balance ↓ |
| **Income** | `accountId` | balance ↑ |
| **Transfer** | `fromAccountId` / `toAccountId` | moves between accounts; **net-worth-neutral** |

Transfers (paycheck → checking, checking → HYSA, credit-card payment, loan payment) keep balances honest *without* polluting spending totals — money you merely shuffled shouldn't look like spending.

`RecurringExpense` unifies here: a **bill/subscription** is a scheduled *transaction*; a **debt** is a *liability account* with a recurring transfer that draws down `remainingBalance`. Same data, finally one model.

---

## 4. Two settled decisions

### Balance model — **stored + reconcile**
Each account stores a balance that every transaction adjusts (matches the app's existing optimistic-update pattern in `Budget.save(transaction:)`). A **Reconcile** action snaps a ledger account to a real bank number when it drifts. Simplest, fastest to ship; no per-read recomputation.

### Money — **add `SignedMoney`**
`Money` stays non-negative for transaction amounts (keeps the keypad clean). A separate **`SignedMoney`** handles balances, deltas, and net worth — which can go negative (investments drop, loans owed, months like Mar '25's −$156,538 change).

---

## 5. Rollout releases

Sequenced so nothing breaks and the spreadsheet dies early. The current shipping version is **1.11**; this redesign opens the **2.x** line.

### v2.0 — Accounts + Net Worth home _(retire the spreadsheet)_ ✅ **Complete**
- ✅ New domain types: `Account` (+ `Class` / `Kind` / `TrackingMode`), `AccountName`, `BalanceSnapshot`, `SignedMoney`.
- ✅ `Budget` gains an `accounts: [Account.Id: Account]` dictionary + `AccountFetcher` / `AccountSaver` / `AccountDeleter` workers mirroring the existing pattern, with optimistic `save`/`remove` and net-worth computed helpers.
- ✅ Firestore `Accounts` subcollection under each budget (`FirebaseAccountRepository` / `FirebaseAccountDoc`).
- ✅ **Net Worth screen** (`NetWorthListContent`): net-worth total, assets/liabilities split, grouped account list — added as a new tab in `BudgetDetailView`.
- ✅ **Add / edit account** (`EditAccountView`): type picker grouped by class, keypad balance entry, snapshot balance history, delete.
- ✅ No changes to existing spending views; app + test targets build clean.

**Deferred out of v2.0** (tracked, not blocking): net-worth-over-time area chart (needs cross-account monthly alignment); the elevated Add / Net Worth / Spending 3-tab IA (v2.1 territory); unit tests for `Account` / `SignedMoney`.

**⚠️ Ops before release:** update the **deployed** Firestore rules to allow the new `Accounts` subcollection — the repo `firestore.rules` is stale and the live rules live elsewhere. Accounts will not persist on real devices until this is done.

### v2.1 — Link transactions to accounts + Transfers
- `Transaction` gains `kind` (`.expense`/`.income`/`.transfer`) + `accountId` / `fromAccountId` / `toAccountId`.
- `save(transaction:)` / `remove(transaction:)` also adjust the affected account's stored balance.
- Add-transaction UI: From-Account chip + Transfer mode.
- Spending rows show an account chip; transfers render as net-worth-neutral.

### v2.2 — Fold recurring debts into liabilities
- Migrate `RecurringExpense` debts into liability accounts; a payment becomes a recurring transfer that draws down the balance.
- Bills/subscriptions become scheduled transactions.

### v2.3 — Reconcile & polish
- Reconcile flow for ledger accounts; drift indicators; history editing; ledger account detail refinements.

---

## 6. Migration & data

- Existing transactions migrate as **account-less** (`kind` defaults to income/expense from their category's existing `kind`); they keep working untouched.
- Snapshot accounts are the on-ramp: enter spreadsheet columns as monthly `BalanceSnapshot`s to reproduce the historical net-worth chart immediately.
- Net-worth history can be backfilled from snapshots even before any transaction links exist.

---

## 7. Codebase notes / gotchas

- **New domain types** (`Account.swift`, `SignedMoney.swift`, etc.) live alongside `Money` / `Transaction` in `Domain/`.
- **Firestore rules:** a new `accounts` subcollection requires updating the **deployed** rules — the repo `firestore.rules` is stale and denies unlisted subcollections.
- **Test targets** compile app files directly via `PBXFileSystemSynchronizedBuildFileExceptionSet` in `project.pbxproj` (no `@testable import`). New shared types referenced by test-target members must be appended to those exception lists, or `xcodebuild build-for-testing` breaks.
- **Workers pattern:** follow the existing `Fetcher` / `Saver` / `Deleter` trio + Firebase repo + mock, wired through the Swinject `iocContainer`.
- **Optimistic updates:** `Budget` already does optimistic mutate-then-rollback-on-error; account balance adjustments should follow the same shape.

---

_Design palette: brand teal `#009193`; income/asset/gain green; expense/liability/loss red. Screens shown in the app's dark theme (black ground, teal accent, white text)._
