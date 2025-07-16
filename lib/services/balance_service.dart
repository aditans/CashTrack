import 'package:shared_preferences/shared_preferences.dart';

class BalanceService {
  static const _balanceKey = 'manual_balance';
  static const _timestampKey = 'manual_balance_timestamp';

  Future<void> setManualBalance(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_balanceKey, value);
    await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<double?> getManualBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_balanceKey);
  }

  Future<DateTime?> getManualBalanceTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_timestampKey);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> clearManualBalance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_balanceKey);
    await prefs.remove(_timestampKey);
  }
}
