part of 'add_device_by_qr_bloc.dart';

class QrState {}

class QrSuccess extends QrState {
  final DeviceInfo deviceInfo;

  QrSuccess(this.deviceInfo);
}