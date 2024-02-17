import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:eunnect/models/socket/custom_server_socket.dart';
import 'package:eunnect/repo/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../blocs/main_bloc/main_bloc.dart';
import '../blocs/scan_bloc/scan_bloc.dart';
import '../models/device_info.dart';

abstract class GetItHelper {
  static final GetIt i = GetIt.I;

  static Future<void> registerAll() async {
    await _registerStorage();
    await _registerSockets();
    await _registerBlocs();
    await registerDeviceInfo();
    i<MainBloc>().initNetworkListener();
  }

  static Future<void> registerDeviceInfo() async {
    if (i.isRegistered<DeviceInfo>()) await i.unregister<DeviceInfo>();

    DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
    String deviceId = i<LocalStorage>().getDeviceId();

    String name;
    DeviceType type;

    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfoPlugin.androidInfo;

      type = MediaQueryData.fromView(WidgetsBinding.instance.window).size.shortestSide < 550 ? DeviceType.phone : DeviceType.tablet;
      name = androidInfo.model;
    } else if (Platform.isWindows) {
      final windowsInfo = await _deviceInfoPlugin.windowsInfo;

      type = DeviceType.windows;
      name = windowsInfo.computerName;
    } else if (Platform.isLinux) {
      final linuxInfo = await _deviceInfoPlugin.linuxInfo;

      type = DeviceType.linux;
      name = linuxInfo.name;
    } else {
      type = DeviceType.unknown;
      name = "Unknown";
    }

    DeviceInfo deviceInfo = DeviceInfo(name: name, type: type, id: deviceId);

    i.registerSingleton<DeviceInfo>(deviceInfo);
  }

  static Future<void> _registerStorage() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    if (i.isRegistered<LocalStorage>()) await i.unregister<LocalStorage>();
    LocalStorage storage = LocalStorage(preferences: sharedPreferences, secureStorage: const FlutterSecureStorage());
    i.registerSingleton<LocalStorage>(storage);
  }

  static Future<void> _registerSockets() async {
    if (i.isRegistered<CustomServerSocket>()) await i.unregister<CustomServerSocket>();
    CustomServerSocket customServerSocket = CustomServerSocket(storage: i<LocalStorage>());
    i.registerSingleton<CustomServerSocket>(customServerSocket);
  }

  static Future<void> _registerBlocs() async {
    if (i.isRegistered<MainBloc>()) await i.unregister<MainBloc>();
    MainBloc mainBloc = MainBloc();
    i.registerSingleton<MainBloc>(mainBloc);
    await mainBloc.checkFirstLaunch();

    if (i.isRegistered<ScanBloc>()) await i.unregister<ScanBloc>();
    ScanBloc scanBloc = ScanBloc();
    i.registerSingleton<ScanBloc>(scanBloc);
  }
}
