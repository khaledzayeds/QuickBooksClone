// app_constants.dart
// core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  static const appName = 'LedgerFlow';
  static const appEdition = 'Offline';
  static const appDisplayName = '$appName $appEdition';

  /// Internal local API endpoint used by the desktop offline build.
  ///
  /// The user should not need to start or configure this endpoint manually;
  /// a desktop launcher/host will own that responsibility.
  static const defaultBaseUrl = 'http://localhost:5014';

  static const dataRootFolderName = 'LedgerFlow';
  static const companiesFolderName = 'Companies';
  static const backupsFolderName = 'Backups';
  static const templatesFolderName = 'Templates';

  static const defaultCompanyDatabaseFileName = 'ledgerflow.db';
  static const companyFileExtension = '.ledgerflow';
}
