import 'dart:convert';

import 'device_info.dart';

const _senderIdField = "sender_id";
const _deviceInfoField = "device_info";

class PairDeviceInfo {
  final String senderId;
  final DeviceInfo deviceInfo;

  PairDeviceInfo({required this.senderId, required this.deviceInfo});

  static List<PairDeviceInfo> fromListJson(String listJson) {
    Iterable list = jsonDecode(listJson);

    return List.from(list.map((e) => PairDeviceInfo.fromJsonString(e)));
  }

  factory PairDeviceInfo.fromJsonString(String jsonString) {
    Map<String, dynamic> json = jsonDecode(jsonString);
    return PairDeviceInfo(senderId: json[_senderIdField], deviceInfo: DeviceInfo.fromJsonString(json[_deviceInfoField]));
  }

  String toJsonString() => jsonEncode({
        _senderIdField: senderId,
        _deviceInfoField: deviceInfo.toJsonString(),
      });
}
