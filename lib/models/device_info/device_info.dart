import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import 'device_type.dart';

const _idField = "id";
const _nameField = "name";
const _deviceTypeField = "type";
const _ipAddressField = "ip";


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
        type = DeviceTypeConverter.fromString(json[_deviceTypeField]),
        ipAddress = json[_ipAddressField];

  String toJsonString() => jsonEncode({
        _idField: id,
        _nameField: name,
        _deviceTypeField: DeviceTypeConverter.fromType(type),
        _ipAddressField: ipAddress,
      });

  Map<String, Uint8List> toNsdJson() => {
    _idField : utf8.encode(id),
    _nameField: utf8.encode(name),
    _deviceTypeField: utf8.encode(DeviceTypeConverter.fromType(type)),
    _ipAddressField: utf8.encode(ipAddress),
  };

  DeviceInfo.fromNsdJson(Map<String, Uint8List?> json) :
      id = utf8.decode(json[_idField]!),
        name = utf8.decode(json[_nameField]!),
        type = DeviceTypeConverter.fromString(utf8.decode(json[_deviceTypeField]!)),
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

  @override
  List<Object?> get props => [name, type, ipAddress, id];
}