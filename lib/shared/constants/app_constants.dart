/// App-wide constants.
abstract final class AppConstants {
  static const appName = 'Mony';
  static const defaultCurrency = 'INR';
  static const smsDuplicateWindowMs = 5 * 60 * 1000; // 5 minutes
  static const fuzzyMatchThreshold = 0.75;
  static const reconciliationDateToleranceDays = 1;
  static const mcpServerPort = 7432;
  static const dbFileName = 'mony.db';
  static const backupFileName = 'mony_backup.json';
}
