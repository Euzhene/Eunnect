import 'dart:convert';

import 'package:eunnect/models/custom_message.dart';

const _fileInfoField = "file_info";
const _notificationIdField = "notification_id";
const _deviceNameField = "device_name";

class NotificationFile {
  final FileMessage fileInfo;
  final int notificationId;
  final String deviceName;

  NotificationFile({
    required this.fileInfo,
    required this.notificationId,
    required this.deviceName,
  });

  String toJsonString() => jsonEncode({
        _fileInfoField: fileInfo.toJsonString(),
        _notificationIdField: notificationId,
        _deviceNameField: deviceName,
      });

  NotificationFile.fromJson(Map<String, dynamic> json)
      : fileInfo = FileMessage.fromJsonString(json[_fileInfoField]),
        notificationId = json[_notificationIdField],
        deviceName = json[_deviceNameField];

  static NotificationFile fromJsonString(String json) => NotificationFile.fromJson(jsonDecode(json));
}
