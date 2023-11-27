part of 'actions_bloc.dart';

class DeviceActionsState {
  bool get isLoading => this is LoadingState;
  bool get isUnreachableDevice => this is UnreachableDeviceState;
}

class LoadingState extends DeviceActionsState {}

class UnreachableDeviceState extends DeviceActionsState {}

class DeletedDeviceState extends DeviceActionsState {}
