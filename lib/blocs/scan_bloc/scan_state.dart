

import 'package:eunnect/models/device_info/device_info.dart';
import 'package:eunnect/screens/scan_screen/scan_paired_device.dart';

class ScanState {}

class MoveToLastOpenDeviceState extends ScanState {
  final ScanPairedDevice device;

  MoveToLastOpenDeviceState(this.device);
}

class AwaitPairingDeviceState extends ScanState {
  final DeviceInfo? deviceInfo;

  AwaitPairingDeviceState(this.deviceInfo);
}
