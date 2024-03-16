import 'dart:io';

import 'package:eunnect/helpers/rtc_helper.dart';
import 'package:eunnect/helpers/ssl_helper.dart';
import 'package:eunnect/models/socket/custom_client_socket.dart';
import 'package:eunnect/models/socket/custom_server_socket.dart';
import 'package:eunnect/network/custom_nsd.dart';
import 'package:eunnect/repo/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../blocs/main_bloc/main_bloc.dart';
import '../blocs/scan_bloc/scan_bloc.dart';
import '../constants.dart';
import '../models/device_info/device_info.dart';
import '../models/device_info/device_type.dart';

abstract class GetItHelper {
  static final GetIt i = GetIt.I;

  static Future<void> registerAll() async {
    await _registerStorage();
    await registerDeviceInfo();
    await _registerHelpers();
    await _registerSockets();
    await _registerBlocs();
    i<MainBloc>().initNetworkListener();
  }

  static Future<void> registerDeviceInfo() async {
    String deviceId = await i<LocalStorage>().getDeviceId();

    String name = await i<LocalStorage>().getDeviceName();
    DeviceType type;

    if (isMobile)
      type = MediaQueryData.fromView(WidgetsBinding.instance.window).size.shortestSide < 550 ? DeviceType.phone : DeviceType.tablet;
     else if (Platform.isWindows) type = DeviceType.windows;
     else if (Platform.isLinux) type = DeviceType.linux;
     else type = DeviceType.unknown;

    DeviceInfo deviceInfo = DeviceInfo(name: name, type: type, id: deviceId);
    await _customRegister(deviceInfo);
  }

  static Future<void> _registerStorage() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    LocalStorage storage = LocalStorage(preferences: sharedPreferences, secureStorage: const FlutterSecureStorage());
    await _customRegister(storage);
  }

  static Future<void> _registerSockets() async {
    CustomServerSocket customServerSocket = CustomServerSocket(storage: i<LocalStorage>(), sslHelper: i<SslHelper>());
    await _customRegister(customServerSocket);
    CustomClientSocket customClientSocket = CustomClientSocket(myDeviceInfo: GetItHelper.i<DeviceInfo>(), storage: GetItHelper.i<LocalStorage>());
    await _customRegister(customClientSocket);
  }

  static Future<void> _registerBlocs() async {
    MainBloc mainBloc = MainBloc();
    await _customRegister(mainBloc);
    await mainBloc.checkFirstLaunch();

    ScanBloc scanBloc = ScanBloc();
    await _customRegister(scanBloc);
  }

  static Future<void> _registerHelpers() async {
    CustomNsd customNsd = CustomNsd();
    await _customRegister(customNsd);

    SslHelper sslHelper = SslHelper(i<LocalStorage>());
    await _customRegister(sslHelper);

    RtcHelper rtcHelper = RtcHelper(sslHelper);
    await _customRegister(rtcHelper);
  }

  static Future<T> _customRegister<T extends Object>(T value) async {
    if (i.isRegistered<T>()) await i.unregister<T>();
    return i.registerSingleton<T>(value);
  }
}
