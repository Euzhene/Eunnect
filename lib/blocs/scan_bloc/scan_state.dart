

import 'package:eunnect/screens/scan_screen/scan_paired_device.dart';

class ScanState {}

class MoveToLastOpenDeviceState extends ScanState {
  final ScanPairedDevice device;

  MoveToLastOpenDeviceState(this.device);
}
