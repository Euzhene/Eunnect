import 'package:eunnect/models/custom_message.dart';

class NotificationFile {
  final FileMessage fileInfo;
  final int notificationId;
  final String deviceName;

  NotificationFile({
    required this.fileInfo,
    required this.notificationId,
    required this.deviceName,
  });
}
