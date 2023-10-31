import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:eunnect/models/device_info.dart';
import 'package:eunnect/repo/local_storage.dart';
import 'package:f_logs/f_logs.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../helpers/get_it_helper.dart';
import '../../models/custom_server_socket.dart';

part 'main_state.dart';

class MainBloc extends Cubit<MainState> {
  final LocalStorage _storage = LocalStorage();
  final DeviceInfo _myDeviceInfo = GetItHelper.i<DeviceInfo>();


  MainBloc() : super(MainState());

  Future<void> checkFirstLaunch() async {

    try {
      if (!_storage.isFirstLaunch()) return;

      await _storage.clearAll();
      await _storage.setSecretKey();
      await _storage.setDeviceId();
      await _storage.setFirstLaunch();

    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      emit(ErrorMainState(error: "Критическая ошибка при чтении из БД. Обратитесь в службу поддержки"));
    }
  }

  Future<void> startServer() async {
    await CustomServerSocket.initServer(_myDeviceInfo.ipAddress);
    CustomServerSocket.onPairDeviceCall = (DeviceInfo deviceInfo) {
      emit(PairDialogState(deviceInfo: deviceInfo));
      emit(MainState());
    };

    CustomServerSocket.start();
  }

  Future<void> onPairConfirmed(DeviceInfo? pairDeviceInfo) async {
    try {
      if (pairDeviceInfo == null) CustomServerSocket.pairStream.sink.add(null);
      else CustomServerSocket.pairStream.sink.add(pairDeviceInfo);

      await CustomServerSocket.pairStream.close();
      if (pairDeviceInfo != null) {
        await _storage.addPairedDevice(pairDeviceInfo);
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

}
