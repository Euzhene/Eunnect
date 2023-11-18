import 'package:eunnect/models/device_info.dart';

class ScanPairedDevice extends DeviceInfo {
  final bool available;

  const ScanPairedDevice(
      {required this.available, required super.name, required super.deviceType, required super.ipAddress, required super.id});

  ScanPairedDevice scanCopyWith({bool? available}) =>
      ScanPairedDevice(available: available ?? this.available, name: name, deviceType: deviceType, ipAddress: ipAddress, id: id);

  factory ScanPairedDevice.fromDeviceInfo(DeviceInfo deviceInfo, [bool available = false]) {
    return ScanPairedDevice(
        available: available,
        name: deviceInfo.name,
        deviceType: deviceInfo.deviceType,
        ipAddress: deviceInfo.ipAddress,
        id: deviceInfo.id);
  }

  @override
  List<Object?> get props => [...super.props, available];
}
