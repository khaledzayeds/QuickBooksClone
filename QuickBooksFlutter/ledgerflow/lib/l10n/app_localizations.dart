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
