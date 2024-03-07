import 'dart:math';

import 'package:eunnect/helpers/notification/notification_file.dart';
import 'package:eunnect/models/custom_message.dart';
import 'package:eunnect/models/device_info/device_info.dart';
import 'package:eunnect/utils/file_utils.dart';
import 'package:f_logs/f_logs.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const String _acceptId = "accept";
const String _denyId = "deny";
const String _blockId = "block";

abstract class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static Function(DeviceInfo)? onPairingAccepted;
  static Function(DeviceInfo)? onPairingDenied;
  static Function(DeviceInfo)? onPairingBlocked;
  static Function(DeviceInfo)? onNotificationClicked;

  static Future<void> init() async {
// initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(onDidReceiveLocalNotification: _onDidReceiveLocalNotification);
    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');
    const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        macOS: initializationSettingsDarwin,
        linux: initializationSettingsLinux);
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse);
  }

  static Future<void> createPairingNotification({required DeviceInfo anotherDeviceInfo}) async {
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails('pairing', 'pairing',
        channelDescription: 'request for pairing',
        category: AndroidNotificationCategory.event,
        importance: Importance.max,
        priority: Priority.max,
        ticker: 'ticker',
        actions: [
          AndroidNotificationAction(_acceptId, "Принять", showsUserInterface: true),
          AndroidNotificationAction(_denyId, "Отклонить", showsUserInterface: true),
          AndroidNotificationAction(_blockId, "Заблокировать", showsUserInterface: true),
        ]);
    const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);
    int notificationId = int.parse(anotherDeviceInfo.id.replaceAll(RegExp(r'\D'), "").substring(10));
    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      "Запрос на сопряжение",
      "Устройство ${anotherDeviceInfo.name} хочет установить сопряжение",
      notificationDetails,
      payload: anotherDeviceInfo.toJsonString(),
    );
  }

  static Future<NotificationFile> createFileNotification(
      {required String deviceName, required FileMessage fileInfo}) async {
    AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails('file', 'file uploading',
        channelDescription: 'show user the uploading of the files',
        category: AndroidNotificationCategory.progress,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        ticker: 'ticker',
        showProgress: true,
        onlyAlertOnce: true,
        maxProgress: fileInfo.fileSize,
        actions: [
          const AndroidNotificationAction(_denyId, "Отменить передачу", showsUserInterface: true),
        ]);
    NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);
    int notificationId = Random().nextInt(1000000);
    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      "$deviceName передает файл",
      fileInfo.filename,
      notificationDetails,
    );
    return NotificationFile(fileInfo: fileInfo, notificationId: notificationId, deviceName: deviceName);
  }

  static Future<void> updateFileNotification({required int progress, required NotificationFile notificationFile}) async {
    AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails('file', 'file uploading',
        channelDescription: 'show user the uploading of the files',
        category: AndroidNotificationCategory.progress,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        ticker: 'ticker',
        showProgress: true,
        onlyAlertOnce: true,
        progress: progress,
        maxProgress: notificationFile.fileInfo.fileSize,
        actions: [
          const AndroidNotificationAction(_denyId, "Отменить передачу", showsUserInterface: true),
        ]);
    NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);
    String progressFileSize = FileUtils.getFileSizeString(bytes: progress);
    String totalFileSize = FileUtils.getFileSizeString(bytes: notificationFile.fileInfo.fileSize);
    await _flutterLocalNotificationsPlugin.show(
      notificationFile.notificationId,
      "${notificationFile.deviceName} передает файл",
      "${notificationFile.fileInfo.filename} $progressFileSize/$totalFileSize",
      notificationDetails,
    );
  }


  static Future<void> deleteNotification(int notificationId) async {
    await _flutterLocalNotificationsPlugin.cancel(notificationId);
  }

  static void _onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) {
    return;
  }

  static void _onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      FLog.debug(text: "notification action ${notificationResponse.actionId}, payload: $payload");
      DeviceInfo deviceInfo = DeviceInfo.fromJsonString(payload);

      switch (notificationResponse.actionId) {
        case _acceptId:
          onPairingAccepted?.call(deviceInfo);
          break;
        case _denyId:
          onPairingDenied?.call(deviceInfo);
          break;
        case _blockId:
          onPairingBlocked?.call(deviceInfo);
          break;
        default:
          onNotificationClicked?.call(deviceInfo);
          break;
      }
    }
  }
}
