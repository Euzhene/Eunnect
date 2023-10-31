import 'package:eunnect/screens/scan_screen/scan_paired_device.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/device_info.dart';

part 'scan_state.freezed.dart';

@Freezed()
class ScanState with _$ScanState {
  const factory ScanState({
    @Default({}) Set<DeviceInfo> foundDevices,
    @Default({}) Set<ScanPairedDevice> pairedDevices,
  }) = _ScanState;
}
