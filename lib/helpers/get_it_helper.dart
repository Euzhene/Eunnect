import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:eunnect/repo/local_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../blocs/main_bloc/main_bloc.dart';
import '../models/device_info.dart';

abstract class GetItHelper {
  static final GetIt i = GetIt.I;

  static Future<void> registerAll() async {
    await _registerSharedPreferences();
    await _registerMainBloc();
    await _registerDeviceInfo();
  }

  static Future<void> _registerDeviceInfo() async {
    if (i.isRegistered<DeviceInfo>()) await i.unregister<DeviceInfo>();

    DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
    String deviceId = LocalStorage().getDeviceId();

    DeviceInfo deviceInfo;
    String deviceIp = (await NetworkInfo().getWifiIP())!;

    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      deviceInfo = DeviceInfo(name: androidInfo.model, platform: androidPlatform, id: deviceId,ipAddress: deviceIp);
    } else if (Platform.isWindows) {
      final windowsInfo = await _deviceInfoPlugin.windowsInfo;
      deviceInfo = DeviceInfo(name: windowsInfo.computerName, platform: windowsPlatform, id: deviceId,ipAddress: deviceIp);
    } else {
      deviceInfo = DeviceInfo(name: "Unknown", platform: "Unsupported", id: deviceId,ipAddress: deviceIp);
    }

    i.registerSingleton<DeviceInfo>(deviceInfo);
  }

  static Future<void> _registerSharedPreferences() async {
    if (i.isRegistered<SharedPreferences>()) await i.unregister<SharedPreferences>();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    i.registerSingleton<SharedPreferences>(sharedPreferences);
  }

  static Future<void> _registerMainBloc() async {
    if (i.isRegistered<MainBloc>()) await i.unregister<MainBloc>();
    MainBloc mainBloc = MainBloc();
    i.registerSingleton<MainBloc>(mainBloc);
    await mainBloc.checkFirstLaunch();
  }
}
