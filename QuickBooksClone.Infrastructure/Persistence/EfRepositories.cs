using Microsoft.EntityFrameworkCore;
using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.CustomerCredits;
using QuickBooksClone.Core.Customers;
using QuickBooksClone.Core.InventoryAdjustments;
using QuickBooksClone.Core.Invoices;
using QuickBooksClone.Core.Items;
using QuickBooksClone.Core.JournalEntries;
using QuickBooksClone.Core.Payments;
using QuickBooksClone.Core.PurchaseBills;
using QuickBooksClone.Core.PurchaseOrders;
using QuickBooksClone.Core.PurchaseReturns;
using QuickBooksClone.Core.SalesReturns;
using QuickBooksClone.Core.VendorCredits;
using QuickBooksClone.Core.VendorPayments;
using QuickBooksClone.Core.Vendors;

namespace QuickBooksClone.Infrastructure.Persistence;

public sealed class EfAccountRepository : IAccountRepository
{
    private readonly QuickBooksCloneDbContext _db;
    public EfAccountRepository(QuickBooksCloneDbContext db) => _db = db;

    public async Task<AccountListResult> SearchAsync(AccountSearch search, CancellationToken cancellationToken = default)
    {
        var page = Math.Max(search.Page, 1);
        var pageSize = Math.Clamp(search.PageSize, 1, 200);
        var query = _db.Accounts.AsQueryable();
        if (!search.IncludeInactive) query = query.Where(account => account.IsActive);
        if (search.AccountType is not null) query = query.Where(account => account.AccountType == search.AccountType);
        if (!string.IsNullOrWhiteSpace(search.Search))
        {
            var term = Like(search.Search);
            query = query.Where(account => EF.Functions.Like(account.Code, term) || EF.Functions.Like(account.Name, term));
        }

        var total = await query.CountAsync(cancellationToken);
        var items = await query.OrderBy(account => account.Code).ThenBy(account => account.Name).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(cancellationToken);
        return new AccountListResult(items, total, page, pageSize);
    }

    public Task<Account?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) => _db.Accounts.FirstOrDefaultAsync(account => account.Id == id, cancellationToken);
    public Task<bool> CodeExistsAsync(string code, Guid? excludingId = null, CancellationToken cancellationToken = default) => _db.Accounts.AnyAsync(account => account.Id != excludingId && account.Code == code.Trim(), cancellationToken);
    public Task<bool> NameExistsAsync(string name, Guid? excludingId = null, CancellationToken cancellationToken = default) => _db.Accounts.AnyAsync(account => account.Id != excludingId && account.Name == name.Trim(), cancellationToken);

    public async Task<Account> AddAsync(Account account, CancellationToken cancellationToken = default)
    {
        _db.Accounts.Add(account);
        await _db.SaveChangesAsync(cancellationToken);
        return account;
    }

    public async Task<Account?> UpdateAsync(Guid id, string code, string name, AccountType accountType, string? description, Guid? parentId, CancellationToken cancellationToken = default)
    {
        var account = await GetByIdAsync(id, cancellationToken);
        if (account is null) return null;
        account.Update(code, name, accountType, description, parentId);
        await _db.SaveChangesAsync(cancellationToken);
        return account;
    }

    public async Task<bool> SetActiveAsync(Guid id, bool isActive, CancellationToken cancellationToken = default)
    {
        var account = await GetByIdAsync(id, cancellationToken);
        if (account is null) return false;
        account.SetActive(isActive);
        await _db.SaveChangesAsync(cancellationToken);
        return true;
    }

    internal static string Like(string value) => $"%{value.Trim()}%";
}

public sealed class EfAccountingTransactionRepository : IAccountingTransactionRepository
{
    private readonly QuickBooksCloneDbContext _db;
    public EfAccountingTransactionRepository(QuickBooksCloneDbContext db) => _db = db;

    public async Task<AccountingTransactionListResult> SearchAsync(AccountingTransactionSearch search, CancellationToken cancellationToken = default)
    {
        var page = Math.Max(search.Page, 1);
        var pageSize = Math.Clamp(search.PageSize, 1, 200);
        var query = _db.AccountingTransactions.Include(transaction => transaction.Lines).AsQueryable();
        if (!search.IncludeVoided) query = query.Where(transaction => transaction.Status != AccountingTransactionStatus.Voided);
        if (!string.IsNullOrWhiteSpace(search.SourceEntityType)) query = query.Where(transaction => transaction.SourceEntityType == search.SourceEntityType);
        if (search.SourceEntityId is not null) query = query.Where(transaction => transaction.SourceEntityId == search.SourceEntityId);
        if (!string.IsNullOrWhiteSpace(search.Search))
        {
            var term = EfAccountRepository.Like(search.Search);
            query = query.Where(transaction => EF.Functions.Like(transaction.ReferenceNumber, term) || EF.Functions.Like(transaction.TransactionType, term));
        }

        var total = await query.CountAsync(cancellationToken);
        var items = await query.OrderByDescending(transaction => transaction.TransactionDate).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(cancellationToken);
        return new AccountingTransactionListResult(items, total, page, pageSize);
    }

    public Task<AccountingTransaction?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) => _db.AccountingTransactions.Include(transaction => transaction.Lines).FirstOrDefaultAsync(transaction => transaction.Id == id, cancellationToken);
    public Task<AccountingTransaction?> GetBySourceAsync(string sourceEntityType, Guid sourceEntityId, CancellationToken cancellationToken = default) => _db.AccountingTransactions.Include(transaction => transaction.Lines).FirstOrDefaultAsync(transaction => transaction.SourceEntityType == sourceEntityType && transaction.SourceEntityId == sourceEntityId && transaction.Status != AccountingTransactionStatus.Voided, cancellationToken);

    public async Task<AccountingTransaction> AddAsync(AccountingTransaction transaction, CancellationToken cancellationToken = default)
    {
        transaction.ValidateBalanced();
        _db.AccountingTransactions.Add(transaction);
        await _db.SaveChangesAsync(cancellationToken);
        return transaction;
    }
}

public sealed class EfCustomerRepository : ICustomerRepository
{
    private readonly QuickBooksCloneDbContext _db;
    public EfCustomerRepository(QuickBooksCloneDbContext db) => _db = db;

    public async Task<CustomerListResult> SearchAsync(CustomerSearch search, CancellationToken cancellationToken = default)
    {
        var page = Math.Max(search.Page, 1);
        var pageSize = Math.Clamp(search.PageSize, 1, 100);
        var query = _db.Customers.AsQueryable();
        if (!search.IncludeInactive) query = query.Where(customer => customer.IsActive);
        if (!string.IsNullOrWhiteSpace(search.Search))
        {
            var term = EfAccountRepository.Like(search.Search);
            query = query.Where(customer => EF.Functions.Like(customer.DisplayName, term) || (customer.CompanyName != null && EF.Functions.Like(customer.CompanyName, term)) || (customer.Email != null && EF.Functions.Like(customer.Email, term)) || (customer.Phone != null && EF.Functions.Like(customer.Phone, term)));
        }

        var total = await query.CountAsync(cancellationToken);
        var items = await query.OrderBy(customer => customer.DisplayName).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(cancellationToken);
        return new CustomerListResult(items, total, page, pageSize);
    }

    public Task<Customer?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) => _db.Customers.FirstOrDefaultAsync(customer => customer.Id == id, cancellationToken);
    public Task<bool> DisplayNameExistsAsync(string displayName, Guid? excludingId = null, CancellationToken cancellationToken = default) => _db.Customers.AnyAsync(customer => customer.Id != excludingId && customer.DisplayName == displayName.Trim(), cancellationToken);
    public Task<bool> EmailExistsAsync(string email, Guid? excludingId = null, CancellationToken cancellationToken = default) => _db.Customers.AnyAsync(customer => customer.Id != excludingId && customer.Email == email.Trim(), cancellationToken);
    public async Task<Customer> AddAsync(Customer customer, CancellationToken cancellationToken = default) { _db.Customers.Add(customer); await _db.SaveChangesAsync(cancellationToken); return customer; }
    public async Task<Customer?> UpdateAsync(Guid id, string displayName, string? companyName, string? email, string? phone, string currency, CancellationToken cancellationToken = default) { var customer = await GetByIdAsync(id, cancellationToken); if (customer is null) return null; customer.Update(displayName, companyName, email, phone, currency); await _db.SaveChangesAsync(cancellationToken); return customer; }
    public Task<bool> SetActiveAsync(Guid id, bool isActive, CancellationToken cancellationToken = default) => MutateAsync(id, customer => customer.SetActive(isActive), cancellationToken);
    public Task<bool> ApplyInvoiceAsync(Guid id, decimal amount, CancellationToken cancellationToken = default) => MutateAsync(id, customer => customer.ApplyInvoice(amount), cancellationToken);
    public Task<bool> ReverseInvoiceAsync(Guid id, decimal amount, CancellationToken cancellationToken = default) => MutateAsync(id, customer => customer.ReverseInvoice(amount), cancellationToken);
    public Task<bool> ApplyPaymentAsync(Guid id, decimal amount, CancellationToken cancellationToken = default) => MutateAsync(id, customer => customer.ApplyPayment(amount), cancellationToken);
    public Task<bool> ReversePaymentAsync(Guid id, decimal amount, CancellationToken cancellationToken = default) => MutateAsync(id, customer => customer.ReversePayment(amount), cancellationToken);
    public Task<bool> ApplySalesReturnAsync(Guid id, decimal amount, CancellationToken cancellationToken = default) => MutateAsync(id, customer => customer.ApplySalesReturn(amount), cancellationToken);
    public Task<bool> AddCreditAsync(Guid id, decimal amount, CancellationToken cancellationToken = default) => MutateAsync(id, customer => customer.AddCredit(amount), cancellationToken);
    public Task<bool> UseCreditAsync(Guid id, decimal amount, CancellationToken cancellationToken = default) => MutateAsync(id, customer => customer.UseCredit(amount), cancellationToken);
    public Task<bool> ApplyCreditToInvoiceAsync(Guid id, decimal amount, CancellationToken cancellationToken = default) => MutateAsync(id, customer => customer.ApplyCreditToInvoice(amount), cancellationToken);
    private async Task<bool> MutateAsync(Guid id, Action<Customer> mutation, CancellationToken cancellationToken) { var customer = await GetByIdAsync(id, cancellationToken); if (customer is null) return false; mutation(customer); await _db.SaveChangesAsync(cancellationToken); return true; }
}

public sealed class EfVendorRepository : IVendorRepository
{
    private readonly QuickBooksCloneDbContext _db;
    public EfVendorRepository(QuickBooksCloneDbContext db) => _db = db;
    public async Task<VendorListResult> SearchAsync(VendorSearch search, CancellationToken cancellationToken = default) { var page = Math.Max(search.Page, 1); var pageSize = Math.Clamp(search.PageSize, 1, 100); var query = _db.Vendors.AsQueryable(); if (!search.IncludeInactive) query = query.Where(vendor => vendor.IsActive); if (!string.IsNullOrWhiteSpace(search.Search)) { var term = EfAccountRepository.Like(search.Search); query = query.Where(vendor => EF.Functions.Like(vendor.DisplayName, term) || (vendor.CompanyName != null && EF.Functions.Like(vendor.CompanyName, term)) || (vendor.Email != null && EF.Functions.Like(vendor.Email, term)) || (vendor.Phone != null && EF.Functions.Like(vendor.Phone, term))); } var total = await query.CountAsync(cancellationToken); var items = await query.OrderBy(vendor => vendor.DisplayName).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(cancellationToken); return new VendorListResult(items, total, page, pageSize); }
    public Task<Vendor?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) => _db.Vendors.FirstOrDefaultAsync(vendor => vendor.Id == id, cancellationToken);
    public Task<bool> DisplayNameExistsAsync(string displayName, Guid? excludingId = null, CancellationToken cancellationToken = default) => _db.Vendors.AnyAsync(vendor => vendor.Id != excludingId && vendor.DisplayName == displayName.Trim(), cancellationToken);
    public Task<bool> EmailExistsAsync(string email, Guid? excludingId = null, CancellationToken cancellationToken = default) => _db.Vendors.AnyAsync(vendor => vendor.Id != excludingId && vendor.Email == email.Trim(), cancellationToken);
    public async Task<Vendor> AddAsync(Vendor vendor, CancellationToken cancellationToken = default) { _db.Vendors.Add(vendor); await _db.SaveChangesAsync(cancellationToken); return vendor; }
    public async Task<Vendor?> UpdateAsync(Guid id, string displayName, string? companyName, string? email, string? phone, string currency, CancellationToken cancellationToken = default) { var vendor = await GetByIdAsync(id, cancellationToken); if (vendor is null) return null; vendor.Update(displayName, companyName, email, phone, currency); await _db.SaveChangesAsync(cancellationToken); return vendor; }
    public Task<bool> SetActiveAsync(Guid id, bool isActive, CancellationToken cancellationToken = default) => MutateAsync(id, vendor => vendor.SetActive(isActive), cancellationToken);
    public Task<bool> ApplyBillAsync(Guid id, decimal amount, CancellationToken cancellationToken = default) => MutateAsync(id, vendor => vendor.ApplyBill(amount), cancellationToken);
    public Task<bool> ReverseBillAsync(Guid id, decimal amount, CancellationToken cancellationToken = default) => MutateAsync(id, vendor => vendor.ReverseBill(amount), cancellationToken);
    public Task<bool> ApplyPaymentAsync(Guid id, decimal amount, CancellationToken cancellationToken = default) => MutateAsync(id, vendor => vendor.ApplyPayment(amount), cancellationToken);
    public Task<bool> ReversePaymentAsync(Guid id, decimal amount, CancellationToken cancellationToken = default) => MutateAsync(id, vendor => vendor.ReversePayment(amount), cancellationToken);
    public Task<bool> ApplyPurchaseReturnAsync(Guid id, decimal amount, CancellationToken cancellationToken = default) => MutateAsync(id, vendor => vendor.ApplyPurchaseReturn(amount), cancellationToken);
    public Task<bool> UseCreditAsync(Guid id, decimal amount, CancellationToken cancellationToken = default) => MutateAsync(id, vendor => vendor.UseCredit(amount), cancellationToken);
    private async Task<bool> MutateAsync(Guid id, Action<Vendor> mutation, CancellationToken cancellationToken) { var vendor = await GetByIdAsync(id, cancellationToken); if (vendor is null) return false; mutation(vendor); await _db.SaveChangesAsync(cancellationToken); return true; }
}

public sealed class EfItemRepository : IItemRepository
{
    private readonly QuickBooksCloneDbContext _db;
    public EfItemRepository(QuickBooksCloneDbContext db) => _db = db;
    public async Task<ItemListResult> SearchAsync(ItemSearch search, CancellationToken cancellationToken = default) { var page = Math.Max(search.Page, 1); var pageSize = Math.Clamp(search.PageSize, 1, 100); var query = _db.Items.AsQueryable(); if (!search.IncludeInactive) query = query.Where(item => item.IsActive); if (!string.IsNullOrWhiteSpace(search.Search)) { var term = EfAccountRepository.Like(search.Search); query = query.Where(item => EF.Functions.Like(item.Name, term) || (item.Sku != null && EF.Functions.Like(item.Sku, term)) || (item.Barcode != null && EF.Functions.Like(item.Barcode, term))); } var total = await query.CountAsync(cancellationToken); var items = await query.OrderBy(item => item.Name).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(cancellationToken); return new ItemListResult(items, total, page, pageSize); }
    public Task<Item?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) => _db.Items.FirstOrDefaultAsync(item => item.Id == id, cancellationToken);
    public Task<bool> NameExistsAsync(string name, Guid? excludingId = null, CancellationToken cancellationToken = default) => _db.Items.AnyAsync(item => item.Id != excludingId && item.Name == name.Trim(), cancellationToken);
    public Task<bool> SkuExistsAsync(string sku, Guid? excludingId = null, CancellationToken cancellationToken = default) => _db.Items.AnyAsync(item => item.Id != excludingId && item.Sku == sku.Trim(), cancellationToken);
    public Task<bool> BarcodeExistsAsync(string barcode, Guid? excludingId = null, CancellationToken cancellationToken = default) => _db.Items.AnyAsync(item => item.Id != excludingId && item.Barcode == barcode.Trim(), cancellationToken);
    public async Task<Item> AddAsync(Item item, CancellationToken cancellationToken = default) { _db.Items.Add(item); await _db.SaveChangesAsync(cancellationToken); return item; }
    public async Task<Item?> UpdateAsync(Guid id, string name, ItemType itemType, string? sku, string? barcode, decimal salesPrice, decimal purchasePrice, string unit, Guid? incomeAccountId, Guid? inventoryAssetAccountId, Guid? cogsAccountId, Guid? expenseAccountId, CancellationToken cancellationToken = default) { var item = await GetByIdAsync(id, cancellationToken); if (item is null) return null; item.Update(name, itemType, sku, barcode, salesPrice, purchasePrice, unit, incomeAccountId, inventoryAssetAccountId, cogsAccountId, expenseAccountId); await _db.SaveChangesAsync(cancellationToken); return item; }
    public Task<bool> SetActiveAsync(Guid id, bool isActive, CancellationToken cancellationToken = default) => MutateAsync(id, item => item.SetActive(isActive), cancellationToken);
    public Task<bool> AdjustQuantityAsync(Guid id, decimal quantityOnHand, CancellationToken cancellationToken = default) => MutateAsync(id, item => item.AdjustQuantity(quantityOnHand), cancellationToken);
    public Task<bool> DecreaseQuantityAsync(Guid id, decimal quantity, CancellationToken cancellationToken = default) => MutateAsync(id, item => item.DecreaseQuantity(quantity), cancellationToken);
    public Task<bool> IncreaseQuantityAsync(Guid id, decimal quantity, CancellationToken cancellationToken = default) => MutateAsync(id, item => item.IncreaseQuantity(quantity), cancellationToken);
    private async Task<bool> MutateAsync(Guid id, Action<Item> mutation, CancellationToken cancellationToken) { var item = await GetByIdAsync(id, cancellationToken); if (item is null) return false; mutation(item); await _db.SaveChangesAsync(cancellationToken); return true; }
}

public abstract class EfDocumentRepository<TDocument, TResult, TSearch>
    where TDocument : class
{
    protected readonly QuickBooksCloneDbContext Db;
    protected EfDocumentRepository(QuickBooksCloneDbContext db) => Db = db;
    protected static (int Page, int PageSize) Page(int page, int pageSize, int max = 100) => (Math.Max(page, 1), Math.Clamp(pageSize, 1, max));
}

public sealed class EfInvoiceRepository : IInvoiceRepository
{
    private readonly QuickBooksCloneDbContext _db;
    public EfInvoiceRepository(QuickBooksCloneDbContext db) => _db = db;
    private IQueryable<Invoice> Query() => _db.Invoices.Include(invoice => invoice.Lines);
    public async Task<InvoiceListResult> SearchAsync(InvoiceSearch search, CancellationToken cancellationToken = default) { var page = Math.Max(search.Page, 1); var pageSize = Math.Clamp(search.PageSize, 1, 100); var query = Query(); if (!search.IncludeVoid) query = query.Where(invoice => invoice.Status != InvoiceStatus.Void); if (search.CustomerId is not null) query = query.Where(invoice => invoice.CustomerId == search.CustomerId); if (search.PaymentMode is not null) query = query.Where(invoice => invoice.PaymentMode == search.PaymentMode); if (!string.IsNullOrWhiteSpace(search.Search)) { var term = EfAccountRepository.Like(search.Search); query = query.Where(invoice => EF.Functions.Like(invoice.InvoiceNumber, term)); } var total = await query.CountAsync(cancellationToken); var items = await query.OrderByDescending(invoice => invoice.InvoiceDate).ThenByDescending(invoice => invoice.InvoiceNumber).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(cancellationToken); return new InvoiceListResult(items, total, page, pageSize); }
    public Task<Invoice?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) => Query().FirstOrDefaultAsync(invoice => invoice.Id == id, cancellationToken);
    public async Task<Invoice> AddAsync(Invoice invoice, CancellationToken cancellationToken = default) { _db.Invoices.Add(invoice); await _db.SaveChangesAsync(cancellationToken); return invoice; }
    public Task<bool> MarkSentAsync(Guid id, CancellationToken cancellationToken = default) => MutateAsync(id, invoice => invoice.MarkSent(), cancellationToken);
    public Task<bool> MarkPostedAsync(Guid id, Guid transactionId, CancellationToken cancellationToken = default) => MutateAsync(id, invoice => invoice.MarkPosted(transactionId), cancellationToken);
    public Task<bool> ApplyPaymentAsync(Guid id, decimal amount, CancellationToken cancellationToken = default) => MutateAsync(id, invoice => invoice.ApplyPayment(amount), cancellationToken);
    public Task<bool> LinkReceiptPaymentAsync(Guid id, Guid paymentId, CancellationToken cancellationToken = default) => MutateAsync(id, invoice => invoice.LinkReceiptPayment(paymentId), cancellationToken);
    public Task<bool> ReversePaymentAsync(Guid id, decimal amount, CancellationToken cancellationToken = default) => MutateAsync(id, invoice => invoice.ReversePayment(amount), cancellationToken);
    public Task<bool> ApplyCreditAsync(Guid id, decimal amount, CancellationToken cancellationToken = default) => MutateAsync(id, invoice => invoice.ApplyCredit(amount), cancellationToken);
    public Task<bool> ApplyReturnAsync(Guid id, decimal amount, CancellationToken cancellationToken = default) => MutateAsync(id, invoice => invoice.ApplyReturn(amount), cancellationToken);
    public Task<bool> VoidAsync(Guid id, Guid? reversalTransactionId = null, CancellationToken cancellationToken = default) => MutateAsync(id, invoice => invoice.Void(reversalTransactionId), cancellationToken);
    private async Task<bool> MutateAsync(Guid id, Action<Invoice> mutation, CancellationToken cancellationToken) { var invoice = await GetByIdAsync(id, cancellationToken); if (invoice is null) return false; mutation(invoice); await _db.SaveChangesAsync(cancellationToken); return true; }
}

public sealed class EfPaymentRepository : IPaymentRepository
{
    private readonly QuickBooksCloneDbContext _db;
    public EfPaymentRepository(QuickBooksCloneDbContext db) => _db = db;
    public async Task<PaymentListResult> SearchAsync(PaymentSearch search, CancellationToken cancellationToken = default) { var page = Math.Max(search.Page, 1); var pageSize = Math.Clamp(search.PageSize, 1, 100); var query = _db.Payments.AsQueryable(); if (!search.IncludeVoid) query = query.Where(payment => payment.Status != PaymentStatus.Void); if (search.CustomerId is not null) query = query.Where(payment => payment.CustomerId == search.CustomerId); if (search.InvoiceId is not null) query = query.Where(payment => payment.InvoiceId == search.InvoiceId); if (!string.IsNullOrWhiteSpace(search.Search)) { var term = EfAccountRepository.Like(search.Search); query = query.Where(payment => EF.Functions.Like(payment.PaymentNumber, term) || EF.Functions.Like(payment.PaymentMethod, term)); } var total = await query.CountAsync(cancellationToken); var items = await query.OrderByDescending(payment => payment.PaymentDate).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(cancellationToken); return new PaymentListResult(items, total, page, pageSize); }
    public Task<Payment?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) => _db.Payments.FirstOrDefaultAsync(payment => payment.Id == id, cancellationToken);
    public async Task<Payment> AddAsync(Payment payment, CancellationToken cancellationToken = default) { _db.Payments.Add(payment); await _db.SaveChangesAsync(cancellationToken); return payment; }
    public Task<bool> MarkPostedAsync(Guid id, Guid transactionId, CancellationToken cancellationToken = default) => MutateAsync(id, payment => payment.MarkPosted(transactionId), cancellationToken);
    public Task<bool> VoidAsync(Guid id, Guid? reversalTransactionId = null, CancellationToken cancellationToken = default) => MutateAsync(id, payment => payment.Void(reversalTransactionId), cancellationToken);
    private async Task<bool> MutateAsync(Guid id, Action<Payment> mutation, CancellationToken cancellationToken) { var payment = await GetByIdAsync(id, cancellationToken); if (payment is null) return false; mutation(payment); await _db.SaveChangesAsync(cancellationToken); return true; }
}

public sealed class EfPurchaseBillRepository : IPurchaseBillRepository
{
    private readonly QuickBooksCloneDbContext _db;
    public EfPurchaseBillRepository(QuickBooksCloneDbContext db) => _db = db;
    private IQueryable<PurchaseBill> Query() => _db.PurchaseBills.Include(bill => bill.Lines);
    public async Task<PurchaseBillListResult> SearchAsync(PurchaseBillSearch search, CancellationToken cancellationToken = default) { var page = Math.Max(search.Page, 1); var pageSize = Math.Clamp(search.PageSize, 1, 100); var query = Query(); if (!search.IncludeVoid) query = query.Where(bill => bill.Status != PurchaseBillStatus.Void); if (search.VendorId is not null) query = query.Where(bill => bill.VendorId == search.VendorId); if (!string.IsNullOrWhiteSpace(search.Search)) { var term = EfAccountRepository.Like(search.Search); query = query.Where(bill => EF.Functions.Like(bill.BillNumber, term)); } var total = await query.CountAsync(cancellationToken); var items = await query.OrderByDescending(bill => bill.BillDate).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(cancellationToken); return new PurchaseBillListResult(items, total, page, pageSize); }
    public Task<PurchaseBill?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) => Query().FirstOrDefaultAsync(bill => bill.Id == id, cancellationToken);
    public async Task<PurchaseBill> AddAsync(PurchaseBill bill, CancellationToken cancellationToken = default) { _db.PurchaseBills.Add(bill); await _db.SaveChangesAsync(cancellationToken); return bill; }
    public Task<bool> MarkPostedAsync(Guid id, Guid transactionId, CancellationToken cancellationToken = default) => MutateAsync(id, bill => bill.MarkPosted(transactionId), cancellationToken);
    public Task<bool> ApplyPaymentAsync(Guid id, decimal amount, CancellationToken cancellationToken = default) => MutateAsync(id, bill => bill.ApplyPayment(amount), cancellationToken);
    public Task<bool> ReversePaymentAsync(Guid id, decimal amount, CancellationToken cancellationToken = default) => MutateAsync(id, bill => bill.ReversePayment(amount), cancellationToken);
    public Task<bool> ApplyCreditAsync(Guid id, decimal amount, CancellationToken cancellationToken = default) => MutateAsync(id, bill => bill.ApplyCredit(amount), cancellationToken);
    public Task<bool> ApplyReturnAsync(Guid id, decimal amount, CancellationToken cancellationToken = default) => MutateAsync(id, bill => bill.ApplyReturn(amount), cancellationToken);
    public Task<bool> VoidAsync(Guid id, Guid? reversalTransactionId = null, CancellationToken cancellationToken = default) => MutateAsync(id, bill => bill.Void(reversalTransactionId), cancellationToken);
    private async Task<bool> MutateAsync(Guid id, Action<PurchaseBill> mutation, CancellationToken cancellationToken) { var bill = await GetByIdAsync(id, cancellationToken); if (bill is null) return false; mutation(bill); await _db.SaveChangesAsync(cancellationToken); return true; }
}

public sealed class EfPurchaseOrderRepository : IPurchaseOrderRepository
{
    private readonly QuickBooksCloneDbContext _db;
    public EfPurchaseOrderRepository(QuickBooksCloneDbContext db) => _db = db;
    private IQueryable<PurchaseOrder> Query() => _db.PurchaseOrders.Include(order => order.Lines);
    public async Task<PurchaseOrderListResult> SearchAsync(PurchaseOrderSearch search, CancellationToken cancellationToken = default) { var page = Math.Max(search.Page, 1); var pageSize = Math.Clamp(search.PageSize, 1, 100); var query = Query(); if (!search.IncludeClosed) query = query.Where(order => order.Status != PurchaseOrderStatus.Closed); if (!search.IncludeCancelled) query = query.Where(order => order.Status != PurchaseOrderStatus.Cancelled); if (search.VendorId is not null) query = query.Where(order => order.VendorId == search.VendorId); if (!string.IsNullOrWhiteSpace(search.Search)) { var term = EfAccountRepository.Like(search.Search); query = query.Where(order => EF.Functions.Like(order.OrderNumber, term)); } var total = await query.CountAsync(cancellationToken); var items = await query.OrderByDescending(order => order.OrderDate).ThenByDescending(order => order.OrderNumber).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(cancellationToken); return new PurchaseOrderListResult(items, total, page, pageSize); }
    public Task<PurchaseOrder?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) => Query().FirstOrDefaultAsync(order => order.Id == id, cancellationToken);
    public async Task<PurchaseOrder> AddAsync(PurchaseOrder order, CancellationToken cancellationToken = default) { _db.PurchaseOrders.Add(order); await _db.SaveChangesAsync(cancellationToken); return order; }
    public Task<bool> MarkOpenAsync(Guid id, CancellationToken cancellationToken = default) => MutateAsync(id, order => order.MarkOpen(), cancellationToken);
    public Task<bool> CloseAsync(Guid id, CancellationToken cancellationToken = default) => MutateAsync(id, order => order.Close(), cancellationToken);
    public Task<bool> CancelAsync(Guid id, CancellationToken cancellationToken = default) => MutateAsync(id, order => order.Cancel(), cancellationToken);
    private async Task<bool> MutateAsync(Guid id, Action<PurchaseOrder> mutation, CancellationToken cancellationToken) { var order = await GetByIdAsync(id, cancellationToken); if (order is null) return false; mutation(order); await _db.SaveChangesAsync(cancellationToken); return true; }
}

public sealed class EfVendorPaymentRepository : IVendorPaymentRepository
{
    private readonly QuickBooksCloneDbContext _db;
    public EfVendorPaymentRepository(QuickBooksCloneDbContext db) => _db = db;
    public async Task<VendorPaymentListResult> SearchAsync(VendorPaymentSearch search, CancellationToken cancellationToken = default) { var page = Math.Max(search.Page, 1); var pageSize = Math.Clamp(search.PageSize, 1, 100); var query = _db.VendorPayments.AsQueryable(); if (!search.IncludeVoid) query = query.Where(payment => payment.Status != VendorPaymentStatus.Void); if (search.VendorId is not null) query = query.Where(payment => payment.VendorId == search.VendorId); if (search.PurchaseBillId is not null) query = query.Where(payment => payment.PurchaseBillId == search.PurchaseBillId); if (!string.IsNullOrWhiteSpace(search.Search)) { var term = EfAccountRepository.Like(search.Search); query = query.Where(payment => EF.Functions.Like(payment.PaymentNumber, term) || EF.Functions.Like(payment.PaymentMethod, term)); } var total = await query.CountAsync(cancellationToken); var items = await query.OrderByDescending(payment => payment.PaymentDate).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(cancellationToken); return new VendorPaymentListResult(items, total, page, pageSize); }
    public Task<VendorPayment?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) => _db.VendorPayments.FirstOrDefaultAsync(payment => payment.Id == id, cancellationToken);
    public async Task<VendorPayment> AddAsync(VendorPayment payment, CancellationToken cancellationToken = default) { _db.VendorPayments.Add(payment); await _db.SaveChangesAsync(cancellationToken); return payment; }
    public Task<bool> MarkPostedAsync(Guid id, Guid transactionId, CancellationToken cancellationToken = default) => MutateAsync(id, payment => payment.MarkPosted(transactionId), cancellationToken);
    public Task<bool> VoidAsync(Guid id, Guid? reversalTransactionId = null, CancellationToken cancellationToken = default) => MutateAsync(id, payment => payment.Void(reversalTransactionId), cancellationToken);
    private async Task<bool> MutateAsync(Guid id, Action<VendorPayment> mutation, CancellationToken cancellationToken) { var payment = await GetByIdAsync(id, cancellationToken); if (payment is null) return false; mutation(payment); await _db.SaveChangesAsync(cancellationToken); return true; }
}

public sealed class EfSalesReturnRepository : ISalesReturnRepository
{
    private readonly QuickBooksCloneDbContext _db;
    public EfSalesReturnRepository(QuickBooksCloneDbContext db) => _db = db;
    private IQueryable<SalesReturn> Query() => _db.SalesReturns.Include(salesReturn => salesReturn.Lines);
    public async Task<SalesReturnListResult> SearchAsync(SalesReturnSearch search, CancellationToken cancellationToken = default) { var page = Math.Max(search.Page, 1); var pageSize = Math.Clamp(search.PageSize, 1, 100); var query = Query(); if (!search.IncludeVoid) query = query.Where(salesReturn => salesReturn.Status != SalesReturnStatus.Void); if (search.InvoiceId is not null) query = query.Where(salesReturn => salesReturn.InvoiceId == search.InvoiceId); if (search.CustomerId is not null) query = query.Where(salesReturn => salesReturn.CustomerId == search.CustomerId); if (!string.IsNullOrWhiteSpace(search.Search)) { var term = EfAccountRepository.Like(search.Search); query = query.Where(salesReturn => EF.Functions.Like(salesReturn.ReturnNumber, term)); } var total = await query.CountAsync(cancellationToken); var items = await query.OrderByDescending(salesReturn => salesReturn.ReturnDate).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(cancellationToken); return new SalesReturnListResult(items, total, page, pageSize); }
    public Task<SalesReturn?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) => Query().FirstOrDefaultAsync(salesReturn => salesReturn.Id == id, cancellationToken);
    public async Task<SalesReturn> AddAsync(SalesReturn salesReturn, CancellationToken cancellationToken = default) { _db.SalesReturns.Add(salesReturn); await _db.SaveChangesAsync(cancellationToken); return salesReturn; }
    public async Task<bool> MarkPostedAsync(Guid id, Guid transactionId, CancellationToken cancellationToken = default) { var salesReturn = await GetByIdAsync(id, cancellationToken); if (salesReturn is null) return false; salesReturn.MarkPosted(transactionId); await _db.SaveChangesAsync(cancellationToken); return true; }
}

public sealed class EfPurchaseReturnRepository : IPurchaseReturnRepository
{
    private readonly QuickBooksCloneDbContext _db;
    public EfPurchaseReturnRepository(QuickBooksCloneDbContext db) => _db = db;
    private IQueryable<PurchaseReturn> Query() => _db.PurchaseReturns.Include(purchaseReturn => purchaseReturn.Lines);
    public async Task<PurchaseReturnListResult> SearchAsync(PurchaseReturnSearch search, CancellationToken cancellationToken = default) { var page = Math.Max(search.Page, 1); var pageSize = Math.Clamp(search.PageSize, 1, 100); var query = Query(); if (!search.IncludeVoid) query = query.Where(purchaseReturn => purchaseReturn.Status != PurchaseReturnStatus.Void); if (search.PurchaseBillId is not null) query = query.Where(purchaseReturn => purchaseReturn.PurchaseBillId == search.PurchaseBillId); if (search.VendorId is not null) query = query.Where(purchaseReturn => purchaseReturn.VendorId == search.VendorId); if (!string.IsNullOrWhiteSpace(search.Search)) { var term = EfAccountRepository.Like(search.Search); query = query.Where(purchaseReturn => EF.Functions.Like(purchaseReturn.ReturnNumber, term)); } var total = await query.CountAsync(cancellationToken); var items = await query.OrderByDescending(purchaseReturn => purchaseReturn.ReturnDate).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(cancellationToken); return new PurchaseReturnListResult(items, total, page, pageSize); }
    public Task<PurchaseReturn?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) => Query().FirstOrDefaultAsync(purchaseReturn => purchaseReturn.Id == id, cancellationToken);
    public async Task<PurchaseReturn> AddAsync(PurchaseReturn purchaseReturn, CancellationToken cancellationToken = default) { _db.PurchaseReturns.Add(purchaseReturn); await _db.SaveChangesAsync(cancellationToken); return purchaseReturn; }
    public async Task<bool> MarkPostedAsync(Guid id, Guid transactionId, CancellationToken cancellationToken = default) { var purchaseReturn = await GetByIdAsync(id, cancellationToken); if (purchaseReturn is null) return false; purchaseReturn.MarkPosted(transactionId); await _db.SaveChangesAsync(cancellationToken); return true; }
}

public sealed class EfCustomerCreditActivityRepository : ICustomerCreditActivityRepository
{
    private readonly QuickBooksCloneDbContext _db;
    public EfCustomerCreditActivityRepository(QuickBooksCloneDbContext db) => _db = db;
    public async Task<CustomerCreditActivityListResult> SearchAsync(CustomerCreditActivitySearch search, CancellationToken cancellationToken = default) { var page = Math.Max(search.Page, 1); var pageSize = Math.Clamp(search.PageSize, 1, 100); var query = _db.CustomerCreditActivities.AsQueryable(); if (!search.IncludeVoid) query = query.Where(activity => activity.Status != CustomerCreditStatus.Void); if (search.CustomerId is not null) query = query.Where(activity => activity.CustomerId == search.CustomerId); if (search.Action is not null) query = query.Where(activity => activity.Action == search.Action); if (!string.IsNullOrWhiteSpace(search.Search)) { var term = EfAccountRepository.Like(search.Search); query = query.Where(activity => EF.Functions.Like(activity.ReferenceNumber, term) || (activity.PaymentMethod != null && EF.Functions.Like(activity.PaymentMethod, term))); } var total = await query.CountAsync(cancellationToken); var items = await query.OrderByDescending(activity => activity.ActivityDate).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(cancellationToken); return new CustomerCreditActivityListResult(items, total, page, pageSize); }
    public Task<CustomerCreditActivity?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) => _db.CustomerCreditActivities.FirstOrDefaultAsync(activity => activity.Id == id, cancellationToken);
    public async Task<CustomerCreditActivity> AddAsync(CustomerCreditActivity activity, CancellationToken cancellationToken = default) { _db.CustomerCreditActivities.Add(activity); await _db.SaveChangesAsync(cancellationToken); return activity; }
    public async Task<bool> MarkPostedAsync(Guid id, Guid? transactionId = null, CancellationToken cancellationToken = default) { var activity = await GetByIdAsync(id, cancellationToken); if (activity is null) return false; activity.MarkPosted(transactionId); await _db.SaveChangesAsync(cancellationToken); return true; }
}

public sealed class EfVendorCreditActivityRepository : IVendorCreditActivityRepository
{
    private readonly QuickBooksCloneDbContext _db;
    public EfVendorCreditActivityRepository(QuickBooksCloneDbContext db) => _db = db;
    public async Task<VendorCreditActivityListResult> SearchAsync(VendorCreditActivitySearch search, CancellationToken cancellationToken = default) { var page = Math.Max(search.Page, 1); var pageSize = Math.Clamp(search.PageSize, 1, 100); var query = _db.VendorCreditActivities.AsQueryable(); if (!search.IncludeVoid) query = query.Where(activity => activity.Status != VendorCreditStatus.Void); if (search.VendorId is not null) query = query.Where(activity => activity.VendorId == search.VendorId); if (search.Action is not null) query = query.Where(activity => activity.Action == search.Action); if (!string.IsNullOrWhiteSpace(search.Search)) { var term = EfAccountRepository.Like(search.Search); query = query.Where(activity => EF.Functions.Like(activity.ReferenceNumber, term) || (activity.PaymentMethod != null && EF.Functions.Like(activity.PaymentMethod, term))); } var total = await query.CountAsync(cancellationToken); var items = await query.OrderByDescending(activity => activity.ActivityDate).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(cancellationToken); return new VendorCreditActivityListResult(items, total, page, pageSize); }
    public Task<VendorCreditActivity?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) => _db.VendorCreditActivities.FirstOrDefaultAsync(activity => activity.Id == id, cancellationToken);
    public async Task<VendorCreditActivity> AddAsync(VendorCreditActivity activity, CancellationToken cancellationToken = default) { _db.VendorCreditActivities.Add(activity); await _db.SaveChangesAsync(cancellationToken); return activity; }
    public async Task<bool> MarkPostedAsync(Guid id, Guid? transactionId = null, CancellationToken cancellationToken = default) { var activity = await GetByIdAsync(id, cancellationToken); if (activity is null) return false; activity.MarkPosted(transactionId); await _db.SaveChangesAsync(cancellationToken); return true; }
}

public sealed class EfInventoryAdjustmentRepository : IInventoryAdjustmentRepository
{
    private readonly QuickBooksCloneDbContext _db;
    public EfInventoryAdjustmentRepository(QuickBooksCloneDbContext db) => _db = db;
    public async Task<InventoryAdjustmentListResult> SearchAsync(InventoryAdjustmentSearch search, CancellationToken cancellationToken = default) { var page = Math.Max(search.Page, 1); var pageSize = Math.Clamp(search.PageSize, 1, 100); var query = _db.InventoryAdjustments.AsQueryable(); if (!search.IncludeVoid) query = query.Where(adjustment => adjustment.Status != InventoryAdjustmentStatus.Void); if (search.ItemId is not null) query = query.Where(adjustment => adjustment.ItemId == search.ItemId); if (!string.IsNullOrWhiteSpace(search.Search)) { var term = EfAccountRepository.Like(search.Search); query = query.Where(adjustment => EF.Functions.Like(adjustment.AdjustmentNumber, term) || EF.Functions.Like(adjustment.Reason, term)); } var total = await query.CountAsync(cancellationToken); var items = await query.OrderByDescending(adjustment => adjustment.AdjustmentDate).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(cancellationToken); return new InventoryAdjustmentListResult(items, total, page, pageSize); }
    public Task<InventoryAdjustment?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) => _db.InventoryAdjustments.FirstOrDefaultAsync(adjustment => adjustment.Id == id, cancellationToken);
    public async Task<InventoryAdjustment> AddAsync(InventoryAdjustment adjustment, CancellationToken cancellationToken = default) { _db.InventoryAdjustments.Add(adjustment); await _db.SaveChangesAsync(cancellationToken); return adjustment; }
    public async Task<bool> MarkPostedAsync(Guid id, Guid transactionId, CancellationToken cancellationToken = default) { var adjustment = await GetByIdAsync(id, cancellationToken); if (adjustment is null) return false; adjustment.MarkPosted(transactionId); await _db.SaveChangesAsync(cancellationToken); return true; }
}

public sealed class EfJournalEntryRepository : IJournalEntryRepository
{
    private readonly QuickBooksCloneDbContext _db;
    public EfJournalEntryRepository(QuickBooksCloneDbContext db) => _db = db;
    private IQueryable<JournalEntry> Query() => _db.JournalEntries.Include(entry => entry.Lines);
    public async Task<JournalEntryListResult> SearchAsync(JournalEntrySearch search, CancellationToken cancellationToken = default) { var page = Math.Max(search.Page, 1); var pageSize = Math.Clamp(search.PageSize, 1, 100); var query = Query(); if (!search.IncludeVoid) query = query.Where(entry => entry.Status != JournalEntryStatus.Void); if (!string.IsNullOrWhiteSpace(search.Search)) { var term = EfAccountRepository.Like(search.Search); query = query.Where(entry => EF.Functions.Like(entry.EntryNumber, term) || EF.Functions.Like(entry.Memo, term)); } var total = await query.CountAsync(cancellationToken); var items = await query.OrderByDescending(entry => entry.EntryDate).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(cancellationToken); return new JournalEntryListResult(items, total, page, pageSize); }
    public Task<JournalEntry?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) => Query().FirstOrDefaultAsync(entry => entry.Id == id, cancellationToken);
    public async Task<JournalEntry> AddAsync(JournalEntry journalEntry, CancellationToken cancellationToken = default) { _db.JournalEntries.Add(journalEntry); await _db.SaveChangesAsync(cancellationToken); return journalEntry; }
    public async Task<bool> MarkPostedAsync(Guid id, Guid transactionId, CancellationToken cancellationToken = default) { var entry = await GetByIdAsync(id, cancellationToken); if (entry is null) return false; entry.MarkPosted(transactionId); await _db.SaveChangesAsync(cancellationToken); return true; }
    public async Task<bool> VoidAsync(Guid id, Guid? reversalTransactionId, CancellationToken cancellationToken = default) { var entry = await GetByIdAsync(id, cancellationToken); if (entry is null) return false; entry.Void(reversalTransactionId); await _db.SaveChangesAsync(cancellationToken); return true; }
}

