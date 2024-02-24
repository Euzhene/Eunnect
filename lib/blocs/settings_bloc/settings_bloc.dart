import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:eunnect/helpers/get_it_helper.dart';
import 'package:eunnect/helpers/log_helper.dart';
import 'package:eunnect/models/device_info.dart';
import 'package:eunnect/repo/local_storage.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../main_bloc/main_bloc.dart';

part 'settings_state.dart';

class SettingsBloc extends Cubit<SettingsState> {
  final LocalStorage _storage = GetItHelper.i<LocalStorage>();
  final MainBloc _mainBloc = GetItHelper.i<MainBloc>();
  final TextEditingController deviceNameController = TextEditingController();

  DeviceInfo get deviceInfo => GetItHelper.i<DeviceInfo>();
  late PackageInfo packageInfo;
  late bool isDarkTheme;
  late String? coreDeviceModel;
  late String? coreDeviceAdditionalInfo;
  List<DeviceInfo> blockedDevices = [];

  SettingsBloc() : super(LoadingScreenState()) {
    deviceNameController.addListener(() {
      if (!state.isAnyLoading) emit(SettingsState());
    });
    _onLoadSettings();
  }

  bool get isDeviceNameValid {
    String newDeviceName = deviceNameController.text.trim();
    return newDeviceName.isNotEmpty && newDeviceName != deviceInfo.name;
  }

  Future<void> _onLoadSettings() async {
    try {
      emit(LoadingScreenState());
      deviceNameController.text = deviceInfo.name;
      isDarkTheme = _storage.isDarkTheme();
      packageInfo = await PackageInfo.fromPlatform();
      await _setCoreDeviceInfo();
      blockedDevices = await _storage.getBlockedDevices();
      emit(SettingsState());
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      _mainBloc.emitDefaultError(e.toString());
    }
  }

  Future<void> onUpdateDeviceName() async {
    try {
      emit(DeviceNameLoadingState());
      String newDeviceName = deviceNameController.text.trim();
      if (!isDeviceNameValid) return;
      DeviceInfo updatedDeviceInfo = deviceInfo.copyWith(name: newDeviceName);

      _storage.setDeviceName(updatedDeviceInfo.name);
      await GetItHelper.i.unregister<DeviceInfo>();
      GetItHelper.i.registerSingleton<DeviceInfo>(updatedDeviceInfo);

      deviceNameController.text = deviceInfo.name;
      emit(SettingsState());
      _mainBloc.emitDefaultSuccess("Имя устройства обновлено");
      _mainBloc.resetNetworkSettings();
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      _mainBloc.emitDefaultError(e.toString());
    }
  }

  Future<void> onResetSettings() async {
    try {
      await _storage.setFirstLaunch(true);
      await _mainBloc.checkFirstLaunch();
      await GetItHelper.registerDeviceInfo();
      await _onLoadSettings();
      _mainBloc.emitDefaultSuccess("Настройки сброшены");
      _mainBloc.resetNetworkSettings();
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      _mainBloc.emitDefaultError(e.toString());
    }
  }

  Future<void> onSendLogs() async {
    await LogHelper.export(
      onEmptyLogs: () => _mainBloc.emitDefaultSuccess("Лог пуст!"),
      onError: (e) => _mainBloc.emitDefaultError(e),
    );
  }

  Future<void> onDarkThemeValueChangeRequested() async {
    try {
      isDarkTheme = !isDarkTheme;
      await _storage.setIsDarkTheme(isDarkTheme);
      emit(SettingsState());
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      _mainBloc.emitDefaultError(e.toString());
    }
  }

  Future<void> onDeleteBlockedDevice(DeviceInfo deviceInfo) async {
    try {
      await _storage.deleteBlockedDevice(deviceInfo);
      blockedDevices = await _storage.getBlockedDevices();
      emit(SettingsState());
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      _mainBloc.emitDefaultError(e.toString());
    }
  }

  Future<void> _setCoreDeviceInfo() async {
    DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      coreDeviceModel = androidInfo.model;
      coreDeviceAdditionalInfo = "Android${androidInfo.version.release}";
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfoPlugin.iosInfo;
      coreDeviceModel = iosInfo.model;
      coreDeviceAdditionalInfo = iosInfo.systemVersion;
    } else if (Platform.isWindows) {
      final windowsInfo = await _deviceInfoPlugin.windowsInfo;
      coreDeviceModel = windowsInfo.productName;
      coreDeviceAdditionalInfo = "Build${windowsInfo.buildNumber}";
    } else if (Platform.isLinux) {
      final linuxInfo = await _deviceInfoPlugin.linuxInfo;
      coreDeviceModel = linuxInfo.name;
      coreDeviceAdditionalInfo = linuxInfo.versionId;
    }
  }
}
