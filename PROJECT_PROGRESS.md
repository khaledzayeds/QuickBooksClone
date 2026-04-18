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
- [x] Vendors foundation slice
  - [x] Vendor entity and repository contract
  - [x] In-memory vendor repository with seed data
  - [x] Vendor API endpoints
  - [x] Duplicate display name and email validation
  - [x] Desktop Vendors list and vendor form
  - [x] Vendor navigation link
- [x] Purchase bills foundation
  - [x] Purchase bill header and lines
  - [x] Save Draft / Create and Post workflow
  - [x] Purchase bill posting service
  - [x] Post inventory receipts into stock
  - [x] Debit Inventory Asset or Expense
  - [x] Credit Accounts Payable
  - [x] Update vendor balance
  - [x] Purchase bill API endpoints
  - [x] Desktop Purchase Bills list and creation form
- [x] Purchase bill reversal hardening
  - [x] Void draft purchase bill without accounting impact
  - [x] Void posted purchase bill creates balanced reversal transaction
  - [x] Void posted purchase bill reduces received inventory safely
  - [x] Void blocks when current stock is not enough to reverse receipt
  - [x] Void reverses vendor balance
  - [x] Purchase bill void is idempotent
  - [x] Desktop Purchase Bills screen can void bills
- [x] Opening balances posting slice
  - [x] Customer opening balances post to Accounts Receivable
  - [x] Vendor opening balances post to Accounts Payable
  - [x] Inventory item opening quantities post to Inventory Asset
  - [x] Opening balance offset posts to Equity
  - [x] Opening balance posting is idempotent by source document
  - [x] Inventory opening quantity requires purchase price and inventory asset account
- [x] Vendor payments slice
  - [x] Pay posted purchase bill
  - [x] Debit Accounts Payable and credit bank/cash
  - [x] Apply payment to purchase bill balance
  - [x] Update purchase bill status to PartiallyPaid or Paid
  - [x] Reduce vendor balance
  - [x] Vendor payment API endpoints
  - [x] Desktop Vendor Payments list and Pay Vendor form
- [x] Vendor payment reversal hardening
  - [x] Void posted vendor payment creates balanced reversal transaction
  - [x] Void posted vendor payment restores purchase bill balance
  - [x] Void posted vendor payment restores vendor balance
  - [x] Purchase bill status returns to Posted or PartiallyPaid after reversal
  - [x] Vendor payment void is idempotent
  - [x] Desktop Vendor Payments screen can void payments
- [x] Cash sale / invoice payment mode
  - [x] Support cash vs credit sales workflow
  - [x] Auto-create receipt payment for cash invoices
  - [x] Link generated receipt payment back to the invoice
  - [x] Show payment mode, paid amount, balance, and deposit account on invoice screens
  - [x] Keep invoice and payment posting logic in dedicated services
- [x] Sales return / credit memo workflow
  - [x] Sales return document linked to posted invoice
  - [x] Return quantities validated against original invoice lines
  - [x] Posted sales return reverses income and Accounts Receivable
  - [x] Inventory returns increase stock and reverse COGS
  - [x] Invoice exposes returned amount and updated balance
  - [x] Desktop Sales Returns list and creation form
- [x] Customer credit / refund handling
  - [x] Customer credit balance created from paid sales returns
  - [x] Apply customer credit to another invoice
  - [x] Refund customer credit through bank/cash account
  - [x] Refund creates balanced accounting transaction
  - [x] Invoice exposes credit applied amount
  - [x] Desktop Customer Credits list and activity form
- [x] Vendor credits / purchase returns
  - [x] Purchase return document linked to posted purchase bill
  - [x] Return quantities validated against original purchase bill lines
  - [x] Posted purchase return reverses Accounts Payable and inventory/expense
  - [x] Inventory returns reduce stock safely
  - [x] Purchase bill exposes returned amount and zero-floor balance due
  - [x] Paid bill returns create vendor credit balance
  - [x] Desktop Purchase Returns list and creation form
- [x] Vendor credit application / refund receipt
  - [x] Apply vendor credit to another purchase bill
  - [x] Receive vendor refund into bank/cash account
  - [x] Refund receipt creates balanced accounting transaction
  - [x] Purchase bill exposes vendor credit applied amount
  - [x] Desktop Vendor Credits list and activity form
- [x] Customer/vendor subledger balance review
  - [x] Credit invoice posting increases customer balance
  - [x] Customer payments reduce customer balance
  - [x] Sales returns reduce customer balance before creating customer credit
  - [x] Customer credit application reduces customer balance and credit balance
  - [x] Verified vendor balance rules already move through bills, payments, returns, and credits

## In Progress

- [ ] Posted invoice edit protection review
  - [x] Core invoice lines cannot be changed after posting
  - [ ] Confirm every future edit path respects posted/void status

## Next

- [ ] Inventory adjustment workflow
  - [ ] Increase/decrease inventory with reason
  - [ ] Post inventory asset and adjustment gain/loss
  - [ ] Block invalid negative stock adjustments
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
