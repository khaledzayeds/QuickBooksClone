# QuickBooksClone Project Progress

This file is the living project notebook. Update it after every vertical slice.

## Current Direction

Build the system as working vertical slices:

1. Backend domain/contracts
2. In-memory infrastructure for fast testing
3. API endpoints
4. MAUI Desktop screen
5. Build + smoke test
6. Git commit

Database persistence, EF Core, and polished UI will come after the core workflows are proven.

## Completed

- [x] Project structure
  - [x] `QuickBooksClone.Api`
  - [x] `QuickBooksClone.Core`
  - [x] `QuickBooksClone.Infrastructure`
  - [x] `QuickBooksClone.Maui`
  - [x] Windows-only MAUI Desktop target
- [x] Strong SQL schema hardening draft
  - [x] `QuickBooksClone.Api/Database/zokaa_qb_schema_v2_hardening.sql`
- [x] Git local repository
  - [x] `cd90351 initial customers slice`
  - [x] `9e556dd add items slice`
  - [x] `5c78d8c add invoices skeleton slice`
- [x] Customers slice
  - [x] Core entity and repository contract
  - [x] In-memory repository
  - [x] API endpoints
  - [x] MAUI Desktop screen
  - [x] Build and API smoke test
- [x] Items slice
  - [x] Core entity and repository contract
  - [x] In-memory repository
  - [x] API endpoints
  - [x] MAUI Desktop screen
  - [x] Build and API smoke test
- [x] Invoices skeleton slice
  - [x] Core invoice and invoice line
  - [x] In-memory repository
  - [x] API endpoints
  - [x] MAUI Desktop screen
  - [x] Build and API smoke test
- [x] Chart of Accounts slice
  - [x] Account types and account entity
  - [x] In-memory repository
  - [x] API endpoints
  - [x] MAUI Desktop screen
  - [x] Build and API smoke test
- [x] Link Items to accounting accounts
  - [x] Income account
  - [x] Inventory asset account
  - [x] COGS account
  - [x] Expense account
  - [x] MAUI account selectors on Items screen
  - [x] API account existence validation
- [x] API endpoints documentation
  - [x] `API_ENDPOINTS.md`
- [x] Accounting transactions slice
  - [x] Transaction header
  - [x] Transaction lines
  - [x] Debit/credit validation
  - [x] Read-only transaction API
- [x] Invoice posting engine
  - [x] Posted invoice creates accounting transaction
  - [x] Basic AR / income posting
  - [x] Basic inventory COGS / inventory asset posting
  - [x] Post Invoice button in MAUI
- [x] Validation hardening slice
  - [x] Prevent duplicate item name, SKU, and barcode
  - [x] Prevent duplicate customer display name and email
  - [x] Prevent duplicate account code and name
  - [x] Reject negative item prices, quantities, and opening balances
  - [x] Reject invalid invoice line quantities, prices, and discounts
  - [x] Show clearer API validation/conflict messages in MAUI
  - [x] Restore a 50/50 desktop list/form layout for early screens
- [x] Transaction list screen slice
  - [x] MAUI transaction DTOs and API client
  - [x] Desktop Transactions page
  - [x] Transaction detail debit/credit lines
  - [x] Source type and voided filters
  - [x] Navigation menu link
- [x] Desktop navigation cleanup slice
  - [x] Accounts list separated from account form
  - [x] Customers list separated from customer form
  - [x] Items list separated from item form
  - [x] Invoices list separated from invoice creation form
  - [x] Chart of Accounts shows calculated balances
  - [x] Added API watch helper script
- [x] Sales invoice posting workflow hardening
  - [x] Dedicated sales invoice posting service
  - [x] Save Draft / Create and Post workflow
  - [x] Auto-post support for daily sales invoices
  - [x] Posting is idempotent
  - [x] Inventory stock is reduced when posted
  - [x] Posting blocks insufficient stock
  - [x] Accounting transaction remains balanced
- [x] Invoice reversal hardening
  - [x] Void draft/saved invoice marks it void without accounting impact
  - [x] Void posted invoice creates a balanced reversal transaction
  - [x] Void posted invoice returns inventory quantities
  - [x] Void is idempotent and does not double-create reversal effects
  - [x] Invoice responses expose posted and reversal transaction links
- [x] Payments slice
  - [x] Receive customer payment for posted invoices
  - [x] Auto-post payment accounting transaction
  - [x] Debit bank/cash and credit Accounts Receivable
  - [x] Apply payment to invoice balance
  - [x] Update invoice status to PartiallyPaid or Paid
  - [x] Payments API endpoints
  - [x] Desktop Payments list and Receive Payment form
- [x] Payment reversal hardening
  - [x] Void posted payment creates balanced reversal transaction
  - [x] Void posted payment restores invoice balance
  - [x] Invoice status returns to Posted or PartiallyPaid after reversal
  - [x] Payment void is idempotent
  - [x] Desktop Payments screen can void payments

## In Progress

- [ ] Posted invoice edit protection review
  - [x] Core invoice lines cannot be changed after posting
  - [ ] Confirm every future edit path respects posted/void status

## Next

- [ ] Vendors and purchases foundation
  - [ ] Vendor entity and endpoints
  - [ ] Vendor bills / purchase invoices
  - [ ] Receive inventory against purchases
- [ ] EF Core persistence
  - [ ] AppDbContext
  - [ ] Entity configurations
  - [ ] Migrations
  - [ ] Replace in-memory repositories
- [ ] Localization foundation
  - [ ] Arabic resources
  - [ ] English resources
  - [ ] Settings language switch
  - [ ] RTL/LTR behavior
- [ ] GitHub remote
  - [ ] Create empty GitHub repository
  - [ ] Add `origin`
  - [ ] Push `main`

## Deferred On Purpose

- [ ] Final UI polish
- [ ] Mobile targets
- [ ] Android/iOS workloads
- [ ] Docker/container setup
- [ ] Full authentication and authorization
- [ ] Payroll
- [ ] Advanced inventory lots/serials/FIFO

## Notes

- Current MAUI app talks to API at `http://localhost:5014`.
- Current repositories are intentionally in-memory to move fast.
- Account links on Items are intentionally waiting for Chart of Accounts.
- Invoice posting is intentionally waiting for account links and transaction rules.
