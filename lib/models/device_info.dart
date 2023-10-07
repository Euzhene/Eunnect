import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

const _nameField = "name";
const _platformField = "platform";

const windowsPlatform = "windows";
const androidPlatform = "android";

class DeviceInfo extends Equatable {
  final String name;
  final String platform;

  const DeviceInfo({required this.name, required this.platform});

  DeviceInfo.fromJson(Map<String, dynamic> json)
      : name = json[_nameField],
        platform = json[_platformField];

  String toJsonString() => jsonEncode({_nameField: name, _platformField: platform});

  factory DeviceInfo.fromJsonString(String jsonString) {
    Map<String, dynamic> json = jsonDecode(jsonString);
    return DeviceInfo(name: json[_nameField], platform: json[_platformField]);
  }

  factory DeviceInfo.fromUInt8List(Uint8List data) =>DeviceInfo.fromJsonString(utf8.decode(data));

  @override
  List<Object?> get props => [name, platform];
}
