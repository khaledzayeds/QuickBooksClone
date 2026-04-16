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

## In Progress

- [ ] Link Items to accounting accounts
  - [ ] Income account
  - [ ] Inventory asset account
  - [ ] COGS account
  - [ ] Expense account

## Next

- [ ] Invoice posting engine
  - [ ] Draft invoice stays editable
  - [ ] Posted invoice creates accounting transaction
  - [ ] Posted invoice cannot be edited directly
  - [ ] Void/reversal rules
- [ ] Payments slice
  - [ ] Receive payment
  - [ ] Apply payment to invoice
  - [ ] Update invoice balance
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
