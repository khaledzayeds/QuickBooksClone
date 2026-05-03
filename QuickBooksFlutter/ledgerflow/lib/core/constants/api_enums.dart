// api_enums.dart

// ─── Account Types ───────────────────────────────
enum AccountType {
  bank(1),
  accountsReceivable(2),
  otherCurrentAsset(3),
  inventoryAsset(4),
  fixedAsset(5),
  accountsPayable(6),
  creditCard(7),
  otherCurrentLiability(8),
  longTermLiability(9),
  equity(10),
  income(11),
  otherIncome(12),
  costOfGoodsSold(13),
  expense(14),
  otherExpense(15);

  const AccountType(this.value);
  final int value;

  static AccountType fromValue(int value) =>
      AccountType.values.firstWhere((e) => e.value == value);
}

// ─── Item Types ───────────────────────────────────
enum ItemType {
  inventory(1),
  nonInventory(2),
  service(3),
  bundle(4);

  const ItemType(this.value);
  final int value;

  static ItemType fromValue(int value) =>
      ItemType.values.firstWhere((e) => e.value == value);
}

// ─── Sync Status ──────────────────────────────────
enum SyncStatus {
  localOnly,
  pendingSync,
  synced,
  syncFailed;

  static SyncStatus fromString(String value) {
    switch (value) {
      case 'LocalOnly':    return SyncStatus.localOnly;
      case 'PendingSync':  return SyncStatus.pendingSync;
      case 'Synced':       return SyncStatus.synced;
      case 'SyncFailed':   return SyncStatus.syncFailed;
      default:             return SyncStatus.localOnly;
    }
  }
}

// ─── Document Save Mode ───────────────────────────
enum SaveMode {
  draft(1),
  saveAndPost(2);

  const SaveMode(this.value);
  final int value;
}

// ─── Invoice / Document Status ────────────────────
enum DocumentStatus {
  draft,
  sent,
  posted,
  partiallyPaid,
  paid,
  void_,
  closed,
  accepted,
  open;

  static DocumentStatus fromString(String value) {
    switch (value) {
      case 'Draft':         return DocumentStatus.draft;
      case 'Sent':          return DocumentStatus.sent;
      case 'Posted':        return DocumentStatus.posted;
      case 'PartiallyPaid': return DocumentStatus.partiallyPaid;
      case 'Paid':          return DocumentStatus.paid;
      case 'Void':          return DocumentStatus.void_;
      case 'Closed':        return DocumentStatus.closed;
      case 'Accepted':      return DocumentStatus.accepted;
      case 'Open':          return DocumentStatus.open;
      default:              return DocumentStatus.draft;
    }
  }
}

// ─── Payment Method ───────────────────────────────
enum PaymentMethod {
  cash,
  check,
  bankTransfer,
  creditCard;

  static PaymentMethod fromString(String value) {
    switch (value) {
      case 'Cash':         return PaymentMethod.cash;
      case 'Check':        return PaymentMethod.check;
      case 'BankTransfer': return PaymentMethod.bankTransfer;
      case 'CreditCard':   return PaymentMethod.creditCard;
      default:             return PaymentMethod.cash;
    }
  }

  String toApiString() {
    switch (this) {
      case PaymentMethod.cash:         return 'Cash';
      case PaymentMethod.check:        return 'Check';
      case PaymentMethod.bankTransfer: return 'BankTransfer';
      case PaymentMethod.creditCard:   return 'CreditCard';
    }
  }
}

// ─── Inventory Adjustment Reason ──────────────────
enum AdjustmentReason {
  shrinkage,
  damagedGoods,
  stockCount,
  theft,
  other;

  static AdjustmentReason fromString(String value) {
    switch (value) {
      case 'Shrinkage':    return AdjustmentReason.shrinkage;
      case 'DamagedGoods': return AdjustmentReason.damagedGoods;
      case 'StockCount':   return AdjustmentReason.stockCount;
      case 'Theft':        return AdjustmentReason.theft;
      default:             return AdjustmentReason.other;
    }
  }

  String toApiString() {
    switch (this) {
      case AdjustmentReason.shrinkage:    return 'Shrinkage';
      case AdjustmentReason.damagedGoods: return 'DamagedGoods';
      case AdjustmentReason.stockCount:   return 'StockCount';
      case AdjustmentReason.theft:        return 'Theft';
      case AdjustmentReason.other:        return 'Other';
    }
  }
}

// ─── Sync Document Type ───────────────────────────
enum SyncDocumentType {
  estimate,
  salesOrder,
  invoice,
  payment,
  purchaseOrder,
  inventoryReceipt,
  purchaseBill,
  vendorPayment,
  salesReturn,
  purchaseReturn,
  customerCredit,
  vendorCredit,
  journalEntry,
  inventoryAdjustment;

  String toApiString() {
    switch (this) {
      case SyncDocumentType.estimate:            return 'estimate';
      case SyncDocumentType.salesOrder:          return 'sales-order';
      case SyncDocumentType.invoice:             return 'invoice';
      case SyncDocumentType.payment:             return 'payment';
      case SyncDocumentType.purchaseOrder:       return 'purchase-order';
      case SyncDocumentType.inventoryReceipt:    return 'inventory-receipt';
      case SyncDocumentType.purchaseBill:        return 'purchase-bill';
      case SyncDocumentType.vendorPayment:       return 'vendor-payment';
      case SyncDocumentType.salesReturn:         return 'sales-return';
      case SyncDocumentType.purchaseReturn:      return 'purchase-return';
      case SyncDocumentType.customerCredit:      return 'customer-credit';
      case SyncDocumentType.vendorCredit:        return 'vendor-credit';
      case SyncDocumentType.journalEntry:        return 'journal-entry';
      case SyncDocumentType.inventoryAdjustment: return 'inventory-adjustment';
    }
  }
}

// ─── Vendor Credit Action ─────────────────────────
enum VendorCreditAction {
  applyToBill(1),
  refundReceipt(2);

  const VendorCreditAction(this.value);
  final int value;

  static VendorCreditAction fromValue(int value) =>
      VendorCreditAction.values.firstWhere((e) => e.value == value, orElse: () => VendorCreditAction.applyToBill);
}

// ─── Customer Credit Action ───────────────────────
enum CustomerCreditAction {
  applyToInvoice(1),
  refundReceipt(2);

  const CustomerCreditAction(this.value);
  final int value;

  static CustomerCreditAction fromValue(int value) =>
      CustomerCreditAction.values.firstWhere((e) => e.value == value, orElse: () => CustomerCreditAction.applyToInvoice);
}