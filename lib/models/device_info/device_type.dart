const windowsDeviceType = "windows";
const linuxDeviceType = "linux";
const phoneDeviceType = "phone";
const tabletDeviceType = "tablet";

enum DeviceType { windows, linux, phone, tablet, unknown }

abstract class DeviceTypeConverter {

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
}

