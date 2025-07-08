import 'package:hive/hive.dart';
import '../models/sms_model.dart';

Future<Box<SmsModel>> openUserBox(String email) async {
  final name = 'transactions_${email.replaceAll('@', '_').replaceAll('.', '_')}';
  if (!Hive.isBoxOpen(name)) {
    return await Hive.openBox<SmsModel>(name);
  }
  return Hive.box<SmsModel>(name);
}
