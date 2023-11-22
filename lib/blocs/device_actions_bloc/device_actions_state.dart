part of 'actions_bloc.dart';

class DeviceActionsState {
  bool get isSendingFile => this is SendingFileState;
  bool get isUnreachableDevice => this is UnreachableDeviceState;
}

class SendingFileState extends DeviceActionsState {}

class UnreachableDeviceState extends DeviceActionsState {}
