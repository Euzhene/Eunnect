import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/device_info.dart';

part 'scan_state.freezed.dart';

@Freezed()
class ScanState with _$ScanState {
  const factory ScanState({
    @Default({}) Set<DeviceInfo> foundDevices,
    @Default({}) Set<DeviceInfo> pairedDevices,
  }) = _ScanState;
}
