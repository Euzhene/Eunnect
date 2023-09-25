import 'dart:convert';

import 'package:equatable/equatable.dart';

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

  String toJsonString() {
    Map<String, dynamic> json = {_nameField: name, _platformField: platform};
    return jsonEncode(json);
  }

  @override
  List<Object?> get props => [name, platform];
}
