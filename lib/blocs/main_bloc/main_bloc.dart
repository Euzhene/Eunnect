import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:eunnect/blocs/scan_bloc/scan_bloc.dart';
import 'package:eunnect/models/device_info.dart';
import 'package:eunnect/repo/local_storage.dart';
import 'package:f_logs/f_logs.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../helpers/get_it_helper.dart';
import '../../models/custom_message.dart';
import '../../models/socket/custom_server_socket.dart';

part 'main_state.dart';

class MainBloc extends Cubit<MainState> {
  final LocalStorage _storage = GetItHelper.i<LocalStorage>();

  late Function(DeviceInfo) onPairedDeviceChanged;
  bool hasConnection = false;

  MainBloc() : super(MainState());

  void initNetworkListener() {
    ScanBloc _scanBloc = GetItHelper.i<ScanBloc>();
    Connectivity().onConnectivityChanged.listen((event) async {
      try {
        bool prevConnectionState = hasConnection;
        hasConnection =
            event == ConnectivityResult.ethernet || event == ConnectivityResult.mobile || event == ConnectivityResult.wifi;
        if (hasConnection && hasConnection != prevConnectionState) {
          await updateDeviceInfo();
          await startServer();
          _scanBloc.onScanDevices();
        }
        emit(MainState());
      }catch(e,st) {
        FLog.error(text: e.toString(),stacktrace: st);
      }
    });
  }

  Future<void> checkFirstLaunch() async {
    try {
      if (!_storage.isFirstLaunch()) return;

      await _storage.clearAll();
      await _storage.setDeviceId();
      await _storage.setFirstLaunch();
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      emit(ErrorMainState(error: "Критическая ошибка при чтении из БД. Обратитесь в службу поддержки"));
    }
  }

  Future<void> startServer() async {
    String? myIp = GetItHelper.i<DeviceInfo>().ipAddress;
    if (myIp.isEmpty) return;

    await CustomServerSocket.initServer(myIp);
    CustomServerSocket.onPairDeviceCall = (DeviceInfo deviceInfo) {
      emit(PairDialogState(deviceInfo: deviceInfo));
      emit(MainState());
    };

    CustomServerSocket.onBufferCall = (text) async {
      await Clipboard.setData(ClipboardData(text: text));
      emitDefaultSuccess("Передан текст в буфер");
    };

    CustomServerSocket.onFileCall = (FileMessage message) async {
      Directory? docDir;
      try {
        if (!Platform.isAndroid) {
          docDir = await getApplicationDocumentsDirectory();
          if (!docDir.path.endsWith(Platform.pathSeparator)) docDir = Directory(docDir.path + Platform.pathSeparator);
        } else {
          docDir = Directory("/storage/emulated/0/Download/");

          if (!await docDir.exists()) {
            docDir = Directory("/storage/emulated/0/Downloads/");
          }
        }

        File file = File("${docDir.path}${message.filename}");
        await file.writeAsBytes(message.bytes);
        emitDefaultSuccess("Файл ${message.filename} успешно передан и сохранен в ${docDir.path}");
      } catch (e, st) {
        FLog.error(text: e.toString(), stacktrace: st);
        String error;
        if (e is FileSystemException)
          error = "Ошибка сохранения файла в ${docDir?.path ?? "неизвестный путь"}";
        else
          error = "Внутреняя ошибка";

        emitDefaultError(error);
      }
    };

    CustomServerSocket.start();
  }

  Future<void> onPairConfirmed(DeviceInfo? pairDeviceInfo) async {
    try {
      if (pairDeviceInfo == null)
        CustomServerSocket.pairStream.sink.add(null);
      else
        CustomServerSocket.pairStream.sink.add(pairDeviceInfo);

      await CustomServerSocket.pairStream.close();
      if (pairDeviceInfo != null) {
        await _storage.addPairedDevice(pairDeviceInfo);
        onPairedDeviceChanged(pairDeviceInfo);
        emitDefaultSuccess("Успешно сопряжено");
      }
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      emitDefaultError(e.toString());
    }
  }

  void emitDefaultError(String error) {
    emit(ErrorMainState(error: error));
    emit(MainState());
  }

  void emitDefaultSuccess(String message) {
    emit(SuccessMainState(message: message));
    emit(MainState());
  }

  Future<void> updateDeviceInfo() async {

    DeviceInfo deviceInfo= GetItHelper.i<DeviceInfo>();
    String deviceIp = (await NetworkInfo().getWifiIP()) ?? "";
    deviceInfo = deviceInfo.copyWith(ipAddress: deviceIp);

    await GetItHelper.i.unregister<DeviceInfo>();
    GetItHelper.i.registerSingleton<DeviceInfo>(deviceInfo);
  }
}
