
import 'package:eunnect/models/device_info.dart';

extension DeviceInfoList<T extends DeviceInfo> on List<T> {
  bool containsSameDeviceId(DeviceInfo deviceInfo) {
    return findIndexWithSameDeviceId(deviceInfo) >= 0;
  }

  int findIndexWithSameDeviceId(DeviceInfo deviceInfo) {
    return indexWhere((d) => d.id == deviceInfo.id);
  }

  T? findWithSameDeviceId(DeviceInfo deviceInfo) {
    return where((d) => d.id == deviceInfo.id).firstOrNull;
  }
}