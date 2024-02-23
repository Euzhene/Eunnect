import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

const _idField = "id";
const _nameField = "name";
const _deviceTypeField = "type";
const _ipAddressField = "ip";

const windowsDeviceType = "windows";
const linuxDeviceType = "linux";
const phoneDeviceType = "phone";
const tabletDeviceType = "tablet";

enum DeviceType { windows, linux, phone, tablet, unknown }

class DeviceInfo extends Equatable {
  final String id;
  final String name;
  final DeviceType type;
  final String ipAddress;

  const DeviceInfo({
    required this.name,
    required this.type,
    this.ipAddress = "",
    required this.id,
  });

  DeviceInfo copyWith({String? ipAddress, String? name}) => DeviceInfo(name: name ?? this.name, type: type, ipAddress: ipAddress ?? this.ipAddress, id: id);

  DeviceInfo.fromJson(Map<String, dynamic> json)
      : id = json[_idField],
        name = json[_nameField],
        type = _deviceTypeList
            .firstWhere((e) => e.typeString == json[_deviceTypeField],
            orElse: () => _DeviceTypeModel(typeEnum: DeviceType.unknown, typeString: ""))
            .typeEnum,
        ipAddress = json[_ipAddressField];

  String toJsonString() => jsonEncode({
        _idField: id,
        _nameField: name,
        _deviceTypeField: _deviceTypeList.firstWhere((e) => e.typeEnum==type).typeString,
        _ipAddressField: ipAddress,
      });

  Map<String, Uint8List> toNsdJson() => {
    _idField : utf8.encode(id),
    _nameField: utf8.encode(name),
    _deviceTypeField: utf8.encode(_deviceTypeList.firstWhere((e) => e.typeEnum==type).typeString),
    _ipAddressField: utf8.encode(ipAddress),
  };

  DeviceInfo.fromNsdJson(Map<String, Uint8List?> json) :
      id = utf8.decode(json[_idField]!),
        name = utf8.decode(json[_nameField]!),
        type = _deviceTypeList
            .firstWhere((e) => e.typeString == utf8.decode(json[_deviceTypeField]!),
            orElse: () => _DeviceTypeModel(typeEnum: DeviceType.unknown, typeString: ""))
            .typeEnum,
        ipAddress = utf8.decode(json[_ipAddressField]!);

  factory DeviceInfo.fromJsonString(String jsonString) {
    Map<String, dynamic> json = jsonDecode(jsonString);
    return DeviceInfo.fromJson(json);
  }

  factory DeviceInfo.fromUInt8List(Uint8List data) => DeviceInfo.fromJsonString(utf8.decode(data));

  static List<DeviceInfo> fromJsonList(String listJson) {
    Iterable list = jsonDecode(listJson);
    return List.from(list.map((e) => DeviceInfo.fromJsonString(e)));
  }

  static final List<_DeviceTypeModel> _deviceTypeList = [
    _DeviceTypeModel(typeEnum: DeviceType.tablet, typeString: tabletDeviceType),
    _DeviceTypeModel(typeEnum: DeviceType.phone, typeString: phoneDeviceType),
    _DeviceTypeModel(typeEnum: DeviceType.windows, typeString: windowsDeviceType),
    _DeviceTypeModel(typeEnum: DeviceType.linux, typeString: linuxDeviceType),
  ];

  @override
  List<Object?> get props => [name, type, ipAddress, id];
}

class _DeviceTypeModel {
  String typeString;
  DeviceType typeEnum;

  _DeviceTypeModel({required this.typeEnum, required this.typeString});
}
