import 'package:permission_handler/permission_handler.dart';

Future<bool> requestSmsAndNotificationPermissions() async {
  final smsStatus = await Permission.sms.request();
  final notifStatus = await Permission.notification.request();

  return smsStatus.isGranted && notifStatus.isGranted;
}