# Unified Transaction Workspace Progress

This is the living finish plan for making LedgerFlow feel like one coherent
desktop accounting product. Update it after every screen slice.

## Branch

- Working branch: `codex/unified-transaction-workspace`
- Baseline: `design/general-ui-refresh`
- Rule: keep `design/general-ui-refresh` as the approved Invoice baseline, and
  do broad unification work on this branch.

## Product Decision

Old transactions should open in their original workspace, not in a separate
static review page. The list/search screens are navigation and filtering
surfaces only. Clicking a row returns the user to the real document workspace
with the saved data loaded.

The workspace decides what is editable from accounting state:

- Draft: editable financial fields and lines; Save Draft and Save/Post enabled.
- Posted/open with no applied payments/credits/returns: editable when backend
  supports safe update and repost.
- Partially paid, paid, credited, returned: same workspace, but financial
  fields and lines are read-only. Operational actions remain available where
  logical: notes, print, receive payment when balance remains, refund/return
  when allowed by backend policy.
- Void: same workspace, read-only, with invalid actions disabled.

## Finish Workflow Per Screen

Each screen gets two passes:

1. Design pass: adopt the unified workspace shell, command bar, side context
   panel, line grid/list style, search/list screen, hover states, disabled
   states, and consistent close/navigation behavior.
2. Backend binding pass: verify every button against the backend. Missing
   endpoints or service behavior should be implemented immediately in the same
   slice, then validated with targeted Flutter analysis and backend build/API
   checks where needed.

## Reusable Templates To Build

- `TransactionWorkspaceFrame`: common desktop document frame with command bar,
  collapsible context panel, footer shortcut strip, and safe responsive layout.
- `TransactionWorkspaceCommandBar`: icon + label command bar with hover,
  tooltip, busy, disabled, and separator behavior.
- `TransactionWorkspaceStatePolicy`: one state object per document that tells
  the UI which operations are enabled.
- `TransactionLineGrid`: common editable/read-only line grid behavior.
- `TransactionSearchList`: common search/filter/list pattern for all document
  list screens.
- `TransactionContextPanel`: common right/left side panel with customer/vendor
  balance, recent transactions, notes, and warnings.
- `DocumentActionBinding`: per-screen mapping between UI actions and real
  backend operations.

## Screen Priority

### Priority 1 - Customer Side

1. Invoice - baseline completed, now used as reference.
2. Sales Receipt - convert to the same workspace and search/list behavior.
3. Estimate - same workspace, with convert/close action policy.
4. Customer Credit - same workspace, credit application logic wired.

### Priority 2 - Customer Follow-up Documents

5. Sales Return - same workspace, invoice-linked return policy.
6. Receive Payment - same workspace/list style, invoice prefill already started.

### Priority 3 - Vendor/Purchase Side

7. Purchase Order - same workspace, receive/create bill actions.
8. Purchase Bill - same workspace, vendor payment and return links.
9. Vendor Credit - same workspace, apply credit behavior.
10. Purchase Return - same workspace, bill-linked return policy.
11. Vendor Payment - same workspace/list style and bill allocation behavior.

### Backlog / Confirm Scope

- Sales Order: route exists, but include in the 11 only if the user wants it
  before Vendor Payment or Receive Payment.
- Receive Inventory: route exists and is important, but it may belong to the
  Purchase Order flow rather than the first 11 document screens.
- Global Transaction Find: separate general search screen reachable from the
  dashboard, with transaction type, customer/vendor, date, number, amount, and
  go-to behavior. This should reuse `TransactionSearchList`.

## Backend Review Checklist

For each document screen:

- Confirm create/update/post/void endpoints.
- Confirm safe state transition rules.
- Confirm print data endpoint supports A4/Thermal settings.
- Confirm notes endpoint exists or add it.
- Confirm attachments/email buttons are disabled until services are real.
- Confirm list search/filter endpoint supports required fields, or use client
  filtering only as a temporary first pass.
- Confirm related actions pass IDs through routes, for example invoice to
  receive payment or bill to vendor payment.

## Current Progress

- [x] Invoice visual workspace approved.
- [x] Invoice old-row open now returns to Invoice workspace.
- [x] Invoice list/search upgraded to filtered result table.
- [x] Invoice payment/refund/print/notes/void actions wired to backend or
  deliberately disabled where service is missing.
- [x] Sales Receipt opens saved rows in the receipt workspace instead of a
  static review page.
- [x] Sales Receipt list/search upgraded to the same local filter pattern:
  text search, status filter, date range, and row go-to behavior.
- [x] Sales Receipt workspace uses read-only accounting state for saved/voided
  receipts, with print, notes, and void actions kept in the document workspace.
- [ ] Extract Invoice workspace pieces into reusable templates.
- [x] Apply the first unified workspace/list behavior to Sales Receipt.
- [ ] Apply templates to Estimate.
- [ ] Apply templates to Customer Credit.
- [ ] Continue through the remaining priority list one screen at a time.
