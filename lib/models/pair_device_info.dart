import 'dart:convert';

import 'device_info.dart';

const _senderIdField = "sender_id";
const _deviceInfoField = "device_info";
const _receiverIdField = "receiver_id";

//todo: inherit DeviceInfo.
class PairDeviceInfo {
  final String senderId;
  final String? receiverId;
  final DeviceInfo deviceInfo;

  PairDeviceInfo({required this.senderId, required this.deviceInfo, this.receiverId});

  static List<PairDeviceInfo> fromListJson(String listJson) {
    Iterable list = jsonDecode(listJson);

    return List.from(list.map((e) => PairDeviceInfo.fromJsonString(e)));
  }

  factory PairDeviceInfo.fromJsonString(String jsonString) {
    Map<String, dynamic> json = jsonDecode(jsonString);
    return PairDeviceInfo(
        senderId: json[_senderIdField],
        receiverId: json[_receiverIdField],
        deviceInfo: DeviceInfo.fromJsonString(json[_deviceInfoField]));
  }

  String toJsonString() => jsonEncode({
        _senderIdField: senderId,
        if (receiverId != null) _receiverIdField: receiverId,
        _deviceInfoField: deviceInfo.toJsonString(),
      });

 @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;

    other as PairDeviceInfo;
    return deviceInfo.id == other.deviceInfo.id;
  }
  @override
  int get hashCode => deviceInfo.id.hashCode;


}
