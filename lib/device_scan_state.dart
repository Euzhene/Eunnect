part of 'device_scan_bloc.dart';

class DeviceScanState extends Equatable {
  final bool loading;
  final List<DeviceInfo>? devices;

  List<DeviceInfo> get devicesNvl => devices ?? [];

  const DeviceScanState({this.loading = false, this.devices});

  DeviceScanState copyWith({List<DeviceInfo>? devices, bool? loading}) =>
      DeviceScanState(loading: loading ?? this.loading, devices: devices ?? this.devices);

  @override
  List<Object?> get props => [loading, devices];
}
