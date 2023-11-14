import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

const _idField = "id";
const _nameField = "name";
const _deviceTypeField = "deviceType";
const _ipAddressField = "ip_address";

const windowsDeviceType = "windows";
const linuxDeviceType = "linux";
const phoneDeviceType = "phone";
const tabletDeviceType = "tablet";

class DeviceInfo extends Equatable {
  final String id;
  final String name;
  final String deviceType;
  final String ipAddress;

  const DeviceInfo({
    required this.name,
    required this.deviceType,
    required this.ipAddress,
    required this.id,
  });

  DeviceInfo.fromJson(Map<String, dynamic> json)
      : id = json[_idField],
        name = json[_nameField],
        deviceType = json[_deviceTypeField],
        ipAddress = json[_ipAddressField];

  String toJsonString() => jsonEncode({
        _idField: id,
        _nameField: name,
        _deviceTypeField: deviceType,
        _ipAddressField: ipAddress,
      });

  factory DeviceInfo.fromJsonString(String jsonString) {
    Map<String, dynamic> json = jsonDecode(jsonString);
    return DeviceInfo(
        id: json[_idField], name: json[_nameField], deviceType: json[_deviceTypeField], ipAddress: json[_ipAddressField]);
  }

  factory DeviceInfo.fromUInt8List(Uint8List data) => DeviceInfo.fromJsonString(utf8.decode(data));

  static List<DeviceInfo> fromJsonList(String listJson) {
    Iterable list = jsonDecode(listJson);
    return List.from(list.map((e) => DeviceInfo.fromJsonString(e)));
  }

  @override
  List<Object?> get props => [name, deviceType, ipAddress, id];
}
