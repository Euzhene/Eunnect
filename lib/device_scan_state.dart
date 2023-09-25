part of 'device_scan_bloc.dart';

class DeviceScanState extends Equatable {
  final bool loading;
  final List<DeviceInfo>? devices;
  final String loadingDots;

  List<DeviceInfo> get devicesNvl => devices ?? [];

  const DeviceScanState({this.loading = false, this.devices, this.loadingDots = ""});

  DeviceScanState copyWith({
    List<DeviceInfo>? devices,
    bool? loading,
    String? loadingDots,
  }) =>
      DeviceScanState(
          loading: loading ?? this.loading, devices: devices ?? this.devices, loadingDots: loadingDots ?? this.loadingDots);

  @override
  List<Object?> get props => [loading, devices, loadingDots];
}
