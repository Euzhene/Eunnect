import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

const windowsDeviceType = "windows";
const linuxDeviceType = "linux";
const phoneDeviceType = "phone";
const tabletDeviceType = "tablet";

enum DeviceType { windows, linux, phone, tablet, unknown }

abstract class DeviceTypeConverter {

  static List<DeviceType> fromList(List? typeList) {
    if (typeList == null) return [];
    return typeList.map((e) => fromString(e)).toList();
  }
  static DeviceType fromString(String type) {
    switch(type) {
      case windowsDeviceType:
        return DeviceType.windows;
      case linuxDeviceType:
        return DeviceType.linux;
      case phoneDeviceType:
        return DeviceType.phone;
      case tabletDeviceType:
        return DeviceType.tablet;
      default:
        return DeviceType.unknown;
    }
  }
  static String fromType(DeviceType type) {
    switch(type) {
      case DeviceType.windows:
        return windowsDeviceType;
      case DeviceType.linux:
        return linuxDeviceType;
      case DeviceType.phone:
        return phoneDeviceType;
      case DeviceType.tablet:
        return tabletDeviceType;
      default:
        throw UnimplementedError();
    }
  }

  static IconData iconFromType(DeviceType type) {
    switch (type) {
      case DeviceType.windows:
        return FontAwesomeIcons.windows;
      case DeviceType.linux:
        return FontAwesomeIcons.linux;
      case DeviceType.phone:
        return Icons.phone_android;
      case DeviceType.tablet:
        return Icons.tablet_mac_sharp;
      default:
        return Icons.question_mark;
    }
  }
}

