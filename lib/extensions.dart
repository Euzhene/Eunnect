
import 'package:eunnect/models/device_info/device_info.dart';

extension DeviceInfoList<T extends DeviceInfo> on List<T> {
  bool containsSameDeviceId(DeviceInfo deviceInfo) {
    return findIndexWithDeviceId(deviceInfo) >= 0;
  }

  int findIndexWithDeviceId(DeviceInfo deviceInfo) {
    return indexWhere((d) => d.id == deviceInfo.id);
  }

  T? findWithDeviceId(DeviceInfo deviceInfo) {
    return where((d) => d.id == deviceInfo.id).firstOrNull;
  }

  void removeWithDeviceId(DeviceInfo deviceInfo) {
    return removeWhere((d) => d.id == deviceInfo.id);
  }

  bool updateWithDeviceId(T deviceInfo) {
    int index = findIndexWithDeviceId(deviceInfo);
    if (index < 0) return false;
    this[index] = deviceInfo;
    return true;
  }
}