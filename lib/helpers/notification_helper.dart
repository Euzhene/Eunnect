import 'package:eunnect/models/device_info/device_info.dart';
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
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails('Makuku', 'pairing',
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

  static void _onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) {
    return;
  }

  static void _onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      FLog.debug(text: "notification action ${notificationResponse.actionId}, payload: $payload");
      DeviceInfo deviceInfo = DeviceInfo.fromJsonString(payload);

      switch(notificationResponse.actionId) {
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
