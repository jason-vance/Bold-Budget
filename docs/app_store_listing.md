# App Store Listing — Bold Budget v2.0

_Copy for App Store Connect. Character counts are shown as `(used/limit)`; App Store limits are hard._

---

## Name

`(29/30)`

```
Bold Budget: Envelope Planner
```

## Subtitle

`(27/30)`

```
Net Worth & Expense Tracker
```

## Categories

| Slot | Value |
| --- | --- |
| Primary | Finance |
| Secondary | Lifestyle |

## Promotional Text

`(145/170)` — editable any time without a new build; use it for the 2.0 launch.

```
Bold Budget 2.0 is here: track every account, watch your net worth over time, and add a transaction in two taps with the new keypad-first screen.
```

---

## Description

`(2,262/4,000)`

```
Bold Budget shows you the whole picture: what you spent this month, what you own, what you owe, and where your net worth is heading.

TRACK EVERY ACCOUNT
Add checking, savings, high-yield savings, cash, brokerage, and retirement accounts alongside credit cards, loans, and mortgages. Choose how each one is tracked: let your transactions move the balance automatically, or enter the number yourself whenever it changes — ideal for investment and retirement accounts you only check once a month.

SEE YOUR NET WORTH
Assets minus liabilities on one screen, with a chart of how it has moved over time. Assets and liabilities are split out and totaled, and each account shows when it was last updated so you always know how current the number is.

ADD A TRANSACTION IN SECONDS
The Add screen opens straight to the keypad. Type the amount, tap a category, done. Add a title, account, location, date, or tags only when you want to.

EXPENSES, INCOME, AND TRANSFERS
Moving money between your own accounts isn't spending. Transfers keep your balances honest while staying out of your spending totals — paychecks into checking, savings contributions, credit card and loan payments.

ENVELOPES AND CATEGORY GOALS
Organize spending into categories with your own icons and colors. Give a category a goal — a cap to stay under or a target to reach — and see at a glance where you stand.

CHARTS THAT MAKE SENSE
A spending breakdown by category for whatever timeframe you pick: week, month, year, or a custom range. Filter by account, tag, or category to answer a specific question.

RECURRING EXPENSES
Keep bills and subscriptions in one list with a running monthly total, so nothing catches you off guard.

TAG WHAT MATTERS
Tag transactions by trip, celebration, project, or any other event, then filter to see exactly what it cost.

SHARE A BUDGET
Invite someone to a budget by username. Owners can add and edit everything; viewers can follow along without changing anything — built for couples, families, and roommates. Everything syncs across devices, so a transaction added on one phone shows up on the other.

Take charge of your financial future with Bold Budget — your tool for mindful spending and financial clarity.

Download now and start seeing the whole picture.
```

---

## What's New in This Version

`(1,401/4,000)`

```
Bold Budget 2.0 — the biggest update yet, and a complete redesign.

ACCOUNTS
• Track checking, savings, high-yield savings, cash, brokerage, retirement, credit cards, loans, and mortgages
• Choose how each account updates: automatically from your transactions, or a balance you enter yourself
• Editable balance history, plus reconcile to snap an account back to your bank's real number

NET WORTH
• New Net Worth tab: assets minus liabilities, with assets and liabilities totaled separately
• Net worth over time, charted
• "As of" dates so a stale balance is obvious at a glance

TRANSACTIONS
• The Add screen is now keypad-first — amount, category, done
• Link a transaction to an account and its balance moves automatically
• Transfers between your own accounts, kept out of spending totals
• Create an account or a category without leaving the transaction editor
• Categories now work for income and expenses alike, and a category goal can be a cap to stay under or a target to reach

SHARING
• Invite someone to a budget by username, with owner and viewer roles
• Switch between budgets right from Settings

DESIGN
• Every screen redesigned for light and dark
• Green and red used consistently for gains and losses throughout
• Faster charts, smoother envelopes, and many small fixes

Have a recurring debt? Open it and tap "Convert to Liability Account" to move it into the new accounts system.
```

---

## Keywords

`(98/100)` — comma-separated, single words, no spaces anywhere.

```
money,finance,spending,debt,savings,account,bill,subscription,credit,loan,cash,family,shared,buget
```

**Why these, and why not the old list:**

- **Apple indexes Name + Subtitle + Keywords as one pool and auto-combines terms across all three.** Anything already in the name or subtitle is wasted here. That rules out `budget`, `envelope`, `planner`, `bold` (name) and `net`, `worth`, `expense`, `tracker` (subtitle) — the old list spent ~25 of its 100 characters re-buying `net worth`, `networth`, and `expense`, which were already ranked.
- **No spaces, and no multi-word phrases.** `net worth` should never be a keyword entry — Apple builds the phrase itself from `net` + `worth`. Every space is a character bought for nothing.
- **Singular only.** `savings` is here as a product noun (savings account), not as a plural of `saving`; elsewhere use one form and let Apple's matching handle the other.
- **Spanish belongs in its own locale.** In the US storefront Apple indexes both the English (U.S.) *and* Spanish (Mexico) keyword fields, so `ahorro`/`meta`/`deuda` were burning English characters for coverage that's free in the es-MX localization. Move them there — a ready-to-paste es-MX field is below.
- **No competitor names.** Rival app names in the keyword field are a trademark issue and a known rejection cause, so none are suggested.
- **The description is not indexed.** Unlike Google Play, Apple ignores description text for search — the description above is written for conversion, not keywords, and shouldn't be stuffed.

### Keywords — Spanish (Mexico) localization

`(94/100)` — free additional indexing in the US storefront; requires adding an es-MX localization in App Store Connect.

```
ahorro,meta,deuda,gastos,dinero,presupuesto,finanzas,cuenta,tarjeta,credito,familia,patrimonio
```

---

## Open decisions

- **App name — which terms get the heaviest slot.** Apple weights Name > Subtitle > Keywords, so this is a ranking decision, not just a branding one. Both pairings below cover the same term pool within the limits; they differ in what ranks hardest:

  | | Option A (as written above) | Option B |
  | --- | --- | --- |
  | Name | `Bold Budget: Envelope Planner` (29/30) | `Bold Budget: Net Worth Tracker` (30/30) |
  | Subtitle | `Net Worth & Expense Tracker` (27/30) | `Envelope Planner & Expenses` (27/30) |
  | Ranks hardest for | envelope budgeting | net worth tracking |

  Option A is written above because it keeps the existing name — a rename costs some accumulated ranking and any external links/word-of-mouth built on it. Take Option B if 2.0's repositioning toward net worth is the priority, since "net worth tracker" is the higher-intent, less crowded query and envelope terms still stay indexed via the subtitle.
- **Screenshots.** The current set predates the redesign and shows none of the new Net Worth screen. A `Bold Budget (Screenshots)` scheme and `ScreenshotMode` exist in the working tree for regenerating them.
- **Firestore rules.** Accounts will not persist on real devices until the deployed rules allow the `Accounts` subcollection — the repo's `firestore.rules` is stale. Blocker for release, not for the listing.
