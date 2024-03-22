part of 'add_device_by_ip_bloc.dart';

class IpState {}

class AwaitPairingDeviceState extends IpState {
  final DeviceInfo? deviceInfo;

  AwaitPairingDeviceState(this.deviceInfo);
}