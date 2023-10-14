part of 'scan_bloc.dart';

abstract class DeviceScanState extends Equatable {
  const DeviceScanState();

  LoadedState get loadedState => this is! LoadedState ? const LoadedState() : this as LoadedState;

  @override
  List<Object?> get props => [];
}

class PairDialogState extends DeviceScanState {
  final PairDeviceInfo pairDeviceInfo;

  const PairDialogState({required this.pairDeviceInfo});

  @override
  List<Object?> get props => [pairDeviceInfo];
}

class ErrorState extends DeviceScanState {
  final String error;

  const ErrorState({required this.error});

  @override
  List<Object?> get props => [error];
}

class SuccessState extends DeviceScanState {
  final String message;

  const SuccessState({required this.message});

  @override
  List<Object?> get props => [message];
}

class MoveState extends DeviceScanState {
  final PairDeviceInfo pairDeviceInfo;

  const MoveState({required this.pairDeviceInfo});
}

class LoadedState extends DeviceScanState {
  final bool loading;
  final List<DeviceInfo> devices;
  final String loadingDots;
  final List<PairDeviceInfo> pairedDevices;
  final List<int>? fileBytes;

  const LoadedState(
      {this.loading = false,
      this.devices = const [],
      this.loadingDots = "",
      this.pairedDevices = const [],
      this.fileBytes,});

  LoadedState copyWith({
    List<DeviceInfo>? devices,
    bool? loading,
    String? loadingDots,
    List<PairDeviceInfo>? pairedDevices,
    List<int>? fileBytes,
  }) =>
      LoadedState(
        loading: loading ?? this.loading,
        devices: devices ?? this.devices,
        loadingDots: loadingDots ?? this.loadingDots,
        pairedDevices: pairedDevices ?? this.pairedDevices,
        fileBytes: fileBytes ?? this.fileBytes,
      );

  @override
  List<Object?> get props => [loading, devices, loadingDots, pairedDevices,fileBytes];
}
