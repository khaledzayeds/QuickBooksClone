using Microsoft.EntityFrameworkCore;
using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Common;
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
using QuickBooksClone.Core.ReceiveInventory;
using QuickBooksClone.Core.SalesReturns;
using QuickBooksClone.Core.Settings;
using QuickBooksClone.Core.VendorCredits;
using QuickBooksClone.Core.VendorPayments;
using QuickBooksClone.Core.Vendors;

namespace QuickBooksClone.Infrastructure.Persistence;

public sealed class QuickBooksCloneDbContext : DbContext
{
    public QuickBooksCloneDbContext(DbContextOptions<QuickBooksCloneDbContext> options)
        : base(options)
    {
    }

    public DbSet<Account> Accounts => Set<Account>();
    public DbSet<AccountingTransaction> AccountingTransactions => Set<AccountingTransaction>();
    public DbSet<Customer> Customers => Set<Customer>();
    public DbSet<CustomerCreditActivity> CustomerCreditActivities => Set<CustomerCreditActivity>();
    public DbSet<InventoryAdjustment> InventoryAdjustments => Set<InventoryAdjustment>();
    public DbSet<Invoice> Invoices => Set<Invoice>();
    public DbSet<Item> Items => Set<Item>();
    public DbSet<JournalEntry> JournalEntries => Set<JournalEntry>();
    public DbSet<Payment> Payments => Set<Payment>();
    public DbSet<PurchaseBill> PurchaseBills => Set<PurchaseBill>();
    public DbSet<InventoryReceipt> InventoryReceipts => Set<InventoryReceipt>();
    public DbSet<PurchaseOrder> PurchaseOrders => Set<PurchaseOrder>();
    public DbSet<PurchaseReturn> PurchaseReturns => Set<PurchaseReturn>();
    public DbSet<SalesReturn> SalesReturns => Set<SalesReturn>();
    public DbSet<CompanySettings> CompanySettings => Set<CompanySettings>();
    public DbSet<DeviceSettings> DeviceSettings => Set<DeviceSettings>();
    public DbSet<DocumentSequenceCounter> DocumentSequenceCounters => Set<DocumentSequenceCounter>();
    public DbSet<Vendor> Vendors => Set<Vendor>();
    public DbSet<VendorCreditActivity> VendorCreditActivities => Set<VendorCreditActivity>();
    public DbSet<VendorPayment> VendorPayments => Set<VendorPayment>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        ConfigureAccounts(modelBuilder);
        ConfigureAccountingTransactions(modelBuilder);
        ConfigureCustomers(modelBuilder);
        ConfigureCustomerCredits(modelBuilder);
        ConfigureInventoryAdjustments(modelBuilder);
        ConfigureInvoices(modelBuilder);
        ConfigureItems(modelBuilder);
        ConfigureJournalEntries(modelBuilder);
        ConfigurePayments(modelBuilder);
        ConfigurePurchaseBills(modelBuilder);
        ConfigureInventoryReceipts(modelBuilder);
        ConfigurePurchaseOrders(modelBuilder);
        ConfigurePurchaseReturns(modelBuilder);
        ConfigureSalesReturns(modelBuilder);
        ConfigureSettings(modelBuilder);
        ConfigureDeviceSettings(modelBuilder);
        ConfigureDocumentSequenceCounters(modelBuilder);
        ConfigureVendors(modelBuilder);
        ConfigureVendorCredits(modelBuilder);
        ConfigureVendorPayments(modelBuilder);
    }

    private static void ConfigureAccounts(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Account>(entity =>
        {
            entity.ToTable("accounts");
            ConfigureEntityBase(entity);
            ConfigureTenant(entity);
            entity.Property(account => account.Code).HasMaxLength(20).IsRequired();
            entity.Property(account => account.Name).HasMaxLength(150).IsRequired();
            entity.Property(account => account.AccountType).HasConversion<int>().IsRequired();
            entity.Property(account => account.Description).HasMaxLength(500);
            entity.Property(account => account.IsActive).IsRequired();
            entity.HasIndex(account => account.Code).IsUnique();
            entity.HasIndex(account => account.Name).IsUnique();
        });
    }

    private static void ConfigureAccountingTransactions(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<AccountingTransaction>(entity =>
        {
            entity.ToTable("accounting_transactions");
            ConfigureEntityBase(entity);
            ConfigureTenant(entity);
            entity.Property(transaction => transaction.TransactionType).HasMaxLength(80).IsRequired();
            entity.Property(transaction => transaction.TransactionDate).IsRequired();
            entity.Property(transaction => transaction.ReferenceNumber).HasMaxLength(80).IsRequired();
            entity.Property(transaction => transaction.SourceEntityType).HasMaxLength(80);
            entity.Property(transaction => transaction.SourceEntityId);
            entity.Property(transaction => transaction.Status).HasConversion<int>().IsRequired();
            entity.Ignore(transaction => transaction.TotalDebit);
            entity.Ignore(transaction => transaction.TotalCredit);
            entity.HasIndex(transaction => transaction.ReferenceNumber);
            entity.HasIndex(transaction => new { transaction.SourceEntityType, transaction.SourceEntityId });

            entity.OwnsMany(transaction => transaction.Lines, line =>
            {
                line.ToTable("accounting_transaction_lines");
                line.WithOwner().HasForeignKey("AccountingTransactionId");
                line.HasKey(current => current.Id);
                line.Property(current => current.Description).HasMaxLength(300).IsRequired();
                ConfigureMoney(line.Property(current => current.Debit));
                ConfigureMoney(line.Property(current => current.Credit));
                line.HasIndex(current => current.AccountId);
            });

            entity.Navigation(transaction => transaction.Lines).UsePropertyAccessMode(PropertyAccessMode.Field);
        });
    }

    private static void ConfigureCustomers(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Customer>(entity =>
        {
            entity.ToTable("customers");
            ConfigureEntityBase(entity);
            ConfigureTenant(entity);
            entity.Property(customer => customer.DisplayName).HasMaxLength(200).IsRequired();
            entity.Property(customer => customer.CompanyName).HasMaxLength(200);
            entity.Property(customer => customer.Email).HasMaxLength(250);
            entity.Property(customer => customer.Phone).HasMaxLength(50);
            entity.Property(customer => customer.Currency).HasMaxLength(10).IsRequired();
            ConfigureMoney(entity.Property(customer => customer.Balance));
            ConfigureMoney(entity.Property(customer => customer.CreditBalance));
            entity.Property(customer => customer.IsActive).IsRequired();
            entity.HasIndex(customer => customer.DisplayName).IsUnique();
            entity.HasIndex(customer => customer.Email).IsUnique();
        });
    }

    private static void ConfigureCustomerCredits(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<CustomerCreditActivity>(entity =>
        {
            entity.ToTable("customer_credit_activities");
            ConfigureEntityBase(entity);
            ConfigureTenant(entity);
            ConfigureSyncDocument(entity);
            entity.Property(activity => activity.CustomerId).IsRequired();
            entity.Property(activity => activity.ActivityDate).IsRequired();
            entity.Property(activity => activity.InvoiceId);
            entity.Property(activity => activity.RefundAccountId);
            entity.Property(activity => activity.Action).HasConversion<int>().IsRequired();
            entity.Property(activity => activity.PaymentMethod).HasMaxLength(50);
            entity.Property(activity => activity.ReferenceNumber).HasMaxLength(80).IsRequired();
            entity.Property(activity => activity.Status).HasConversion<int>().IsRequired();
            ConfigureMoney(entity.Property(activity => activity.Amount));
            entity.HasIndex(activity => activity.ReferenceNumber).IsUnique();
        });
    }

    private static void ConfigureInventoryAdjustments(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<InventoryAdjustment>(entity =>
        {
            entity.ToTable("inventory_adjustments");
            ConfigureEntityBase(entity);
            ConfigureTenant(entity);
            ConfigureSyncDocument(entity);
            entity.Property(adjustment => adjustment.ItemId).IsRequired();
            entity.Property(adjustment => adjustment.AdjustmentAccountId).IsRequired();
            entity.Property(adjustment => adjustment.AdjustmentDate).IsRequired();
            entity.Property(adjustment => adjustment.AdjustmentNumber).HasMaxLength(80).IsRequired();
            entity.Property(adjustment => adjustment.Reason).HasMaxLength(300).IsRequired();
            entity.Property(adjustment => adjustment.Status).HasConversion<int>().IsRequired();
            ConfigureMoney(entity.Property(adjustment => adjustment.QuantityChange));
            ConfigureMoney(entity.Property(adjustment => adjustment.UnitCost));
            entity.Ignore(adjustment => adjustment.TotalCost);
            entity.HasIndex(adjustment => adjustment.AdjustmentNumber).IsUnique();
        });
    }

    private static void ConfigureInvoices(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Invoice>(entity =>
        {
            entity.ToTable("invoices");
            ConfigureEntityBase(entity);
            ConfigureTenant(entity);
            ConfigureSyncDocument(entity);
            entity.Property(invoice => invoice.CustomerId).IsRequired();
            entity.Property(invoice => invoice.InvoiceDate).IsRequired();
            entity.Property(invoice => invoice.DueDate).IsRequired();
            entity.Property(invoice => invoice.DepositAccountId);
            entity.Property(invoice => invoice.ReceiptPaymentId);
            entity.Property(invoice => invoice.PostedTransactionId);
            entity.Property(invoice => invoice.ReversalTransactionId);
            entity.Property(invoice => invoice.InvoiceNumber).HasMaxLength(80).IsRequired();
            entity.Property(invoice => invoice.PaymentMode).HasConversion<int>().IsRequired();
            entity.Property(invoice => invoice.PaymentMethod).HasMaxLength(50);
            entity.Property(invoice => invoice.Status).HasConversion<int>().IsRequired();
            ConfigureMoney(entity.Property(invoice => invoice.TaxAmount));
            ConfigureMoney(entity.Property(invoice => invoice.PaidAmount));
            ConfigureMoney(entity.Property(invoice => invoice.CreditAppliedAmount));
            ConfigureMoney(entity.Property(invoice => invoice.ReturnedAmount));
            entity.Ignore(invoice => invoice.Subtotal);
            entity.Ignore(invoice => invoice.DiscountAmount);
            entity.Ignore(invoice => invoice.TotalAmount);
            entity.Ignore(invoice => invoice.BalanceDue);
            entity.HasIndex(invoice => invoice.InvoiceNumber).IsUnique();

            entity.OwnsMany(invoice => invoice.Lines, line =>
            {
                line.ToTable("invoice_lines");
                line.WithOwner().HasForeignKey("InvoiceId");
                line.HasKey(current => current.Id);
                line.Property(current => current.ItemId).IsRequired();
                line.Property(current => current.Description).HasMaxLength(300).IsRequired();
                ConfigureMoney(line.Property(current => current.Quantity));
                ConfigureMoney(line.Property(current => current.UnitPrice));
                ConfigureMoney(line.Property(current => current.DiscountPercent));
                line.Ignore(current => current.GrossAmount);
                line.Ignore(current => current.DiscountAmount);
                line.Ignore(current => current.LineTotal);
            });

            entity.Navigation(invoice => invoice.Lines).UsePropertyAccessMode(PropertyAccessMode.Field);
        });
    }

    private static void ConfigureItems(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Item>(entity =>
        {
            entity.ToTable("items");
            ConfigureEntityBase(entity);
            ConfigureTenant(entity);
            entity.Property(item => item.Name).HasMaxLength(200).IsRequired();
            entity.Property(item => item.ItemType).HasConversion<int>().IsRequired();
            entity.Property(item => item.Sku).HasMaxLength(80);
            entity.Property(item => item.Barcode).HasMaxLength(100);
            entity.Property(item => item.Unit).HasMaxLength(20).IsRequired();
            ConfigureMoney(entity.Property(item => item.SalesPrice));
            ConfigureMoney(entity.Property(item => item.PurchasePrice));
            ConfigureMoney(entity.Property(item => item.QuantityOnHand));
            entity.Property(item => item.IsActive).IsRequired();
            entity.HasIndex(item => item.Name).IsUnique();
            entity.HasIndex(item => item.Sku).IsUnique();
            entity.HasIndex(item => item.Barcode).IsUnique();
        });
    }

    private static void ConfigureJournalEntries(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<JournalEntry>(entity =>
        {
            entity.ToTable("journal_entries");
            ConfigureEntityBase(entity);
            ConfigureTenant(entity);
            ConfigureSyncDocument(entity);
            entity.Property(entry => entry.EntryDate).IsRequired();
            entity.Property(entry => entry.PostedTransactionId);
            entity.Property(entry => entry.ReversalTransactionId);
            entity.Property(entry => entry.EntryNumber).HasMaxLength(80).IsRequired();
            entity.Property(entry => entry.Memo).HasMaxLength(500).IsRequired();
            entity.Property(entry => entry.Status).HasConversion<int>().IsRequired();
            entity.Ignore(entry => entry.TotalDebit);
            entity.Ignore(entry => entry.TotalCredit);
            entity.HasIndex(entry => entry.EntryNumber).IsUnique();

            entity.OwnsMany(entry => entry.Lines, line =>
            {
                line.ToTable("journal_entry_lines");
                line.WithOwner().HasForeignKey("JournalEntryId");
                line.HasKey(current => current.Id);
                line.Property(current => current.AccountId).IsRequired();
                line.Property(current => current.Description).HasMaxLength(300).IsRequired();
                ConfigureMoney(line.Property(current => current.Debit));
                ConfigureMoney(line.Property(current => current.Credit));
            });

            entity.Navigation(entry => entry.Lines).UsePropertyAccessMode(PropertyAccessMode.Field);
        });
    }

    private static void ConfigurePayments(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Payment>(entity =>
        {
            entity.ToTable("payments");
            ConfigureEntityBase(entity);
            ConfigureTenant(entity);
            ConfigureSyncDocument(entity);
            entity.Property(payment => payment.CustomerId).IsRequired();
            entity.Property(payment => payment.InvoiceId).IsRequired();
            entity.Property(payment => payment.DepositAccountId).IsRequired();
            entity.Property(payment => payment.PaymentDate).IsRequired();
            entity.Property(payment => payment.PostedTransactionId);
            entity.Property(payment => payment.ReversalTransactionId);
            entity.Property(payment => payment.PaymentMethod).HasMaxLength(50).IsRequired();
            entity.Property(payment => payment.PaymentNumber).HasMaxLength(80).IsRequired();
            entity.Property(payment => payment.Status).HasConversion<int>().IsRequired();
            ConfigureMoney(entity.Property(payment => payment.Amount));
            entity.HasIndex(payment => payment.PaymentNumber).IsUnique();
        });
    }

    private static void ConfigurePurchaseBills(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<PurchaseBill>(entity =>
        {
            entity.ToTable("purchase_bills");
            ConfigureEntityBase(entity);
            ConfigureTenant(entity);
            ConfigureSyncDocument(entity);
            entity.Property(bill => bill.VendorId).IsRequired();
            entity.Property(bill => bill.InventoryReceiptId);
            entity.Property(bill => bill.BillDate).IsRequired();
            entity.Property(bill => bill.DueDate).IsRequired();
            entity.Property(bill => bill.PostedTransactionId);
            entity.Property(bill => bill.ReversalTransactionId);
            entity.Property(bill => bill.BillNumber).HasMaxLength(80).IsRequired();
            entity.Property(bill => bill.Status).HasConversion<int>().IsRequired();
            ConfigureMoney(entity.Property(bill => bill.PaidAmount));
            ConfigureMoney(entity.Property(bill => bill.CreditAppliedAmount));
            ConfigureMoney(entity.Property(bill => bill.ReturnedAmount));
            entity.Ignore(bill => bill.TotalAmount);
            entity.Ignore(bill => bill.BalanceDue);
            entity.HasIndex(bill => bill.BillNumber).IsUnique();

            entity.OwnsMany(bill => bill.Lines, line =>
            {
                line.ToTable("purchase_bill_lines");
                line.WithOwner().HasForeignKey("PurchaseBillId");
                line.HasKey(current => current.Id);
                line.Property(current => current.ItemId).IsRequired();
                line.Property(current => current.InventoryReceiptLineId);
                line.Property(current => current.Description).HasMaxLength(300).IsRequired();
                ConfigureMoney(line.Property(current => current.Quantity));
                ConfigureMoney(line.Property(current => current.UnitCost));
                line.Ignore(current => current.LineTotal);
            });

            entity.Navigation(bill => bill.Lines).UsePropertyAccessMode(PropertyAccessMode.Field);
        });
    }

    private static void ConfigureInventoryReceipts(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<InventoryReceipt>(entity =>
        {
            entity.ToTable("inventory_receipts");
            ConfigureEntityBase(entity);
            ConfigureTenant(entity);
            ConfigureSyncDocument(entity);
            entity.Property(receipt => receipt.VendorId).IsRequired();
            entity.Property(receipt => receipt.PurchaseOrderId);
            entity.Property(receipt => receipt.ReceiptDate).IsRequired();
            entity.Property(receipt => receipt.PostedTransactionId);
            entity.Property(receipt => receipt.ReversalTransactionId);
            entity.Property(receipt => receipt.ReceiptNumber).HasMaxLength(80).IsRequired();
            entity.Property(receipt => receipt.Status).HasConversion<int>().IsRequired();
            entity.Ignore(receipt => receipt.TotalAmount);
            entity.HasIndex(receipt => receipt.ReceiptNumber).IsUnique();

            entity.OwnsMany(receipt => receipt.Lines, line =>
            {
                line.ToTable("inventory_receipt_lines");
                line.WithOwner().HasForeignKey("InventoryReceiptId");
                line.HasKey(current => current.Id);
                line.Property(current => current.ItemId).IsRequired();
                line.Property(current => current.PurchaseOrderLineId);
                line.Property(current => current.Description).HasMaxLength(300).IsRequired();
                ConfigureMoney(line.Property(current => current.Quantity));
                ConfigureMoney(line.Property(current => current.UnitCost));
                line.Ignore(current => current.LineTotal);
            });

            entity.Navigation(receipt => receipt.Lines).UsePropertyAccessMode(PropertyAccessMode.Field);
        });
    }

    private static void ConfigurePurchaseOrders(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<PurchaseOrder>(entity =>
        {
            entity.ToTable("purchase_orders");
            ConfigureEntityBase(entity);
            ConfigureTenant(entity);
            ConfigureSyncDocument(entity);
            entity.Property(order => order.VendorId).IsRequired();
            entity.Property(order => order.OrderDate).IsRequired();
            entity.Property(order => order.ExpectedDate).IsRequired();
            entity.Property(order => order.OrderNumber).HasMaxLength(80).IsRequired();
            entity.Property(order => order.Status).HasConversion<int>().IsRequired();
            entity.Ignore(order => order.TotalAmount);
            entity.HasIndex(order => order.OrderNumber).IsUnique();

            entity.OwnsMany(order => order.Lines, line =>
            {
                line.ToTable("purchase_order_lines");
                line.WithOwner().HasForeignKey("PurchaseOrderId");
                line.HasKey(current => current.Id);
                line.Property(current => current.ItemId).IsRequired();
                line.Property(current => current.Description).HasMaxLength(300).IsRequired();
                ConfigureMoney(line.Property(current => current.Quantity));
                ConfigureMoney(line.Property(current => current.UnitCost));
                line.Ignore(current => current.LineTotal);
            });

            entity.Navigation(order => order.Lines).UsePropertyAccessMode(PropertyAccessMode.Field);
        });
    }

    private static void ConfigurePurchaseReturns(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<PurchaseReturn>(entity =>
        {
            entity.ToTable("purchase_returns");
            ConfigureEntityBase(entity);
            ConfigureTenant(entity);
            ConfigureSyncDocument(entity);
            entity.Property(purchaseReturn => purchaseReturn.PurchaseBillId).IsRequired();
            entity.Property(purchaseReturn => purchaseReturn.VendorId).IsRequired();
            entity.Property(purchaseReturn => purchaseReturn.ReturnDate).IsRequired();
            entity.Property(purchaseReturn => purchaseReturn.PostedTransactionId);
            entity.Property(purchaseReturn => purchaseReturn.ReversalTransactionId);
            entity.Property(purchaseReturn => purchaseReturn.ReturnNumber).HasMaxLength(80).IsRequired();
            entity.Property(purchaseReturn => purchaseReturn.Status).HasConversion<int>().IsRequired();
            entity.Ignore(purchaseReturn => purchaseReturn.TotalAmount);
            entity.HasIndex(purchaseReturn => purchaseReturn.ReturnNumber).IsUnique();

            entity.OwnsMany(purchaseReturn => purchaseReturn.Lines, line =>
            {
                line.ToTable("purchase_return_lines");
                line.WithOwner().HasForeignKey("PurchaseReturnId");
                line.HasKey(current => current.Id);
                line.Property(current => current.PurchaseBillLineId).IsRequired();
                line.Property(current => current.ItemId).IsRequired();
                line.Property(current => current.Description).HasMaxLength(300).IsRequired();
                ConfigureMoney(line.Property(current => current.Quantity));
                ConfigureMoney(line.Property(current => current.UnitCost));
                line.Ignore(current => current.LineTotal);
            });

            entity.Navigation(purchaseReturn => purchaseReturn.Lines).UsePropertyAccessMode(PropertyAccessMode.Field);
        });
    }

    private static void ConfigureSalesReturns(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<SalesReturn>(entity =>
        {
            entity.ToTable("sales_returns");
            ConfigureEntityBase(entity);
            ConfigureTenant(entity);
            ConfigureSyncDocument(entity);
            entity.Property(salesReturn => salesReturn.InvoiceId).IsRequired();
            entity.Property(salesReturn => salesReturn.CustomerId).IsRequired();
            entity.Property(salesReturn => salesReturn.ReturnDate).IsRequired();
            entity.Property(salesReturn => salesReturn.PostedTransactionId);
            entity.Property(salesReturn => salesReturn.ReversalTransactionId);
            entity.Property(salesReturn => salesReturn.ReturnNumber).HasMaxLength(80).IsRequired();
            entity.Property(salesReturn => salesReturn.Status).HasConversion<int>().IsRequired();
            entity.Ignore(salesReturn => salesReturn.TotalAmount);
            entity.HasIndex(salesReturn => salesReturn.ReturnNumber).IsUnique();

            entity.OwnsMany(salesReturn => salesReturn.Lines, line =>
            {
                line.ToTable("sales_return_lines");
                line.WithOwner().HasForeignKey("SalesReturnId");
                line.HasKey(current => current.Id);
                line.Property(current => current.InvoiceLineId).IsRequired();
                line.Property(current => current.ItemId).IsRequired();
                line.Property(current => current.Description).HasMaxLength(300).IsRequired();
                ConfigureMoney(line.Property(current => current.Quantity));
                ConfigureMoney(line.Property(current => current.UnitPrice));
                ConfigureMoney(line.Property(current => current.DiscountPercent));
                line.Ignore(current => current.GrossAmount);
                line.Ignore(current => current.DiscountAmount);
                line.Ignore(current => current.LineTotal);
            });

            entity.Navigation(salesReturn => salesReturn.Lines).UsePropertyAccessMode(PropertyAccessMode.Field);
        });
    }

    private static void ConfigureVendors(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Vendor>(entity =>
        {
            entity.ToTable("vendors");
            ConfigureEntityBase(entity);
            ConfigureTenant(entity);
            entity.Property(vendor => vendor.DisplayName).HasMaxLength(200).IsRequired();
            entity.Property(vendor => vendor.CompanyName).HasMaxLength(200);
            entity.Property(vendor => vendor.Email).HasMaxLength(250);
            entity.Property(vendor => vendor.Phone).HasMaxLength(50);
            entity.Property(vendor => vendor.Currency).HasMaxLength(10).IsRequired();
            ConfigureMoney(entity.Property(vendor => vendor.Balance));
            ConfigureMoney(entity.Property(vendor => vendor.CreditBalance));
            entity.Property(vendor => vendor.IsActive).IsRequired();
            entity.HasIndex(vendor => vendor.DisplayName).IsUnique();
            entity.HasIndex(vendor => vendor.Email).IsUnique();
        });
    }

    private static void ConfigureSettings(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<CompanySettings>(entity =>
        {
            entity.ToTable("company_settings");
            ConfigureEntityBase(entity);
            ConfigureTenant(entity);
            entity.Property(settings => settings.CompanyName).HasMaxLength(200).IsRequired();
            entity.Property(settings => settings.LegalName).HasMaxLength(200);
            entity.Property(settings => settings.Email).HasMaxLength(250);
            entity.Property(settings => settings.Phone).HasMaxLength(50);
            entity.Property(settings => settings.Currency).HasMaxLength(10).IsRequired();
            entity.Property(settings => settings.Country).HasMaxLength(120).IsRequired();
            entity.Property(settings => settings.TimeZoneId).HasMaxLength(120).IsRequired();
            entity.Property(settings => settings.DefaultLanguage).HasMaxLength(10).IsRequired();
            entity.Property(settings => settings.TaxRegistrationNumber).HasMaxLength(100);
            entity.Property(settings => settings.AddressLine1).HasMaxLength(200);
            entity.Property(settings => settings.AddressLine2).HasMaxLength(200);
            entity.Property(settings => settings.City).HasMaxLength(120);
            entity.Property(settings => settings.Region).HasMaxLength(120);
            entity.Property(settings => settings.PostalCode).HasMaxLength(40);
            entity.Property(settings => settings.FiscalYearStartMonth).IsRequired();
            entity.Property(settings => settings.FiscalYearStartDay).IsRequired();
            ConfigureMoney(entity.Property(settings => settings.DefaultSalesTaxRate));
            ConfigureMoney(entity.Property(settings => settings.DefaultPurchaseTaxRate));
            entity.HasIndex(settings => settings.CompanyId).IsUnique();
        });
    }

    private static void ConfigureDeviceSettings(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<DeviceSettings>(entity =>
        {
            entity.ToTable("device_settings");
            ConfigureEntityBase(entity);
            entity.Property(settings => settings.DeviceId).HasMaxLength(20).IsRequired();
            entity.Property(settings => settings.DeviceName).HasMaxLength(120).IsRequired();
            entity.HasIndex(settings => settings.DeviceId).IsUnique();
        });
    }

    private static void ConfigureDocumentSequenceCounters(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<DocumentSequenceCounter>(entity =>
        {
            entity.ToTable("document_sequence_counters");
            ConfigureEntityBase(entity);
            entity.Property(counter => counter.DeviceId).HasMaxLength(20).IsRequired();
            entity.Property(counter => counter.DocumentType).HasMaxLength(50).IsRequired();
            entity.Property(counter => counter.Year).IsRequired();
            entity.Property(counter => counter.NextSequence).IsRequired();
            entity.HasIndex(counter => new { counter.DeviceId, counter.DocumentType, counter.Year }).IsUnique();
        });
    }

    private static void ConfigureVendorCredits(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<VendorCreditActivity>(entity =>
        {
            entity.ToTable("vendor_credit_activities");
            ConfigureEntityBase(entity);
            ConfigureTenant(entity);
            ConfigureSyncDocument(entity);
            entity.Property(activity => activity.VendorId).IsRequired();
            entity.Property(activity => activity.ActivityDate).IsRequired();
            entity.Property(activity => activity.PurchaseBillId);
            entity.Property(activity => activity.DepositAccountId);
            entity.Property(activity => activity.Action).HasConversion<int>().IsRequired();
            entity.Property(activity => activity.PaymentMethod).HasMaxLength(50);
            entity.Property(activity => activity.ReferenceNumber).HasMaxLength(80).IsRequired();
            entity.Property(activity => activity.Status).HasConversion<int>().IsRequired();
            ConfigureMoney(entity.Property(activity => activity.Amount));
            entity.HasIndex(activity => activity.ReferenceNumber).IsUnique();
        });
    }

    private static void ConfigureVendorPayments(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<VendorPayment>(entity =>
        {
            entity.ToTable("vendor_payments");
            ConfigureEntityBase(entity);
            ConfigureTenant(entity);
            ConfigureSyncDocument(entity);
            entity.Property(payment => payment.VendorId).IsRequired();
            entity.Property(payment => payment.PurchaseBillId).IsRequired();
            entity.Property(payment => payment.PaymentAccountId).IsRequired();
            entity.Property(payment => payment.PaymentDate).IsRequired();
            entity.Property(payment => payment.PostedTransactionId);
            entity.Property(payment => payment.ReversalTransactionId);
            entity.Property(payment => payment.PaymentMethod).HasMaxLength(50).IsRequired();
            entity.Property(payment => payment.PaymentNumber).HasMaxLength(80).IsRequired();
            entity.Property(payment => payment.Status).HasConversion<int>().IsRequired();
            ConfigureMoney(entity.Property(payment => payment.Amount));
            entity.HasIndex(payment => payment.PaymentNumber).IsUnique();
        });
    }

    private static void ConfigureEntityBase<TEntity>(Microsoft.EntityFrameworkCore.Metadata.Builders.EntityTypeBuilder<TEntity> entity)
        where TEntity : class
    {
        entity.HasKey("Id");
        entity.Property<Guid>("Id").ValueGeneratedNever();
        entity.Property<DateTimeOffset>("CreatedAt").IsRequired();
        entity.Property<DateTimeOffset?>("UpdatedAt");
    }

    private static void ConfigureTenant<TEntity>(Microsoft.EntityFrameworkCore.Metadata.Builders.EntityTypeBuilder<TEntity> entity)
        where TEntity : class
    {
        entity.Property<Guid>("CompanyId").IsRequired();
        entity.HasIndex("CompanyId");
    }

    private static void ConfigureSyncDocument<TEntity>(Microsoft.EntityFrameworkCore.Metadata.Builders.EntityTypeBuilder<TEntity> entity)
        where TEntity : SyncDocumentBase
    {
        entity.Property(document => document.DeviceId).HasMaxLength(20).IsRequired();
        entity.Property(document => document.DocumentNo).HasMaxLength(80).IsRequired();
        entity.Property(document => document.SyncStatus).HasConversion<int>().IsRequired();
        entity.Property(document => document.LastSyncAt);
        entity.Property(document => document.SyncError).HasMaxLength(500);
        entity.HasIndex(document => document.DocumentNo).IsUnique();
        entity.HasIndex(document => document.DeviceId);
        entity.HasIndex(document => document.SyncStatus);
    }

    private static void ConfigureMoney(Microsoft.EntityFrameworkCore.Metadata.Builders.PropertyBuilder<decimal> property)
    {
        property.HasPrecision(18, 4);
    }
}
