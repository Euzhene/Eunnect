
part of 'settings_bloc.dart';

class SettingsState {
  bool get isAnyLoading => this is LoadingScreenState || this is DeviceNameLoadingState;
}

class LoadingScreenState extends SettingsState {}

class DeviceNameLoadingState extends SettingsState {}