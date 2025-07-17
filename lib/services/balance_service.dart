import 'package:shared_preferences/shared_preferences.dart';

class BalanceService {
  String _balanceKey(DateTime date) =>
      'manual_balance_${date.year}_${date.month}';

  String _timestampKey(DateTime date) =>
      'manual_balance_timestamp_${date.year}_${date.month}';

  Future<void> setManualBalance(DateTime date,double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_balanceKey(date), value);
    await prefs.setInt(_timestampKey(date), DateTime.now().millisecondsSinceEpoch);
  }

  Future<double?> getManualBalance(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_balanceKey(date));
  }

  Future<DateTime?> getManualBalanceTimestamp(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_timestampKey(date));
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> clearManualBalance(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_balanceKey(date));
    await prefs.remove(_timestampKey(date));
  }
}
