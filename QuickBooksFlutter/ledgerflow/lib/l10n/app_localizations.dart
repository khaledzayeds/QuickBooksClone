import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// اسم التطبيق
  ///
  /// In ar, this message translates to:
  /// **'LedgerFlow'**
  String get appName;

  /// No description provided for @dashboard.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get dashboard;

  /// No description provided for @all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get all;

  /// No description provided for @sales.
  ///
  /// In ar, this message translates to:
  /// **'المبيعات'**
  String get sales;

  /// No description provided for @estimates.
  ///
  /// In ar, this message translates to:
  /// **'عروض الأسعار'**
  String get estimates;

  /// No description provided for @salesOrders.
  ///
  /// In ar, this message translates to:
  /// **'أوامر البيع'**
  String get salesOrders;

  /// No description provided for @invoices.
  ///
  /// In ar, this message translates to:
  /// **'الفواتير'**
  String get invoices;

  /// No description provided for @payments.
  ///
  /// In ar, this message translates to:
  /// **'المدفوعات'**
  String get payments;

  /// No description provided for @purchases.
  ///
  /// In ar, this message translates to:
  /// **'المشتريات'**
  String get purchases;

  /// No description provided for @purchaseOrders.
  ///
  /// In ar, this message translates to:
  /// **'أوامر الشراء'**
  String get purchaseOrders;

  /// No description provided for @receiveInventory.
  ///
  /// In ar, this message translates to:
  /// **'استلام المخزون'**
  String get receiveInventory;

  /// No description provided for @purchaseBills.
  ///
  /// In ar, this message translates to:
  /// **'فواتير الشراء'**
  String get purchaseBills;

  /// No description provided for @vendorPayments.
  ///
  /// In ar, this message translates to:
  /// **'مدفوعات الموردين'**
  String get vendorPayments;

  /// No description provided for @masterData.
  ///
  /// In ar, this message translates to:
  /// **'البيانات الأساسية'**
  String get masterData;

  /// No description provided for @customers.
  ///
  /// In ar, this message translates to:
  /// **'العملاء'**
  String get customers;

  /// No description provided for @vendors.
  ///
  /// In ar, this message translates to:
  /// **'الموردون'**
  String get vendors;

  /// No description provided for @items.
  ///
  /// In ar, this message translates to:
  /// **'الأصناف'**
  String get items;

  /// No description provided for @chartOfAccounts.
  ///
  /// In ar, this message translates to:
  /// **'دليل الحسابات'**
  String get chartOfAccounts;

  /// No description provided for @reportsAndSettings.
  ///
  /// In ar, this message translates to:
  /// **'التقارير والإعدادات'**
  String get reportsAndSettings;

  /// No description provided for @reports.
  ///
  /// In ar, this message translates to:
  /// **'التقارير'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @search.
  ///
  /// In ar, this message translates to:
  /// **'بحث...'**
  String get search;

  /// No description provided for @pageNotFound.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة غير موجودة'**
  String get pageNotFound;

  /// No description provided for @backToHome.
  ///
  /// In ar, this message translates to:
  /// **'العودة للرئيسية'**
  String get backToHome;

  /// No description provided for @underDevelopment.
  ///
  /// In ar, this message translates to:
  /// **'قيد التطوير...'**
  String get underDevelopment;

  /// No description provided for @newText.
  ///
  /// In ar, this message translates to:
  /// **'جديد'**
  String get newText;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @moneyBarUnpaid.
  ///
  /// In ar, this message translates to:
  /// **'فواتير غير مدفوعة'**
  String get moneyBarUnpaid;

  /// No description provided for @moneyBarOverdue.
  ///
  /// In ar, this message translates to:
  /// **'فواتير متأخرة'**
  String get moneyBarOverdue;

  /// No description provided for @moneyBarPaid.
  ///
  /// In ar, this message translates to:
  /// **'مقبوضات (آخر 30 يوم)'**
  String get moneyBarPaid;

  /// No description provided for @moneyBarExpenses.
  ///
  /// In ar, this message translates to:
  /// **'مصروفات'**
  String get moneyBarExpenses;

  /// No description provided for @profitAndLoss.
  ///
  /// In ar, this message translates to:
  /// **'الأرباح والخسائر'**
  String get profitAndLoss;

  /// No description provided for @expensesByCategory.
  ///
  /// In ar, this message translates to:
  /// **'المصروفات حسب الفئة'**
  String get expensesByCategory;

  /// No description provided for @bankAccounts.
  ///
  /// In ar, this message translates to:
  /// **'الحسابات البنكية'**
  String get bankAccounts;

  /// No description provided for @income.
  ///
  /// In ar, this message translates to:
  /// **'دخل'**
  String get income;

  /// No description provided for @newPurchaseOrder.
  ///
  /// In ar, this message translates to:
  /// **'أمر شراء جديد'**
  String get newPurchaseOrder;

  /// No description provided for @saveDraft.
  ///
  /// In ar, this message translates to:
  /// **'حفظ مسودة'**
  String get saveDraft;

  /// No description provided for @saveAndOpen.
  ///
  /// In ar, this message translates to:
  /// **'حفظ وفتح'**
  String get saveAndOpen;

  /// No description provided for @clear.
  ///
  /// In ar, this message translates to:
  /// **'مسح'**
  String get clear;

  /// No description provided for @vendor.
  ///
  /// In ar, this message translates to:
  /// **'المورد'**
  String get vendor;

  /// No description provided for @poDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الأمر'**
  String get poDate;

  /// No description provided for @expectedDate.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ المتوقع'**
  String get expectedDate;

  /// No description provided for @itemService.
  ///
  /// In ar, this message translates to:
  /// **'الصنف / الخدمة'**
  String get itemService;

  /// No description provided for @description.
  ///
  /// In ar, this message translates to:
  /// **'الوصف'**
  String get description;

  /// No description provided for @qty.
  ///
  /// In ar, this message translates to:
  /// **'الكمية'**
  String get qty;

  /// No description provided for @rate.
  ///
  /// In ar, this message translates to:
  /// **'السعر'**
  String get rate;

  /// No description provided for @amount.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get amount;

  /// No description provided for @totalAmount.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي الكلي'**
  String get totalAmount;

  /// No description provided for @memoInternal.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات داخلية'**
  String get memoInternal;

  /// No description provided for @addLine.
  ///
  /// In ar, this message translates to:
  /// **'إضافة سطر'**
  String get addLine;

  /// No description provided for @selectItem.
  ///
  /// In ar, this message translates to:
  /// **'اختر صنفاً...'**
  String get selectItem;

  /// No description provided for @selectVendor.
  ///
  /// In ar, this message translates to:
  /// **'اختر مورداً...'**
  String get selectVendor;

  /// No description provided for @poCreatedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ أمر الشراء بنجاح'**
  String get poCreatedSuccess;

  /// No description provided for @poSavedAsDraft.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ المسودة بنجاح'**
  String get poSavedAsDraft;

  /// No description provided for @poSavedAsOpen.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ وفتح أمر الشراء بنجاح'**
  String get poSavedAsOpen;

  /// No description provided for @orderDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الأمر'**
  String get orderDetails;

  /// No description provided for @openOrder.
  ///
  /// In ar, this message translates to:
  /// **'فتح الأمر'**
  String get openOrder;

  /// No description provided for @closeOrder.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق الأمر'**
  String get closeOrder;

  /// No description provided for @cancelOrder.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الأمر'**
  String get cancelOrder;

  /// No description provided for @receiveInventoryAction.
  ///
  /// In ar, this message translates to:
  /// **'استلام مخزون'**
  String get receiveInventoryAction;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @confirmCancelPO.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من إلغاء أمر الشراء؟'**
  String get confirmCancelPO;

  /// No description provided for @poOpenedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم فتح الأمر بنجاح'**
  String get poOpenedSuccess;

  /// No description provided for @poClosedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إغلاق الأمر بنجاح'**
  String get poClosedSuccess;

  /// No description provided for @poCancelledSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء الأمر بنجاح'**
  String get poCancelledSuccess;

  /// No description provided for @subtotal.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ الفرعي'**
  String get subtotal;

  /// No description provided for @tax.
  ///
  /// In ar, this message translates to:
  /// **'الضريبة'**
  String get tax;

  /// No description provided for @total.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get total;

  /// No description provided for @statusDraft.
  ///
  /// In ar, this message translates to:
  /// **'مسودة'**
  String get statusDraft;

  /// No description provided for @statusOpen.
  ///
  /// In ar, this message translates to:
  /// **'مفتوح'**
  String get statusOpen;

  /// No description provided for @statusClosed.
  ///
  /// In ar, this message translates to:
  /// **'مغلق'**
  String get statusClosed;

  /// No description provided for @statusCancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغي'**
  String get statusCancelled;

  /// No description provided for @inventoryReceipts.
  ///
  /// In ar, this message translates to:
  /// **'سندات الاستلام'**
  String get inventoryReceipts;

  /// No description provided for @newReceipt.
  ///
  /// In ar, this message translates to:
  /// **'استلام جديد'**
  String get newReceipt;

  /// No description provided for @noInventoryReceipts.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد سندات استلام'**
  String get noInventoryReceipts;

  /// No description provided for @startReceivingFromPO.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ باستلام مخزون من أمر شراء مفتوح'**
  String get startReceivingFromPO;

  /// No description provided for @receipt.
  ///
  /// In ar, this message translates to:
  /// **'سند استلام'**
  String get receipt;

  /// No description provided for @currentBalance.
  ///
  /// In ar, this message translates to:
  /// **'الرصيد الحالي'**
  String get currentBalance;

  /// No description provided for @email.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In ar, this message translates to:
  /// **'الهاتف'**
  String get phone;

  /// No description provided for @viewVendorProfile.
  ///
  /// In ar, this message translates to:
  /// **'عرض ملف المورد'**
  String get viewVendorProfile;

  /// No description provided for @egp.
  ///
  /// In ar, this message translates to:
  /// **'ج.م'**
  String get egp;

  /// No description provided for @openPO.
  ///
  /// In ar, this message translates to:
  /// **'أمر الشراء المفتوح'**
  String get openPO;

  /// No description provided for @receiptDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الاستلام'**
  String get receiptDate;

  /// No description provided for @notes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات'**
  String get notes;

  /// No description provided for @saving.
  ///
  /// In ar, this message translates to:
  /// **'جاري الحفظ...'**
  String get saving;

  /// No description provided for @saveReceipt.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الاستلام'**
  String get saveReceipt;

  /// No description provided for @ordered.
  ///
  /// In ar, this message translates to:
  /// **'مطلوب'**
  String get ordered;

  /// No description provided for @qtyToReceive.
  ///
  /// In ar, this message translates to:
  /// **'كمية الاستلام'**
  String get qtyToReceive;

  /// No description provided for @riSavedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل استلام المخزون بنجاح'**
  String get riSavedSuccess;

  /// No description provided for @selectOpenPO.
  ///
  /// In ar, this message translates to:
  /// **'اختر أمر شراء مفتوح أولاً'**
  String get selectOpenPO;

  /// No description provided for @minOneQty.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كمية استلام واحدة على الأقل'**
  String get minOneQty;

  /// No description provided for @selectOpenPOHint.
  ///
  /// In ar, this message translates to:
  /// **'اختر أمر شراء مفتوح لعرض الكميات'**
  String get selectOpenPOHint;

  /// No description provided for @from.
  ///
  /// In ar, this message translates to:
  /// **'من'**
  String get from;

  /// No description provided for @receivedItems.
  ///
  /// In ar, this message translates to:
  /// **'الأصناف المستلمة'**
  String get receivedItems;

  /// No description provided for @received.
  ///
  /// In ar, this message translates to:
  /// **'مستلم'**
  String get received;

  /// No description provided for @homePage.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة الرئيسية'**
  String get homePage;

  /// No description provided for @insights.
  ///
  /// In ar, this message translates to:
  /// **'رؤى البيانات'**
  String get insights;

  /// No description provided for @enterBills.
  ///
  /// In ar, this message translates to:
  /// **'إدخال فواتير'**
  String get enterBills;

  /// No description provided for @payBills.
  ///
  /// In ar, this message translates to:
  /// **'سداد فواتير'**
  String get payBills;

  /// No description provided for @createInvoices.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء فواتير'**
  String get createInvoices;

  /// No description provided for @recordDeposits.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل إيداعات'**
  String get recordDeposits;

  /// No description provided for @enterTime.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الوقت'**
  String get enterTime;

  /// No description provided for @payEmployees.
  ///
  /// In ar, this message translates to:
  /// **'صرف الرواتب'**
  String get payEmployees;

  /// No description provided for @itemsAndServices.
  ///
  /// In ar, this message translates to:
  /// **'الأصناف والخدمات'**
  String get itemsAndServices;

  /// No description provided for @employees.
  ///
  /// In ar, this message translates to:
  /// **'الموظفون'**
  String get employees;

  /// No description provided for @company.
  ///
  /// In ar, this message translates to:
  /// **'الشركة'**
  String get company;

  /// No description provided for @fiscalYearToDate.
  ///
  /// In ar, this message translates to:
  /// **'هذه السنة المالية حتى تاريخه'**
  String get fiscalYearToDate;

  /// No description provided for @netIncome.
  ///
  /// In ar, this message translates to:
  /// **'صافي الدخل'**
  String get netIncome;

  /// No description provided for @unpaid.
  ///
  /// In ar, this message translates to:
  /// **'غير مدفوع'**
  String get unpaid;

  /// No description provided for @paid.
  ///
  /// In ar, this message translates to:
  /// **'مدفوع'**
  String get paid;

  /// No description provided for @createInvoice.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء فاتورة'**
  String get createInvoice;

  /// No description provided for @createBill.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء فاتورة شراء'**
  String get createBill;

  /// No description provided for @searchHelp.
  ///
  /// In ar, this message translates to:
  /// **'البحث في الشركة أو المساعدة'**
  String get searchHelp;

  /// No description provided for @myShortcuts.
  ///
  /// In ar, this message translates to:
  /// **'اختصاراتي'**
  String get myShortcuts;

  /// No description provided for @home.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get home;

  /// No description provided for @myCompany.
  ///
  /// In ar, this message translates to:
  /// **'شركتي'**
  String get myCompany;

  /// No description provided for @cashFlowHub.
  ///
  /// In ar, this message translates to:
  /// **'مركز التدفق النقدي'**
  String get cashFlowHub;

  /// No description provided for @incomeTracker.
  ///
  /// In ar, this message translates to:
  /// **'تتبع الدخل'**
  String get incomeTracker;

  /// No description provided for @billTracker.
  ///
  /// In ar, this message translates to:
  /// **'تتبع الفواتير'**
  String get billTracker;

  /// No description provided for @calendar.
  ///
  /// In ar, this message translates to:
  /// **'التقويم'**
  String get calendar;

  /// No description provided for @snapshots.
  ///
  /// In ar, this message translates to:
  /// **'لقطات سريعة'**
  String get snapshots;

  /// No description provided for @viewBalances.
  ///
  /// In ar, this message translates to:
  /// **'عرض الأرصدة'**
  String get viewBalances;

  /// No description provided for @runFavoriteReports.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل التقارير المفضلة'**
  String get runFavoriteReports;

  /// No description provided for @openWindows.
  ///
  /// In ar, this message translates to:
  /// **'النوافذ المفتوحة'**
  String get openWindows;

  /// No description provided for @stock.
  ///
  /// In ar, this message translates to:
  /// **'المخزون'**
  String get stock;

  /// No description provided for @vendorBalance.
  ///
  /// In ar, this message translates to:
  /// **'رصيد المورد'**
  String get vendorBalance;

  /// No description provided for @creditBalance.
  ///
  /// In ar, this message translates to:
  /// **'رصيد دائن'**
  String get creditBalance;

  /// No description provided for @recentTransactions.
  ///
  /// In ar, this message translates to:
  /// **'آخر المعاملات'**
  String get recentTransactions;

  /// No description provided for @openBills.
  ///
  /// In ar, this message translates to:
  /// **'الفواتير المفتوحة'**
  String get openBills;

  /// No description provided for @noRecentTransactions.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد معاملات حديثة'**
  String get noRecentTransactions;

  /// No description provided for @billDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الفاتورة'**
  String get billDate;

  /// No description provided for @dueDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الاستحقاق'**
  String get dueDate;

  /// No description provided for @amountPaid.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المدفوع'**
  String get amountPaid;

  /// No description provided for @amountDue.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المستحق'**
  String get amountDue;

  /// No description provided for @paymentDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الدفع'**
  String get paymentDate;

  /// No description provided for @paymentMethod.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الدفع'**
  String get paymentMethod;

  /// No description provided for @selectBillsToPay.
  ///
  /// In ar, this message translates to:
  /// **'اختر الفواتير للدفع'**
  String get selectBillsToPay;

  /// No description provided for @totalPayment.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الدفع'**
  String get totalPayment;

  /// No description provided for @billCreatedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل فاتورة المشتريات بنجاح'**
  String get billCreatedSuccess;

  /// No description provided for @paymentCreatedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل دفعة المورد بنجاح'**
  String get paymentCreatedSuccess;

  /// No description provided for @selectVendorHint.
  ///
  /// In ar, this message translates to:
  /// **'اختر مورداً لعرض التفاصيل'**
  String get selectVendorHint;

  /// No description provided for @linkToRI.
  ///
  /// In ar, this message translates to:
  /// **'ربط بإيصال استلام'**
  String get linkToRI;

  /// No description provided for @noPendingRI.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إيصالات استلام معلقة لهذا المورد'**
  String get noPendingRI;

  /// No description provided for @selectRI.
  ///
  /// In ar, this message translates to:
  /// **'اختر إيصالاً...'**
  String get selectRI;

  /// No description provided for @billStatus.
  ///
  /// In ar, this message translates to:
  /// **'حالة الفاتورة'**
  String get billStatus;

  /// No description provided for @statusPartiallyPaid.
  ///
  /// In ar, this message translates to:
  /// **'مدفوع جزئياً'**
  String get statusPartiallyPaid;

  /// No description provided for @statusPaid.
  ///
  /// In ar, this message translates to:
  /// **'مدفوع'**
  String get statusPaid;

  /// No description provided for @paymentAccount.
  ///
  /// In ar, this message translates to:
  /// **'حساب الدفع'**
  String get paymentAccount;

  /// No description provided for @paymentAccountHint.
  ///
  /// In ar, this message translates to:
  /// **'اختر حساباً بنكياً أو نقدياً'**
  String get paymentAccountHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
