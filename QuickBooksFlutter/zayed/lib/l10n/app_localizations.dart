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
  /// **'Zayed'**
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

  /// No description provided for @salesReceipt.
  ///
  /// In ar, this message translates to:
  /// **'إيصال بيع'**
  String get salesReceipt;

  /// No description provided for @newSalesReceipt.
  ///
  /// In ar, this message translates to:
  /// **'إيصال بيع جديد'**
  String get newSalesReceipt;

  /// No description provided for @salesReceiptDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل إيصال البيع'**
  String get salesReceiptDetails;

  /// No description provided for @createSalesReceipt.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء إيصال بيع'**
  String get createSalesReceipt;

  /// No description provided for @paidNowSale.
  ///
  /// In ar, this message translates to:
  /// **'بيع نقدي مباشر'**
  String get paidNowSale;

  /// No description provided for @creditSale.
  ///
  /// In ar, this message translates to:
  /// **'بيع آجل'**
  String get creditSale;

  /// No description provided for @receivePayments.
  ///
  /// In ar, this message translates to:
  /// **'تحصيل المدفوعات'**
  String get receivePayments;

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

  /// No description provided for @ok.
  ///
  /// In ar, this message translates to:
  /// **'موافق'**
  String get ok;

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

  /// No description provided for @selectCustomer.
  ///
  /// In ar, this message translates to:
  /// **'اختر عميلاً...'**
  String get selectCustomer;

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

  /// No description provided for @newItem.
  ///
  /// In ar, this message translates to:
  /// **'صنف جديد'**
  String get newItem;

  /// No description provided for @editItem.
  ///
  /// In ar, this message translates to:
  /// **'تعديل صنف'**
  String get editItem;

  /// No description provided for @createItem.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء صنف'**
  String get createItem;

  /// No description provided for @saveChanges.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التعديلات'**
  String get saveChanges;

  /// No description provided for @itemCreated.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء الصنف.'**
  String get itemCreated;

  /// No description provided for @itemUpdated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث الصنف.'**
  String get itemUpdated;

  /// No description provided for @itemDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الصنف'**
  String get itemDetails;

  /// No description provided for @itemType.
  ///
  /// In ar, this message translates to:
  /// **'نوع الصنف'**
  String get itemType;

  /// No description provided for @itemTypeRequired.
  ///
  /// In ar, this message translates to:
  /// **'نوع الصنف *'**
  String get itemTypeRequired;

  /// No description provided for @itemNameNumber.
  ///
  /// In ar, this message translates to:
  /// **'اسم / رقم الصنف *'**
  String get itemNameNumber;

  /// No description provided for @itemNameExample.
  ///
  /// In ar, this message translates to:
  /// **'مثال: طابعة حرارية'**
  String get itemNameExample;

  /// No description provided for @nameAndBarcode.
  ///
  /// In ar, this message translates to:
  /// **'الاسم والباركود'**
  String get nameAndBarcode;

  /// No description provided for @barcode.
  ///
  /// In ar, this message translates to:
  /// **'الباركود'**
  String get barcode;

  /// No description provided for @barcodeHint.
  ///
  /// In ar, this message translates to:
  /// **'امسح أو اكتب الباركود'**
  String get barcodeHint;

  /// No description provided for @barcodeCenter.
  ///
  /// In ar, this message translates to:
  /// **'مركز الباركود'**
  String get barcodeCenter;

  /// No description provided for @generateBarcode.
  ///
  /// In ar, this message translates to:
  /// **'توليد باركود'**
  String get generateBarcode;

  /// No description provided for @generateInternalBarcode.
  ///
  /// In ar, this message translates to:
  /// **'توليد باركود داخلي'**
  String get generateInternalBarcode;

  /// No description provided for @advancedIdentifiers.
  ///
  /// In ar, this message translates to:
  /// **'معرفات إضافية'**
  String get advancedIdentifiers;

  /// No description provided for @advancedIdentifiersHint.
  ///
  /// In ar, this message translates to:
  /// **'رقم القطعة / كود المصنع اختياري.'**
  String get advancedIdentifiersHint;

  /// No description provided for @partNoSkuOptional.
  ///
  /// In ar, this message translates to:
  /// **'رقم القطعة / SKU (اختياري)'**
  String get partNoSkuOptional;

  /// No description provided for @pricing.
  ///
  /// In ar, this message translates to:
  /// **'التسعير'**
  String get pricing;

  /// No description provided for @discount.
  ///
  /// In ar, this message translates to:
  /// **'خصم'**
  String get discount;

  /// No description provided for @discountAmountPercent.
  ///
  /// In ar, this message translates to:
  /// **'قيمة / نسبة الخصم'**
  String get discountAmountPercent;

  /// No description provided for @salesPrice.
  ///
  /// In ar, this message translates to:
  /// **'سعر البيع'**
  String get salesPrice;

  /// No description provided for @purchaseCost.
  ///
  /// In ar, this message translates to:
  /// **'تكلفة الشراء'**
  String get purchaseCost;

  /// No description provided for @purchaseExpenseCost.
  ///
  /// In ar, this message translates to:
  /// **'تكلفة شراء / مصروف'**
  String get purchaseExpenseCost;

  /// No description provided for @openingQtyOnHand.
  ///
  /// In ar, this message translates to:
  /// **'كمية افتتاحية بالمخزن'**
  String get openingQtyOnHand;

  /// No description provided for @postingAccounts.
  ///
  /// In ar, this message translates to:
  /// **'حسابات الترحيل'**
  String get postingAccounts;

  /// No description provided for @incomeAccount.
  ///
  /// In ar, this message translates to:
  /// **'حساب الدخل'**
  String get incomeAccount;

  /// No description provided for @incomeAccountRequired.
  ///
  /// In ar, this message translates to:
  /// **'حساب الدخل *'**
  String get incomeAccountRequired;

  /// No description provided for @inventoryAssetAccountRequired.
  ///
  /// In ar, this message translates to:
  /// **'حساب أصل المخزون *'**
  String get inventoryAssetAccountRequired;

  /// No description provided for @cogsAccountRequired.
  ///
  /// In ar, this message translates to:
  /// **'حساب تكلفة البضاعة المباعة *'**
  String get cogsAccountRequired;

  /// No description provided for @discountAccountRequired.
  ///
  /// In ar, this message translates to:
  /// **'حساب الخصم *'**
  String get discountAccountRequired;

  /// No description provided for @depositPaymentAccountRequired.
  ///
  /// In ar, this message translates to:
  /// **'حساب الإيداع / الدفع *'**
  String get depositPaymentAccountRequired;

  /// No description provided for @assetExpenseAccount.
  ///
  /// In ar, this message translates to:
  /// **'حساب أصل / مصروف'**
  String get assetExpenseAccount;

  /// No description provided for @expensePurchaseAccount.
  ///
  /// In ar, this message translates to:
  /// **'حساب مصروف / شراء'**
  String get expensePurchaseAccount;

  /// No description provided for @notSelected.
  ///
  /// In ar, this message translates to:
  /// **'غير محدد'**
  String get notSelected;

  /// No description provided for @required.
  ///
  /// In ar, this message translates to:
  /// **'مطلوب'**
  String get required;

  /// No description provided for @invalidNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم غير صحيح'**
  String get invalidNumber;

  /// No description provided for @cannotBeNegative.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن أن يكون سالبًا'**
  String get cannotBeNegative;

  /// No description provided for @barcodeExists.
  ///
  /// In ar, this message translates to:
  /// **'هذا الباركود مستخدم في صنف آخر.'**
  String get barcodeExists;

  /// No description provided for @incomeAccountRequiredMsg.
  ///
  /// In ar, this message translates to:
  /// **'حساب الدخل مطلوب.'**
  String get incomeAccountRequiredMsg;

  /// No description provided for @inventoryAssetAccountRequiredMsg.
  ///
  /// In ar, this message translates to:
  /// **'حساب أصل المخزون مطلوب.'**
  String get inventoryAssetAccountRequiredMsg;

  /// No description provided for @cogsAccountRequiredMsg.
  ///
  /// In ar, this message translates to:
  /// **'حساب تكلفة البضاعة المباعة مطلوب.'**
  String get cogsAccountRequiredMsg;

  /// No description provided for @discountAccountRequiredMsg.
  ///
  /// In ar, this message translates to:
  /// **'حساب الخصم مطلوب.'**
  String get discountAccountRequiredMsg;

  /// No description provided for @incomeOrExpenseAccountRequired.
  ///
  /// In ar, this message translates to:
  /// **'مطلوب حساب دخل أو مصروف.'**
  String get incomeOrExpenseAccountRequired;

  /// No description provided for @assetOrExpenseAccountRequired.
  ///
  /// In ar, this message translates to:
  /// **'مطلوب حساب أصل أو مصروف.'**
  String get assetOrExpenseAccountRequired;

  /// No description provided for @depositOrIncomeAccountRequired.
  ///
  /// In ar, this message translates to:
  /// **'مطلوب حساب إيداع أو دخل.'**
  String get depositOrIncomeAccountRequired;

  /// No description provided for @componentItemsNoIncomeAccount.
  ///
  /// In ar, this message translates to:
  /// **'أصناف المجموعة والإجمالي الفرعي لا يجب أن يكون لها حساب دخل مباشر.'**
  String get componentItemsNoIncomeAccount;

  /// No description provided for @purchaseCostRequiredForOpeningQty.
  ///
  /// In ar, this message translates to:
  /// **'تكلفة الشراء مطلوبة مع الكمية الافتتاحية'**
  String get purchaseCostRequiredForOpeningQty;

  /// No description provided for @discountItemHint.
  ///
  /// In ar, this message translates to:
  /// **'صنف الخصم يقلل نماذج البيع بعد الإجمالي الفرعي، ولا يحتاج تكلفة شراء.'**
  String get discountItemHint;

  /// No description provided for @openingQtyHint.
  ///
  /// In ar, this message translates to:
  /// **'الكمية الافتتاحية الأكبر من صفر ترحل قيمة مخزون افتتاحية حسب تكلفة الشراء.'**
  String get openingQtyHint;

  /// No description provided for @componentPostingHint.
  ///
  /// In ar, this message translates to:
  /// **'أصناف المجموعة والإجمالي الفرعي لا ترحل مباشرة، والترحيل يتم من سطور المكونات.'**
  String get componentPostingHint;

  /// No description provided for @newItemHero.
  ///
  /// In ar, this message translates to:
  /// **'صنف جديد'**
  String get newItemHero;

  /// No description provided for @noBarcodeYet.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد باركود بعد'**
  String get noBarcodeYet;

  /// No description provided for @onHand.
  ///
  /// In ar, this message translates to:
  /// **'المتاح'**
  String get onHand;

  /// No description provided for @cost.
  ///
  /// In ar, this message translates to:
  /// **'التكلفة'**
  String get cost;

  /// No description provided for @qtyOnHand.
  ///
  /// In ar, this message translates to:
  /// **'الكمية بالمخزن'**
  String get qtyOnHand;

  /// No description provided for @active.
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In ar, this message translates to:
  /// **'غير نشط'**
  String get inactive;

  /// No description provided for @typeInventoryPart.
  ///
  /// In ar, this message translates to:
  /// **'صنف مخزني'**
  String get typeInventoryPart;

  /// No description provided for @typeNonInventoryPart.
  ///
  /// In ar, this message translates to:
  /// **'صنف غير مخزني'**
  String get typeNonInventoryPart;

  /// No description provided for @typeService.
  ///
  /// In ar, this message translates to:
  /// **'خدمة'**
  String get typeService;

  /// No description provided for @typeBundle.
  ///
  /// In ar, this message translates to:
  /// **'حزمة'**
  String get typeBundle;

  /// No description provided for @typeInventoryAssembly.
  ///
  /// In ar, this message translates to:
  /// **'تجميعة مخزون'**
  String get typeInventoryAssembly;

  /// No description provided for @typeFixedAsset.
  ///
  /// In ar, this message translates to:
  /// **'أصل ثابت'**
  String get typeFixedAsset;

  /// No description provided for @typeOtherCharge.
  ///
  /// In ar, this message translates to:
  /// **'رسوم أخرى'**
  String get typeOtherCharge;

  /// No description provided for @typeSubtotal.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي فرعي'**
  String get typeSubtotal;

  /// No description provided for @typeGroup.
  ///
  /// In ar, this message translates to:
  /// **'مجموعة'**
  String get typeGroup;

  /// No description provided for @typeDiscount.
  ///
  /// In ar, this message translates to:
  /// **'خصم'**
  String get typeDiscount;

  /// No description provided for @typePayment.
  ///
  /// In ar, this message translates to:
  /// **'دفعة'**
  String get typePayment;

  /// No description provided for @typeHintInventory.
  ///
  /// In ar, this message translates to:
  /// **'يتابع الكمية بالمخزن ويرحل إلى أصل المخزون وتكلفة البضاعة المباعة.'**
  String get typeHintInventory;

  /// No description provided for @typeHintNonInventory.
  ///
  /// In ar, this message translates to:
  /// **'لا يتابع مخزونًا، ويمكن شراؤه أو بيعه أو الاثنين.'**
  String get typeHintNonInventory;

  /// No description provided for @typeHintService.
  ///
  /// In ar, this message translates to:
  /// **'عمل أو خدمة غير مخزنية يمكن بيعها أو شراؤها.'**
  String get typeHintService;

  /// No description provided for @typeHintBundle.
  ///
  /// In ar, this message translates to:
  /// **'يجمع أصنافًا في نماذج البيع، والترحيل يتم من المكونات.'**
  String get typeHintBundle;

  /// No description provided for @typeHintInventoryAssembly.
  ///
  /// In ar, this message translates to:
  /// **'يتم تجميعه من مكونات مخزنية ويتابع الكمية بالمخزن.'**
  String get typeHintInventoryAssembly;

  /// No description provided for @typeHintFixedAsset.
  ///
  /// In ar, this message translates to:
  /// **'يتابع أصلًا أو معدات تشتريها وقد تبيعها لاحقًا.'**
  String get typeHintFixedAsset;

  /// No description provided for @typeHintOtherCharge.
  ///
  /// In ar, this message translates to:
  /// **'رسوم متنوعة مثل التوصيل أو التركيب أو مصاريف الخدمة.'**
  String get typeHintOtherCharge;

  /// No description provided for @typeHintSubtotal.
  ///
  /// In ar, this message translates to:
  /// **'يضيف سطر إجمالي فرعي في نماذج البيع أو الشراء.'**
  String get typeHintSubtotal;

  /// No description provided for @typeHintGroup.
  ///
  /// In ar, this message translates to:
  /// **'يجمع عدة أصناف بدون ترحيل مباشر.'**
  String get typeHintGroup;

  /// No description provided for @typeHintDiscount.
  ///
  /// In ar, this message translates to:
  /// **'يخصم مبلغًا ثابتًا أو نسبة من إجمالي فرعي.'**
  String get typeHintDiscount;

  /// No description provided for @typeHintPayment.
  ///
  /// In ar, this message translates to:
  /// **'يسجل صنف دفعة مرتبطًا بحساب إيداع أو دخل.'**
  String get typeHintPayment;

  /// No description provided for @accountsHintInventory.
  ///
  /// In ar, this message translates to:
  /// **'الصنف المخزني يحتاج حساب دخل، أصل مخزون، وتكلفة بضاعة مباعة.'**
  String get accountsHintInventory;

  /// No description provided for @accountsHintNonInventory.
  ///
  /// In ar, this message translates to:
  /// **'استخدم حساب دخل و/أو حساب مصروف.'**
  String get accountsHintNonInventory;

  /// No description provided for @accountsHintService.
  ///
  /// In ar, this message translates to:
  /// **'استخدم حساب دخل و/أو حساب مصروف.'**
  String get accountsHintService;

  /// No description provided for @accountsHintBundle.
  ///
  /// In ar, this message translates to:
  /// **'الحزمة ترحل من خلال الأصناف المكونة لها.'**
  String get accountsHintBundle;

  /// No description provided for @accountsHintInventoryAssembly.
  ///
  /// In ar, this message translates to:
  /// **'التجميعات تحتاج حساب دخل، أصل مخزون، وتكلفة بضاعة مباعة.'**
  String get accountsHintInventoryAssembly;

  /// No description provided for @accountsHintFixedAsset.
  ///
  /// In ar, this message translates to:
  /// **'استخدم حساب أصل أو حساب مصروف.'**
  String get accountsHintFixedAsset;

  /// No description provided for @accountsHintOtherCharge.
  ///
  /// In ar, this message translates to:
  /// **'استخدم حساب دخل و/أو حساب مصروف.'**
  String get accountsHintOtherCharge;

  /// No description provided for @accountsHintSubtotal.
  ///
  /// In ar, this message translates to:
  /// **'سطور الإجمالي الفرعي لا ترحل مباشرة.'**
  String get accountsHintSubtotal;

  /// No description provided for @accountsHintGroup.
  ///
  /// In ar, this message translates to:
  /// **'المجموعة ترحل من خلال الأصناف المكونة لها.'**
  String get accountsHintGroup;

  /// No description provided for @accountsHintDiscount.
  ///
  /// In ar, this message translates to:
  /// **'استخدم حساب خصم واحد فقط، بدون تكلفة شراء أو حسابات مخزون.'**
  String get accountsHintDiscount;

  /// No description provided for @accountsHintPayment.
  ///
  /// In ar, this message translates to:
  /// **'استخدم حساب إيداع أو حساب دخل.'**
  String get accountsHintPayment;

  /// No description provided for @refresh.
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get refresh;

  /// No description provided for @close.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;

  /// No description provided for @type.
  ///
  /// In ar, this message translates to:
  /// **'النوع'**
  String get type;

  /// No description provided for @allItemTypes.
  ///
  /// In ar, this message translates to:
  /// **'كل أنواع الأصناف'**
  String get allItemTypes;

  /// No description provided for @includeInactive.
  ///
  /// In ar, this message translates to:
  /// **'عرض غير النشط'**
  String get includeInactive;

  /// No description provided for @stockValue.
  ///
  /// In ar, this message translates to:
  /// **'قيمة المخزون'**
  String get stockValue;

  /// No description provided for @missingAccounts.
  ///
  /// In ar, this message translates to:
  /// **'حسابات مفقودة'**
  String get missingAccounts;

  /// No description provided for @zeroLowStock.
  ///
  /// In ar, this message translates to:
  /// **'مخزون صفر/منخفض'**
  String get zeroLowStock;

  /// No description provided for @couldNotLoadItems.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الأصناف'**
  String get couldNotLoadItems;

  /// No description provided for @noItemsFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على أصناف'**
  String get noItemsFound;

  /// No description provided for @createNewItemOrImport.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ صنفًا جديدًا أو استورد قائمة.'**
  String get createNewItemOrImport;

  /// No description provided for @csvSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ CSV: {path}'**
  String csvSaved(String path);

  /// No description provided for @excelSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ Excel: {path}'**
  String excelSaved(String path);

  /// No description provided for @excelTemplateSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ قالب Excel: {path}'**
  String excelTemplateSaved(String path);

  /// No description provided for @exportFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل التصدير: {error}'**
  String exportFailed(String error);

  /// No description provided for @excelExportFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل تصدير Excel: {error}'**
  String excelExportFailed(String error);

  /// No description provided for @failedWithError.
  ///
  /// In ar, this message translates to:
  /// **'فشل: {error}'**
  String failedWithError(String error);

  /// No description provided for @itemsUpdatedSuccessfully.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث {count} صنف بنجاح.'**
  String itemsUpdatedSuccessfully(int count);

  /// No description provided for @makeInactive.
  ///
  /// In ar, this message translates to:
  /// **'جعله غير نشط'**
  String get makeInactive;

  /// No description provided for @makeActive.
  ///
  /// In ar, this message translates to:
  /// **'جعله نشط'**
  String get makeActive;

  /// No description provided for @makeInactiveTitle.
  ///
  /// In ar, this message translates to:
  /// **'جعله غير نشط'**
  String get makeInactiveTitle;

  /// No description provided for @makeActiveTitle.
  ///
  /// In ar, this message translates to:
  /// **'جعله نشط'**
  String get makeActiveTitle;

  /// No description provided for @deactivateItemConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تعطيل \"{name}\"؟'**
  String deactivateItemConfirm(String name);

  /// No description provided for @activateItemConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل \"{name}\"؟'**
  String activateItemConfirm(String name);

  /// No description provided for @itemActions.
  ///
  /// In ar, this message translates to:
  /// **'إجراءات الأصناف'**
  String get itemActions;

  /// No description provided for @addEditMultipleItems.
  ///
  /// In ar, this message translates to:
  /// **'إضافة/تعديل عدة أصناف'**
  String get addEditMultipleItems;

  /// No description provided for @importItemsExcelCsv.
  ///
  /// In ar, this message translates to:
  /// **'استيراد أصناف من Excel/CSV'**
  String get importItemsExcelCsv;

  /// No description provided for @exportToCsv.
  ///
  /// In ar, this message translates to:
  /// **'تصدير إلى CSV'**
  String get exportToCsv;

  /// No description provided for @exportToExcel.
  ///
  /// In ar, this message translates to:
  /// **'تصدير إلى Excel (.xlsx)'**
  String get exportToExcel;

  /// No description provided for @downloadImportTemplate.
  ///
  /// In ar, this message translates to:
  /// **'تحميل نموذج الاستيراد'**
  String get downloadImportTemplate;

  /// No description provided for @changeItemPrices.
  ///
  /// In ar, this message translates to:
  /// **'تغيير أسعار الأصناف'**
  String get changeItemPrices;

  /// No description provided for @barcodeCenterPrintLabels.
  ///
  /// In ar, this message translates to:
  /// **'مركز الباركود / طباعة الملصقات'**
  String get barcodeCenterPrintLabels;

  /// No description provided for @price.
  ///
  /// In ar, this message translates to:
  /// **'السعر'**
  String get price;

  /// No description provided for @itemInformation.
  ///
  /// In ar, this message translates to:
  /// **'معلومات الصنف'**
  String get itemInformation;

  /// No description provided for @open.
  ///
  /// In ar, this message translates to:
  /// **'فتح'**
  String get open;

  /// No description provided for @name.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get name;

  /// No description provided for @partNo.
  ///
  /// In ar, this message translates to:
  /// **'رقم القطعة'**
  String get partNo;

  /// No description provided for @unit.
  ///
  /// In ar, this message translates to:
  /// **'الوحدة'**
  String get unit;

  /// No description provided for @inventoryValue.
  ///
  /// In ar, this message translates to:
  /// **'قيمة المخزون'**
  String get inventoryValue;

  /// No description provided for @adjustStock.
  ///
  /// In ar, this message translates to:
  /// **'تسوية المخزون'**
  String get adjustStock;

  /// No description provided for @date.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get date;

  /// No description provided for @account.
  ///
  /// In ar, this message translates to:
  /// **'الحساب'**
  String get account;

  /// No description provided for @stockActivityHint.
  ///
  /// In ar, this message translates to:
  /// **'تظهر حركة المخزون من المبيعات والمشتريات والتسويات.'**
  String get stockActivityHint;

  /// No description provided for @salesPurchaseActivityHint.
  ///
  /// In ar, this message translates to:
  /// **'تظهر حركة البيع والشراء هنا.'**
  String get salesPurchaseActivityHint;

  /// No description provided for @applyTo.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق على'**
  String get applyTo;

  /// No description provided for @method.
  ///
  /// In ar, this message translates to:
  /// **'الطريقة'**
  String get method;

  /// No description provided for @both.
  ///
  /// In ar, this message translates to:
  /// **'كلاهما'**
  String get both;

  /// No description provided for @setFixedPrice.
  ///
  /// In ar, this message translates to:
  /// **'تحديد سعر ثابت'**
  String get setFixedPrice;

  /// No description provided for @setFixedPriceTo.
  ///
  /// In ar, this message translates to:
  /// **'تحديد السعر الثابت إلى'**
  String get setFixedPriceTo;

  /// No description provided for @increaseByAmount.
  ///
  /// In ar, this message translates to:
  /// **'زيادة بمبلغ'**
  String get increaseByAmount;

  /// No description provided for @increaseByPercent.
  ///
  /// In ar, this message translates to:
  /// **'زيادة بنسبة %'**
  String get increaseByPercent;

  /// No description provided for @decreaseByAmount.
  ///
  /// In ar, this message translates to:
  /// **'خفض بمبلغ'**
  String get decreaseByAmount;

  /// No description provided for @decreaseByPercent.
  ///
  /// In ar, this message translates to:
  /// **'خفض بنسبة %'**
  String get decreaseByPercent;

  /// No description provided for @percent.
  ///
  /// In ar, this message translates to:
  /// **'النسبة %'**
  String get percent;

  /// No description provided for @amountEgp.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ بالجنيه'**
  String get amountEgp;

  /// No description provided for @selectItems.
  ///
  /// In ar, this message translates to:
  /// **'اختيار الأصناف ({selected}/{total})'**
  String selectItems(int selected, int total);

  /// No description provided for @none.
  ///
  /// In ar, this message translates to:
  /// **'لا شيء'**
  String get none;

  /// No description provided for @salesCostLine.
  ///
  /// In ar, this message translates to:
  /// **'بيع: {sales}  تكلفة: {cost}'**
  String salesCostLine(String sales, String cost);

  /// No description provided for @applyToItemCount.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق على {count} صنف'**
  String applyToItemCount(int count);

  /// No description provided for @needsAccountSetup.
  ///
  /// In ar, this message translates to:
  /// **'يحتاج ضبط الحسابات'**
  String get needsAccountSetup;

  /// No description provided for @salesPurchaseAndStock.
  ///
  /// In ar, this message translates to:
  /// **'البيع والشراء والمخزون'**
  String get salesPurchaseAndStock;

  /// No description provided for @grossMargin.
  ///
  /// In ar, this message translates to:
  /// **'مجمل الربح'**
  String get grossMargin;

  /// No description provided for @quantityOnHand.
  ///
  /// In ar, this message translates to:
  /// **'الكمية بالمخزن'**
  String get quantityOnHand;

  /// No description provided for @zeroNegativeStockHint.
  ///
  /// In ar, this message translates to:
  /// **'هذا الصنف المخزني كميته صفر أو سالبة. استخدم تسوية المخزون أو استلام المخزون أو الفواتير لتحديث المخزون بشكل صحيح.'**
  String get zeroNegativeStockHint;

  /// No description provided for @identifiers.
  ///
  /// In ar, this message translates to:
  /// **'المعرفات'**
  String get identifiers;

  /// No description provided for @itemId.
  ///
  /// In ar, this message translates to:
  /// **'معرف الصنف'**
  String get itemId;

  /// No description provided for @partNoSku.
  ///
  /// In ar, this message translates to:
  /// **'رقم القطعة / SKU'**
  String get partNoSku;

  /// No description provided for @postingAccountsLower.
  ///
  /// In ar, this message translates to:
  /// **'حسابات الترحيل'**
  String get postingAccountsLower;

  /// No description provided for @incomeAccountLower.
  ///
  /// In ar, this message translates to:
  /// **'حساب الدخل'**
  String get incomeAccountLower;

  /// No description provided for @inventoryAssetAccount.
  ///
  /// In ar, this message translates to:
  /// **'حساب أصل المخزون'**
  String get inventoryAssetAccount;

  /// No description provided for @cogsAccount.
  ///
  /// In ar, this message translates to:
  /// **'حساب تكلفة البضاعة المباعة'**
  String get cogsAccount;

  /// No description provided for @expensePurchaseAccountLower.
  ///
  /// In ar, this message translates to:
  /// **'حساب مصروف / شراء'**
  String get expensePurchaseAccountLower;

  /// No description provided for @bundleDirectPostingHint.
  ///
  /// In ar, this message translates to:
  /// **'أصناف الحزمة/المجموعة لا يجب أن ترحل مباشرة. الأصناف المكونة هي التي تتحكم في الدخل والتكلفة والمخزون لاحقًا.'**
  String get bundleDirectPostingHint;

  /// No description provided for @quickActions.
  ///
  /// In ar, this message translates to:
  /// **'إجراءات سريعة'**
  String get quickActions;

  /// No description provided for @createInvoice.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء فاتورة'**
  String get createInvoice;

  /// No description provided for @inventoryAdjustment.
  ///
  /// In ar, this message translates to:
  /// **'تسوية المخزون'**
  String get inventoryAdjustment;

  /// No description provided for @editItemLower.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الصنف'**
  String get editItemLower;

  /// No description provided for @relatedActivity.
  ///
  /// In ar, this message translates to:
  /// **'النشاط المرتبط'**
  String get relatedActivity;

  /// No description provided for @itemInventoryActivityTrail.
  ///
  /// In ar, this message translates to:
  /// **'استخدم شاشات البيع والشراء واستلام المخزون والتسويات لبناء سجل حركة هذا الصنف.'**
  String get itemInventoryActivityTrail;

  /// No description provided for @itemSalesPurchaseActivityTrail.
  ///
  /// In ar, this message translates to:
  /// **'استخدم شاشات البيع والشراء لبناء سجل حركة هذا الصنف.'**
  String get itemSalesPurchaseActivityTrail;

  /// No description provided for @barcodeValue.
  ///
  /// In ar, this message translates to:
  /// **'الباركود: {value}'**
  String barcodeValue(String value);

  /// No description provided for @partNoValue.
  ///
  /// In ar, this message translates to:
  /// **'رقم القطعة: {value}'**
  String partNoValue(String value);

  /// No description provided for @missingAccountInventory.
  ///
  /// In ar, this message translates to:
  /// **'الصنف المخزني يحتاج حساب دخل، أصل مخزون، وتكلفة بضاعة مباعة قبل أن يكون آمنًا للترحيل.'**
  String get missingAccountInventory;

  /// No description provided for @missingAccountSalesPurchase.
  ///
  /// In ar, this message translates to:
  /// **'هذا الصنف يحتاج حساب دخل أو حساب مصروف/شراء على الأقل قبل أن يكون آمنًا للترحيل.'**
  String get missingAccountSalesPurchase;

  /// No description provided for @missingAccountFixedAsset.
  ///
  /// In ar, this message translates to:
  /// **'الأصل الثابت يحتاج حساب أصل أو مصروف قبل أن يكون آمنًا للترحيل.'**
  String get missingAccountFixedAsset;

  /// No description provided for @missingAccountPayment.
  ///
  /// In ar, this message translates to:
  /// **'صنف الدفعة يحتاج حساب إيداع أو دخل قبل أن يكون آمنًا للترحيل.'**
  String get missingAccountPayment;

  /// No description provided for @missingAccountComponent.
  ///
  /// In ar, this message translates to:
  /// **'أصناف المجموعة والإجمالي الفرعي لا يجب أن يكون لها ترحيل دخل مباشر. الترحيل يجب أن يأتي من سطور المكونات.'**
  String get missingAccountComponent;

  /// No description provided for @missingAccountGeneric.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الترحيل لهذا الصنف غير مكتملة.'**
  String get missingAccountGeneric;

  /// No description provided for @searchNameSkuBarcode.
  ///
  /// In ar, this message translates to:
  /// **'بحث بالاسم أو SKU أو الباركود...'**
  String get searchNameSkuBarcode;

  /// No description provided for @missingBarcode.
  ///
  /// In ar, this message translates to:
  /// **'باركود مفقود'**
  String get missingBarcode;

  /// No description provided for @internal200.
  ///
  /// In ar, this message translates to:
  /// **'داخلي 200'**
  String get internal200;

  /// No description provided for @external.
  ///
  /// In ar, this message translates to:
  /// **'خارجي'**
  String get external;

  /// No description provided for @inStock.
  ///
  /// In ar, this message translates to:
  /// **'متوفر بالمخزون'**
  String get inStock;

  /// No description provided for @withBarcode.
  ///
  /// In ar, this message translates to:
  /// **'له باركود'**
  String get withBarcode;

  /// No description provided for @labels.
  ///
  /// In ar, this message translates to:
  /// **'ملصقات'**
  String get labels;

  /// No description provided for @noItemsMatchFilters.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أصناف مطابقة للفلاتر الحالية.'**
  String get noItemsMatchFilters;

  /// No description provided for @stock.
  ///
  /// In ar, this message translates to:
  /// **'المخزون'**
  String get stock;

  /// No description provided for @barcodeStockLine.
  ///
  /// In ar, this message translates to:
  /// **'{barcode}  |  المخزون: {stock}'**
  String barcodeStockLine(String barcode, String stock);

  /// No description provided for @noBarcode.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد باركود'**
  String get noBarcode;

  /// No description provided for @decrease.
  ///
  /// In ar, this message translates to:
  /// **'تقليل'**
  String get decrease;

  /// No description provided for @increase.
  ///
  /// In ar, this message translates to:
  /// **'زيادة'**
  String get increase;

  /// No description provided for @printSettings.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الطباعة'**
  String get printSettings;

  /// No description provided for @single.
  ///
  /// In ar, this message translates to:
  /// **'مفرد'**
  String get single;

  /// No description provided for @triple.
  ///
  /// In ar, this message translates to:
  /// **'ثلاثي'**
  String get triple;

  /// No description provided for @useStockQty.
  ///
  /// In ar, this message translates to:
  /// **'استخدام كمية المخزون'**
  String get useStockQty;

  /// No description provided for @showSalesPrice.
  ///
  /// In ar, this message translates to:
  /// **'إظهار سعر البيع'**
  String get showSalesPrice;

  /// No description provided for @showCompanyName.
  ///
  /// In ar, this message translates to:
  /// **'إظهار اسم الشركة'**
  String get showCompanyName;

  /// No description provided for @selectedLabels.
  ///
  /// In ar, this message translates to:
  /// **'الملصقات المحددة'**
  String get selectedLabels;

  /// No description provided for @labelSize.
  ///
  /// In ar, this message translates to:
  /// **'مقاس الملصق'**
  String get labelSize;

  /// No description provided for @printer.
  ///
  /// In ar, this message translates to:
  /// **'الطابعة'**
  String get printer;

  /// No description provided for @previewPdfFallback.
  ///
  /// In ar, this message translates to:
  /// **'معاينة/PDF'**
  String get previewPdfFallback;

  /// No description provided for @previewPdf.
  ///
  /// In ar, this message translates to:
  /// **'معاينة PDF'**
  String get previewPdf;

  /// No description provided for @printing.
  ///
  /// In ar, this message translates to:
  /// **'جاري الطباعة...'**
  String get printing;

  /// No description provided for @printLabels.
  ///
  /// In ar, this message translates to:
  /// **'طباعة الملصقات'**
  String get printLabels;

  /// No description provided for @couldNotLoadItemsWithError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الأصناف: {error}'**
  String couldNotLoadItemsWithError(String error);

  /// No description provided for @couldNotBuildBarcodeLabels.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إنشاء ملصقات الباركود: {error}'**
  String couldNotBuildBarcodeLabels(String error);

  /// No description provided for @printFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشلت الطباعة: {error}'**
  String printFailed(String error);

  /// No description provided for @roll80Triple.
  ///
  /// In ar, this message translates to:
  /// **'رول 80 مم - 3 أعمدة'**
  String get roll80Triple;

  /// No description provided for @roll80Single.
  ///
  /// In ar, this message translates to:
  /// **'رول 80 مم - ملصقات مفردة'**
  String get roll80Single;

  /// No description provided for @label50x40Roll.
  ///
  /// In ar, this message translates to:
  /// **'رول ملصقات 50 مم × 40 مم'**
  String get label50x40Roll;

  /// No description provided for @a4SheetLabels.
  ///
  /// In ar, this message translates to:
  /// **'ملصقات ورق A4'**
  String get a4SheetLabels;

  /// No description provided for @importItems.
  ///
  /// In ar, this message translates to:
  /// **'استيراد الأصناف'**
  String get importItems;

  /// No description provided for @exportExcel.
  ///
  /// In ar, this message translates to:
  /// **'تصدير Excel'**
  String get exportExcel;

  /// No description provided for @exportCurrentItems.
  ///
  /// In ar, this message translates to:
  /// **'تصدير الأصناف الحالية'**
  String get exportCurrentItems;

  /// No description provided for @importItemCount.
  ///
  /// In ar, this message translates to:
  /// **'استيراد {count} صنف'**
  String importItemCount(int count);

  /// No description provided for @importItemsCsvExcel.
  ///
  /// In ar, this message translates to:
  /// **'استيراد أصناف من CSV أو Excel'**
  String get importItemsCsvExcel;

  /// No description provided for @selectCsvXlsxFileHint.
  ///
  /// In ar, this message translates to:
  /// **'اختر ملف .csv أو .xlsx لمعاينة الأصناف واستيرادها.'**
  String get selectCsvXlsxFileHint;

  /// No description provided for @browseFile.
  ///
  /// In ar, this message translates to:
  /// **'اختيار ملف'**
  String get browseFile;

  /// No description provided for @expectedItemsWorkbookHint.
  ///
  /// In ar, this message translates to:
  /// **'الملف المتوقع: شيت Items يحتوي على Name, Type, Barcode, Unit, Sales Price, Purchase Cost, Qty on Hand, و Part No.'**
  String get expectedItemsWorkbookHint;

  /// No description provided for @rowCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} صف'**
  String rowCount(int count);

  /// No description provided for @validCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} صالح'**
  String validCount(int count);

  /// No description provided for @errorCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} خطأ'**
  String errorCount(int count);

  /// No description provided for @changeFile.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الملف'**
  String get changeFile;

  /// No description provided for @importingProgress.
  ///
  /// In ar, this message translates to:
  /// **'جاري الاستيراد {done} / {total}...'**
  String importingProgress(int done, int total);

  /// No description provided for @status.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get status;

  /// No description provided for @importComplete.
  ///
  /// In ar, this message translates to:
  /// **'اكتمل الاستيراد!'**
  String get importComplete;

  /// No description provided for @itemsImportedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم استيراد {imported} صنف بنجاح.'**
  String itemsImportedSuccess(int imported);

  /// No description provided for @itemsImportedWithFailures.
  ///
  /// In ar, this message translates to:
  /// **'تم استيراد {imported} صنف بنجاح - فشل {failed}.'**
  String itemsImportedWithFailures(int imported, int failed);

  /// No description provided for @backToItems.
  ///
  /// In ar, this message translates to:
  /// **'العودة إلى الأصناف'**
  String get backToItems;

  /// No description provided for @nameRequired.
  ///
  /// In ar, this message translates to:
  /// **'الاسم مطلوب'**
  String get nameRequired;

  /// No description provided for @noValidRowsToImport.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد صفوف صالحة للاستيراد.'**
  String get noValidRowsToImport;

  /// No description provided for @inventoryOpeningQtyRequiresPurchasePrice.
  ///
  /// In ar, this message translates to:
  /// **'الكمية الافتتاحية للمخزون تحتاج تكلفة شراء.'**
  String get inventoryOpeningQtyRequiresPurchasePrice;

  /// No description provided for @incomeAccountNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على حساب الدخل.'**
  String get incomeAccountNotFound;

  /// No description provided for @inventoryAssetAccountNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على حساب أصل المخزون.'**
  String get inventoryAssetAccountNotFound;

  /// No description provided for @cogsAccountNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على حساب تكلفة البضاعة المباعة.'**
  String get cogsAccountNotFound;

  /// No description provided for @incomeOrExpenseAccountNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على حساب دخل أو مصروف.'**
  String get incomeOrExpenseAccountNotFound;

  /// No description provided for @assetOrExpenseAccountNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على حساب أصل أو مصروف.'**
  String get assetOrExpenseAccountNotFound;

  /// No description provided for @depositOrIncomeAccountNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على حساب إيداع أو دخل.'**
  String get depositOrIncomeAccountNotFound;

  /// No description provided for @couldNotSaveExcelTemplate.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حفظ قالب Excel: {error}'**
  String couldNotSaveExcelTemplate(String error);

  /// No description provided for @excelExportSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ تصدير Excel: {path}'**
  String excelExportSaved(String path);

  /// No description provided for @customerTransactionHistory.
  ///
  /// In ar, this message translates to:
  /// **'سجل معاملات العميل'**
  String get customerTransactionHistory;

  /// No description provided for @customerStatement.
  ///
  /// In ar, this message translates to:
  /// **'كشف حساب عميل'**
  String get customerStatement;

  /// No description provided for @vendorStatement.
  ///
  /// In ar, this message translates to:
  /// **'كشف حساب مورد'**
  String get vendorStatement;

  /// No description provided for @print.
  ///
  /// In ar, this message translates to:
  /// **'طباعة'**
  String get print;

  /// No description provided for @chooseCustomerBeforePrinting.
  ///
  /// In ar, this message translates to:
  /// **'اختر عميلاً قبل الطباعة.'**
  String get chooseCustomerBeforePrinting;

  /// No description provided for @chooseVendorBeforePrinting.
  ///
  /// In ar, this message translates to:
  /// **'اختر موردًا قبل الطباعة.'**
  String get chooseVendorBeforePrinting;

  /// No description provided for @couldNotPrintCustomerStatement.
  ///
  /// In ar, this message translates to:
  /// **'تعذرت طباعة كشف حساب العميل: {error}'**
  String couldNotPrintCustomerStatement(String error);

  /// No description provided for @couldNotPrintVendorStatement.
  ///
  /// In ar, this message translates to:
  /// **'تعذرت طباعة كشف حساب المورد: {error}'**
  String couldNotPrintVendorStatement(String error);

  /// No description provided for @loadingCustomers.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل العملاء...'**
  String get loadingCustomers;

  /// No description provided for @loadingVendors.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل الموردين...'**
  String get loadingVendors;

  /// No description provided for @dateRange.
  ///
  /// In ar, this message translates to:
  /// **'الفترة'**
  String get dateRange;

  /// No description provided for @clearDateRange.
  ///
  /// In ar, this message translates to:
  /// **'مسح الفترة'**
  String get clearDateRange;

  /// No description provided for @chooseCustomer.
  ///
  /// In ar, this message translates to:
  /// **'اختر عميلًا'**
  String get chooseCustomer;

  /// No description provided for @chooseVendor.
  ///
  /// In ar, this message translates to:
  /// **'اختر موردًا'**
  String get chooseVendor;

  /// No description provided for @selectCustomerToViewHistory.
  ///
  /// In ar, this message translates to:
  /// **'اختر عميلًا لعرض سجل المعاملات.'**
  String get selectCustomerToViewHistory;

  /// No description provided for @selectVendorToViewStatement.
  ///
  /// In ar, this message translates to:
  /// **'اختر موردًا لعرض معاملات كشف الحساب.'**
  String get selectVendorToViewStatement;

  /// No description provided for @couldNotLoadTransactions.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل المعاملات'**
  String get couldNotLoadTransactions;

  /// No description provided for @noTransactionsFound.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد معاملات'**
  String get noTransactionsFound;

  /// No description provided for @noTransactionsMatchFilters.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد معاملات مطابقة للفلاتر المحددة.'**
  String get noTransactionsMatchFilters;

  /// No description provided for @previewAndPrint.
  ///
  /// In ar, this message translates to:
  /// **'معاينة وطباعة'**
  String get previewAndPrint;

  /// No description provided for @previewA4.
  ///
  /// In ar, this message translates to:
  /// **'معاينة A4'**
  String get previewA4;

  /// No description provided for @printA4.
  ///
  /// In ar, this message translates to:
  /// **'طباعة A4'**
  String get printA4;

  /// No description provided for @printThermal.
  ///
  /// In ar, this message translates to:
  /// **'طباعة حرارية'**
  String get printThermal;

  /// No description provided for @emailShare.
  ///
  /// In ar, this message translates to:
  /// **'إرسال / مشاركة'**
  String get emailShare;

  /// No description provided for @saveAndPrint.
  ///
  /// In ar, this message translates to:
  /// **'حفظ وطباعة'**
  String get saveAndPrint;

  /// No description provided for @saveAndNew.
  ///
  /// In ar, this message translates to:
  /// **'حفظ وجديد'**
  String get saveAndNew;

  /// No description provided for @saveAsDraft.
  ///
  /// In ar, this message translates to:
  /// **'حفظ كمسودة'**
  String get saveAsDraft;

  /// No description provided for @saveOptions.
  ///
  /// In ar, this message translates to:
  /// **'خيارات الحفظ'**
  String get saveOptions;

  /// No description provided for @posting.
  ///
  /// In ar, this message translates to:
  /// **'جاري الترحيل'**
  String get posting;

  /// No description provided for @draft.
  ///
  /// In ar, this message translates to:
  /// **'مسودة'**
  String get draft;

  /// No description provided for @voidText.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get voidText;

  /// No description provided for @refund.
  ///
  /// In ar, this message translates to:
  /// **'رد مبلغ'**
  String get refund;

  /// No description provided for @receive.
  ///
  /// In ar, this message translates to:
  /// **'استلام'**
  String get receive;

  /// No description provided for @savePurchaseOrderBeforePrinting.
  ///
  /// In ar, this message translates to:
  /// **'احفظ أمر الشراء قبل الطباعة.'**
  String get savePurchaseOrderBeforePrinting;

  /// No description provided for @salesSummary.
  ///
  /// In ar, this message translates to:
  /// **'ملخص المبيعات'**
  String get salesSummary;

  /// No description provided for @purchasesSummary.
  ///
  /// In ar, this message translates to:
  /// **'ملخص المشتريات'**
  String get purchasesSummary;

  /// No description provided for @payrollSummary.
  ///
  /// In ar, this message translates to:
  /// **'ملخص الرواتب'**
  String get payrollSummary;

  /// No description provided for @timeTrackingSummary.
  ///
  /// In ar, this message translates to:
  /// **'ملخص تتبع الوقت'**
  String get timeTrackingSummary;

  /// No description provided for @openCustomerStatement.
  ///
  /// In ar, this message translates to:
  /// **'فتح كشف حساب العميل'**
  String get openCustomerStatement;

  /// No description provided for @openVendorStatement.
  ///
  /// In ar, this message translates to:
  /// **'فتح كشف حساب المورد'**
  String get openVendorStatement;

  /// No description provided for @customerStatementSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'كشف حساب تفصيلي للعميل مع فلاتر العميل والفترة والنوع وطباعة PDF بحجم A4.'**
  String get customerStatementSubtitle;

  /// No description provided for @vendorStatementSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'كشف حساب تفصيلي للمورد مع فلاتر المورد والفترة والنوع وطباعة PDF بحجم A4.'**
  String get vendorStatementSubtitle;

  /// No description provided for @customerDropdown.
  ///
  /// In ar, this message translates to:
  /// **'قائمة العملاء'**
  String get customerDropdown;

  /// No description provided for @vendorDropdown.
  ///
  /// In ar, this message translates to:
  /// **'قائمة الموردين'**
  String get vendorDropdown;

  /// No description provided for @receiptsPaymentsInvoices.
  ///
  /// In ar, this message translates to:
  /// **'إيصالات / مدفوعات / فواتير'**
  String get receiptsPaymentsInvoices;

  /// No description provided for @billsPayments.
  ///
  /// In ar, this message translates to:
  /// **'فواتير / مدفوعات'**
  String get billsPayments;

  /// No description provided for @a4PdfPrint.
  ///
  /// In ar, this message translates to:
  /// **'طباعة PDF A4'**
  String get a4PdfPrint;

  /// No description provided for @statementLauncherHint.
  ///
  /// In ar, this message translates to:
  /// **'هذا التقرير يفتح شاشة كشف حساب مباشرة بها فلاتر وطباعة. ويمكن فتح نفس الشاشة لاحقًا من المستندات أو صفحات الأطراف.'**
  String get statementLauncherHint;

  /// No description provided for @totalSales.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المبيعات'**
  String get totalSales;

  /// No description provided for @totalPurchases.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المشتريات'**
  String get totalPurchases;

  /// No description provided for @balanceDue.
  ///
  /// In ar, this message translates to:
  /// **'الرصيد المستحق'**
  String get balanceDue;

  /// No description provided for @invoice.
  ///
  /// In ar, this message translates to:
  /// **'الفاتورة'**
  String get invoice;

  /// No description provided for @bill.
  ///
  /// In ar, this message translates to:
  /// **'فاتورة شراء'**
  String get bill;

  /// No description provided for @due.
  ///
  /// In ar, this message translates to:
  /// **'الاستحقاق'**
  String get due;

  /// No description provided for @paid.
  ///
  /// In ar, this message translates to:
  /// **'مدفوع'**
  String get paid;

  /// No description provided for @balance.
  ///
  /// In ar, this message translates to:
  /// **'الرصيد'**
  String get balance;

  /// No description provided for @runs.
  ///
  /// In ar, this message translates to:
  /// **'دورات'**
  String get runs;

  /// No description provided for @grossPay.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الراتب'**
  String get grossPay;

  /// No description provided for @netPay.
  ///
  /// In ar, this message translates to:
  /// **'صافي الراتب'**
  String get netPay;

  /// No description provided for @run.
  ///
  /// In ar, this message translates to:
  /// **'الدورة'**
  String get run;

  /// No description provided for @payDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الصرف'**
  String get payDate;

  /// No description provided for @gross.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get gross;

  /// No description provided for @deductions.
  ///
  /// In ar, this message translates to:
  /// **'الاستقطاعات'**
  String get deductions;

  /// No description provided for @net.
  ///
  /// In ar, this message translates to:
  /// **'الصافي'**
  String get net;

  /// No description provided for @entries.
  ///
  /// In ar, this message translates to:
  /// **'إدخالات'**
  String get entries;

  /// No description provided for @totalHours.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الساعات'**
  String get totalHours;

  /// No description provided for @billableHours.
  ///
  /// In ar, this message translates to:
  /// **'ساعات قابلة للفوترة'**
  String get billableHours;

  /// No description provided for @billableNotInvoiced.
  ///
  /// In ar, this message translates to:
  /// **'قابل للفوترة ولم تتم فوترته'**
  String get billableNotInvoiced;

  /// No description provided for @person.
  ///
  /// In ar, this message translates to:
  /// **'الشخص'**
  String get person;

  /// No description provided for @service.
  ///
  /// In ar, this message translates to:
  /// **'الخدمة'**
  String get service;

  /// No description provided for @activity.
  ///
  /// In ar, this message translates to:
  /// **'النشاط'**
  String get activity;

  /// No description provided for @hours.
  ///
  /// In ar, this message translates to:
  /// **'الساعات'**
  String get hours;

  /// No description provided for @reportDateRange.
  ///
  /// In ar, this message translates to:
  /// **'فترة التقرير'**
  String get reportDateRange;

  /// No description provided for @fromDate.
  ///
  /// In ar, this message translates to:
  /// **'من تاريخ'**
  String get fromDate;

  /// No description provided for @toDate.
  ///
  /// In ar, this message translates to:
  /// **'إلى تاريخ'**
  String get toDate;

  /// No description provided for @change.
  ///
  /// In ar, this message translates to:
  /// **'تغيير'**
  String get change;

  /// No description provided for @apply.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق'**
  String get apply;

  /// No description provided for @statusSent.
  ///
  /// In ar, this message translates to:
  /// **'مرسل'**
  String get statusSent;

  /// No description provided for @statusVoid.
  ///
  /// In ar, this message translates to:
  /// **'ملغي'**
  String get statusVoid;

  /// No description provided for @statusReturned.
  ///
  /// In ar, this message translates to:
  /// **'مرتجع'**
  String get statusReturned;

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

  /// No description provided for @companyHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get companyHome;

  /// No description provided for @logout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logout;

  /// No description provided for @switchToEnglish.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get switchToEnglish;

  /// No description provided for @switchToArabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get switchToArabic;

  /// No description provided for @expandSidebar.
  ///
  /// In ar, this message translates to:
  /// **'توسيع القائمة'**
  String get expandSidebar;

  /// No description provided for @collapseSidebar.
  ///
  /// In ar, this message translates to:
  /// **'طي القائمة'**
  String get collapseSidebar;

  /// No description provided for @plutoGridDemo.
  ///
  /// In ar, this message translates to:
  /// **'تجربة شبكة البيانات'**
  String get plutoGridDemo;

  /// No description provided for @customerCredits.
  ///
  /// In ar, this message translates to:
  /// **'أرصدة العملاء'**
  String get customerCredits;

  /// No description provided for @vendorCredits.
  ///
  /// In ar, this message translates to:
  /// **'أرصدة الموردين'**
  String get vendorCredits;

  /// No description provided for @banking.
  ///
  /// In ar, this message translates to:
  /// **'البنوك'**
  String get banking;

  /// No description provided for @bankRegister.
  ///
  /// In ar, this message translates to:
  /// **'سجل البنك'**
  String get bankRegister;

  /// No description provided for @writeChecks.
  ///
  /// In ar, this message translates to:
  /// **'كتابة شيكات'**
  String get writeChecks;

  /// No description provided for @makeDeposits.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل إيداعات'**
  String get makeDeposits;

  /// No description provided for @reconcile.
  ///
  /// In ar, this message translates to:
  /// **'تسوية بنكية'**
  String get reconcile;

  /// No description provided for @transactions.
  ///
  /// In ar, this message translates to:
  /// **'المعاملات'**
  String get transactions;

  /// No description provided for @customerCenter.
  ///
  /// In ar, this message translates to:
  /// **'مركز العملاء'**
  String get customerCenter;

  /// No description provided for @openBills.
  ///
  /// In ar, this message translates to:
  /// **'الفواتير المفتوحة'**
  String get openBills;

  /// No description provided for @cashFlowAlerts.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات التدفق النقدي'**
  String get cashFlowAlerts;

  /// No description provided for @openHub.
  ///
  /// In ar, this message translates to:
  /// **'فتح المركز'**
  String get openHub;

  /// No description provided for @cashLabel.
  ///
  /// In ar, this message translates to:
  /// **'النقدية'**
  String get cashLabel;

  /// No description provided for @noCashFlowActivity.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد حركة تدفق نقدي بعد.'**
  String get noCashFlowActivity;

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

  /// No description provided for @salesReceipts.
  ///
  /// In ar, this message translates to:
  /// **'إيصالات البيع'**
  String get salesReceipts;

  /// No description provided for @salesReturns.
  ///
  /// In ar, this message translates to:
  /// **'مرتجعات البيع'**
  String get salesReturns;

  /// No description provided for @purchaseReturns.
  ///
  /// In ar, this message translates to:
  /// **'مرتجعات الشراء'**
  String get purchaseReturns;

  /// No description provided for @customerPayments.
  ///
  /// In ar, this message translates to:
  /// **'تحصيلات العملاء'**
  String get customerPayments;

  /// No description provided for @inventoryAdjustments.
  ///
  /// In ar, this message translates to:
  /// **'تسويات المخزون'**
  String get inventoryAdjustments;

  /// No description provided for @newInvoice.
  ///
  /// In ar, this message translates to:
  /// **'فاتورة جديدة'**
  String get newInvoice;

  /// No description provided for @newPayment.
  ///
  /// In ar, this message translates to:
  /// **'تحصيل جديد'**
  String get newPayment;

  /// No description provided for @newSalesReturn.
  ///
  /// In ar, this message translates to:
  /// **'مرتجع بيع جديد'**
  String get newSalesReturn;

  /// No description provided for @newPurchaseReturn.
  ///
  /// In ar, this message translates to:
  /// **'مرتجع شراء جديد'**
  String get newPurchaseReturn;

  /// No description provided for @newInventoryAdjustment.
  ///
  /// In ar, this message translates to:
  /// **'تسوية مخزون جديدة'**
  String get newInventoryAdjustment;

  /// No description provided for @noInvoices.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد فواتير'**
  String get noInvoices;

  /// No description provided for @noPayments.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تحصيلات عملاء'**
  String get noPayments;

  /// No description provided for @noVendorPayments.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مدفوعات موردين'**
  String get noVendorPayments;

  /// No description provided for @noSalesReturns.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مرتجعات بيع'**
  String get noSalesReturns;

  /// No description provided for @noSalesReceipts.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إيصالات بيع'**
  String get noSalesReceipts;

  /// No description provided for @startSalesReceipt.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ بيعاً مباشراً بإيصال بيع'**
  String get startSalesReceipt;

  /// No description provided for @noPurchaseReturns.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مرتجعات شراء'**
  String get noPurchaseReturns;

  /// No description provided for @selectCustomerFirst.
  ///
  /// In ar, this message translates to:
  /// **'اختر العميل أولاً'**
  String get selectCustomerFirst;

  /// No description provided for @selectInvoiceFirst.
  ///
  /// In ar, this message translates to:
  /// **'اختر الفاتورة أولاً'**
  String get selectInvoiceFirst;

  /// No description provided for @selectPurchaseBillFirst.
  ///
  /// In ar, this message translates to:
  /// **'اختر فاتورة الشراء أولاً'**
  String get selectPurchaseBillFirst;

  /// No description provided for @selectDepositAccountFirst.
  ///
  /// In ar, this message translates to:
  /// **'اختر حساب الإيداع أولاً'**
  String get selectDepositAccountFirst;

  /// No description provided for @selectPaymentAccountFirst.
  ///
  /// In ar, this message translates to:
  /// **'اختر حساب الدفع أولاً'**
  String get selectPaymentAccountFirst;

  /// No description provided for @enterPositiveAmount.
  ///
  /// In ar, this message translates to:
  /// **'أدخل مبلغاً أكبر من صفر'**
  String get enterPositiveAmount;

  /// No description provided for @selectAtLeastOneLine.
  ///
  /// In ar, this message translates to:
  /// **'اختر سطرًا واحدًا على الأقل'**
  String get selectAtLeastOneLine;

  /// No description provided for @returnQuantityCannotExceedOriginal.
  ///
  /// In ar, this message translates to:
  /// **'كمية المرتجع لا يمكن أن تتجاوز الكمية الأصلية'**
  String get returnQuantityCannotExceedOriginal;

  /// No description provided for @invoiceSavedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الفاتورة بنجاح'**
  String get invoiceSavedSuccess;

  /// No description provided for @customerPaymentSavedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل تحصيل العميل بنجاح'**
  String get customerPaymentSavedSuccess;

  /// No description provided for @salesReturnSavedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ مرتجع البيع بنجاح'**
  String get salesReturnSavedSuccess;

  /// No description provided for @salesReceiptCreatedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء إيصال البيع بنجاح'**
  String get salesReceiptCreatedSuccess;

  /// No description provided for @purchaseReturnSavedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ مرتجع الشراء بنجاح'**
  String get purchaseReturnSavedSuccess;

  /// No description provided for @customer.
  ///
  /// In ar, this message translates to:
  /// **'العميل'**
  String get customer;

  /// No description provided for @purchaseBill.
  ///
  /// In ar, this message translates to:
  /// **'فاتورة الشراء'**
  String get purchaseBill;

  /// No description provided for @depositAccount.
  ///
  /// In ar, this message translates to:
  /// **'حساب الإيداع'**
  String get depositAccount;

  /// No description provided for @selectDepositAccount.
  ///
  /// In ar, this message translates to:
  /// **'اختر حساب الإيداع...'**
  String get selectDepositAccount;

  /// No description provided for @depositAccountHint.
  ///
  /// In ar, this message translates to:
  /// **'اختر حساباً بنكياً أو نقدياً'**
  String get depositAccountHint;

  /// No description provided for @returnDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ المرتجع'**
  String get returnDate;

  /// No description provided for @unitCost.
  ///
  /// In ar, this message translates to:
  /// **'تكلفة الوحدة'**
  String get unitCost;

  /// No description provided for @unitPrice.
  ///
  /// In ar, this message translates to:
  /// **'سعر الوحدة'**
  String get unitPrice;

  /// No description provided for @originalQuantity.
  ///
  /// In ar, this message translates to:
  /// **'الكمية الأصلية'**
  String get originalQuantity;

  /// No description provided for @returnQuantity.
  ///
  /// In ar, this message translates to:
  /// **'كمية المرتجع'**
  String get returnQuantity;

  /// No description provided for @lineTotal.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي السطر'**
  String get lineTotal;

  /// No description provided for @statusVoided.
  ///
  /// In ar, this message translates to:
  /// **'ملغي'**
  String get statusVoided;

  /// No description provided for @statusPosted.
  ///
  /// In ar, this message translates to:
  /// **'مرحل'**
  String get statusPosted;

  /// No description provided for @cash.
  ///
  /// In ar, this message translates to:
  /// **'كاش'**
  String get cash;

  /// No description provided for @check.
  ///
  /// In ar, this message translates to:
  /// **'شيك'**
  String get check;

  /// No description provided for @bankTransfer.
  ///
  /// In ar, this message translates to:
  /// **'تحويل بنكي'**
  String get bankTransfer;

  /// No description provided for @creditCard.
  ///
  /// In ar, this message translates to:
  /// **'بطاقة'**
  String get creditCard;

  /// No description provided for @reason.
  ///
  /// In ar, this message translates to:
  /// **'السبب'**
  String get reason;

  /// No description provided for @totalReturn.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المرتجع'**
  String get totalReturn;

  /// No description provided for @posted.
  ///
  /// In ar, this message translates to:
  /// **'مرحل'**
  String get posted;

  /// No description provided for @voided.
  ///
  /// In ar, this message translates to:
  /// **'ملغي'**
  String get voided;

  /// No description provided for @noInventoryAdjustments.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تسويات مخزون'**
  String get noInventoryAdjustments;

  /// No description provided for @startWithNewInventoryAdjustment.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ بإنشاء تسوية مخزون جديدة.'**
  String get startWithNewInventoryAdjustment;

  /// No description provided for @selectItemFirst.
  ///
  /// In ar, this message translates to:
  /// **'اختر الصنف أولاً'**
  String get selectItemFirst;

  /// No description provided for @enterValidQuantity.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كمية صحيحة'**
  String get enterValidQuantity;

  /// No description provided for @inventoryAdjustmentSavedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ تسوية المخزون بنجاح'**
  String get inventoryAdjustmentSavedSuccess;

  /// No description provided for @journalEntries.
  ///
  /// In ar, this message translates to:
  /// **'القيود اليومية'**
  String get journalEntries;

  /// No description provided for @newJournalEntry.
  ///
  /// In ar, this message translates to:
  /// **'قيد يومية جديد'**
  String get newJournalEntry;

  /// No description provided for @noJournalEntries.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد قيود يومية'**
  String get noJournalEntries;

  /// No description provided for @startWithNewJournalEntry.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ بإنشاء قيد يومية متوازن.'**
  String get startWithNewJournalEntry;

  /// No description provided for @entryDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ القيد'**
  String get entryDate;

  /// No description provided for @memo.
  ///
  /// In ar, this message translates to:
  /// **'مذكرة'**
  String get memo;

  /// No description provided for @debit.
  ///
  /// In ar, this message translates to:
  /// **'مدين'**
  String get debit;

  /// No description provided for @credit.
  ///
  /// In ar, this message translates to:
  /// **'دائن'**
  String get credit;

  /// No description provided for @totalDebit.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المدين'**
  String get totalDebit;

  /// No description provided for @totalCredit.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الدائن'**
  String get totalCredit;

  /// No description provided for @balanced.
  ///
  /// In ar, this message translates to:
  /// **'متوازن'**
  String get balanced;

  /// No description provided for @unbalanced.
  ///
  /// In ar, this message translates to:
  /// **'غير متوازن'**
  String get unbalanced;

  /// No description provided for @saveAndPost.
  ///
  /// In ar, this message translates to:
  /// **'حفظ وترحيل'**
  String get saveAndPost;

  /// No description provided for @journalEntrySavedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ قيد اليومية بنجاح'**
  String get journalEntrySavedSuccess;

  /// No description provided for @itemsLines.
  ///
  /// In ar, this message translates to:
  /// **'سطور'**
  String get itemsLines;

  /// No description provided for @seedDefaults.
  ///
  /// In ar, this message translates to:
  /// **'إعداد الحسابات الافتراضية'**
  String get seedDefaults;

  /// No description provided for @allTypes.
  ///
  /// In ar, this message translates to:
  /// **'كل الأنواع'**
  String get allTypes;

  /// No description provided for @typeFilter.
  ///
  /// In ar, this message translates to:
  /// **'النوع'**
  String get typeFilter;

  /// No description provided for @searchCodeOrName.
  ///
  /// In ar, this message translates to:
  /// **'بحث بالكود أو الاسم...'**
  String get searchCodeOrName;

  /// No description provided for @noAccountsFound.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد حسابات'**
  String get noAccountsFound;

  /// No description provided for @createOrSeedHint.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ حساباً جديداً أو قم بإعداد الحسابات الافتراضية.'**
  String get createOrSeedHint;

  /// No description provided for @seedCreated.
  ///
  /// In ar, this message translates to:
  /// **'الإعداد: تم إنشاء {count}'**
  String seedCreated(Object count);

  /// No description provided for @coaShortcutHint.
  ///
  /// In ar, this message translates to:
  /// **'دليل الحسابات  •  Enter للتعديل  •  Esc للإغلاق'**
  String get coaShortcutHint;

  /// No description provided for @accounts.
  ///
  /// In ar, this message translates to:
  /// **'الحسابات'**
  String get accounts;

  /// No description provided for @activate.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل'**
  String get activate;

  /// No description provided for @deactivate.
  ///
  /// In ar, this message translates to:
  /// **'تعطيل'**
  String get deactivate;

  /// No description provided for @inventoryCenter.
  ///
  /// In ar, this message translates to:
  /// **'مركز المخزون'**
  String get inventoryCenter;

  /// No description provided for @inventoryCenterDescription.
  ///
  /// In ar, this message translates to:
  /// **'إدارة بنود المخزون، والبنود غير المخزنية، والخدمات، ومجموعات البنود مع سلوك ترحيل بأسلوب Zayed.'**
  String get inventoryCenterDescription;

  /// No description provided for @lowOrZeroStock.
  ///
  /// In ar, this message translates to:
  /// **'مخزون منخفض/صفر'**
  String get lowOrZeroStock;

  /// No description provided for @importItemsExcel.
  ///
  /// In ar, this message translates to:
  /// **'استيراد الأصناف من Excel/CSV'**
  String get importItemsExcel;

  /// No description provided for @exportItemsExcel.
  ///
  /// In ar, this message translates to:
  /// **'تصدير الأصناف إلى Excel/CSV'**
  String get exportItemsExcel;

  /// No description provided for @createOrImportItemsHint.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ صنفاً جديداً أو استورد قائمة من ملف Excel.'**
  String get createOrImportItemsHint;
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
