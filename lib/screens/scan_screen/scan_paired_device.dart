
import 'package:eunnect/models/device_info.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'scan_paired_device.freezed.dart';

@Freezed()
class ScanPairedDevice with _$ScanPairedDevice {
  const factory ScanPairedDevice({@Default(false) bool available, required DeviceInfo deviceInfo}) = _ScanPairedDevice;
}