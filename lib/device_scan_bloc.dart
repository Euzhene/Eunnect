import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:equatable/equatable.dart';
import 'package:eunnect/helpers/get_it_helper.dart';
import 'package:eunnect/models/custom_message.dart';
import 'package:eunnect/models/custom_server_socket.dart';
import 'package:eunnect/models/device_info.dart';
import 'package:eunnect/models/pair_device_info.dart';
import 'package:eunnect/repo/local_storage.dart';
import 'package:f_logs/f_logs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

import 'blocs/main_bloc/main_bloc.dart';

part 'device_scan_state.dart';

class DeviceScanBloc extends Cubit<DeviceScanState> {
  final MainBloc _mainBloc = GetItHelper.i<MainBloc>();

  Isolate? _scanIsolate;
  ReceivePort? _scanPort;
  DeviceInfo _myDeviceInfo = GetItHelper.i<DeviceInfo>();
  final LocalStorage _storage = LocalStorage();

  final List<PairDeviceInfo> _pairedDevices = [];

  DeviceScanBloc() : super(const LoadedState(devices: [])) {
    _storage.getPairedDevices().then((value) {
      _pairedDevices.clear();
      _pairedDevices.addAll(value);
    });

    Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      DeviceScanState _state = state;
      if (_state is! LoadedState || !_state.loading) return;

      String loadingDots = _state.loadingDots;
      emit(_state.copyWith(loadingDots: loadingDots.length < 3 ? loadingDots += "." : ""));
    });
  }

  Future<void> onInitServer() async {
    await CustomServerSocket.initServer();
    _myDeviceInfo = _myDeviceInfo.copyWith(ipAddress: CustomServerSocket.deviceIp);
    CustomServerSocket.onDeviceInfoCall = () {
      return _myDeviceInfo;
    };

    CustomServerSocket.onBufferCall = (text) async {
      await Clipboard.setData(ClipboardData(text: text));
      _mainBloc.emitDefaultSuccess("Передан текст в буфер");
    };

    CustomServerSocket.onPairDeviceCall = (PairDeviceInfo pairDeviceInfo) async {
      CustomServerSocket.pairStream = StreamController();
      LoadedState _state = state.loadedState;
      emit(PairDialogState(pairDeviceInfo: pairDeviceInfo));
      emit(_state);
    };

    CustomServerSocket.start();
  }

  Future<void> onCancelScanRequested() async {
    _scanPort?.close();
    _scanIsolate?.kill();
    emit(state.loadedState.copyWith(loading: false));
  }

  Future<void> onScanDevicesRequested() async {
    try {
      emit(state.loadedState.copyWith(devices: [], loading: true, pairedDevices: []));
      _scanPort = ReceivePort();
      _scanIsolate = await Isolate.spawn(scan, [_scanPort!.sendPort, port, _myDeviceInfo.ipAddress]);
      _scanPort!.listen((message) {
        message as IsolateMessage;
        if (message.errorMessage != null) {
          ErrorMessage e = message.errorMessage!;
          Logger.root.info(e.shortError, e.error, e.stackTrace);
          return;
        }
        if (message.data != null) {
          DeviceInfo deviceInfo = message.data as DeviceInfo;
          LoadedState _state = state.loadedState;

          if (_pairedDevices.where((element) => element.deviceInfo.id == deviceInfo.id).isNotEmpty)
            emit(_state.copyWith(
                pairedDevices: _state.pairedDevices.toList()
                  ..add(_pairedDevices.firstWhere((element) => element.deviceInfo.id == deviceInfo.id))));
          else
            emit(_state.copyWith(devices: _state.devices.toList()..add(deviceInfo)));
        }

        if (message.done) {
          onCancelScanRequested();
        }
      });
    } catch (e, st) {
      Logger.root.info(e.toString(), e, st);
      emit(state.loadedState.copyWith(loading: false));
    }
  }

  Future<void> onPairConfirmed(PairDeviceInfo? pairDeviceInfo) async {
    try {
      if (pairDeviceInfo == null) {
        CustomServerSocket.pairStream.sink.add(null);
      } else {
        PairDeviceInfo myPairDeviceInfo = PairDeviceInfo(
            senderId: await _storage.getSecretKey(), deviceInfo: _myDeviceInfo, receiverId: pairDeviceInfo.senderId);
        CustomServerSocket.pairStream.sink.add(myPairDeviceInfo);
      }

      await CustomServerSocket.pairStream.close();
      LoadedState _state = state.loadedState;
      if (pairDeviceInfo != null) {
        List<PairDeviceInfo> pairedDevices = await _storage.addPairedDevice(pairDeviceInfo);
        emit(const SuccessState(message: "Успешно сопряжено"));
        emit(_state.copyWith(pairedDevices: pairedDevices, devices: _state.devices.toList()..remove(pairDeviceInfo.deviceInfo)));
      } else {
        emit(_state);
      }
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      _mainBloc.emitDefaultError(e.toString());
      //    emit(ErrorState(error: e.toString()));
      //  emit(_state);
    }
  }

  Future<void> onPairRequested(DeviceInfo deviceInfo) async {
    try {
      SocketMessage socketMessage =
          await compute<List, SocketMessage>(pair, [_myDeviceInfo, deviceInfo, await _storage.getSecretKey()]);

      if (socketMessage.error != null) {
        _mainBloc.emitDefaultError(socketMessage.error!);
        return;
      }

      PairDeviceInfo pairDeviceInfo = PairDeviceInfo.fromJsonString(socketMessage.data!);
      _pairedDevices.clear();
      _pairedDevices.addAll(await _storage.addPairedDevice(pairDeviceInfo));

      LoadedState _state = state.loadedState;
      emit(const SuccessState(message: "Успешно сопряжено"));

      emit(_state.copyWith(
          pairedDevices: _state.pairedDevices.toList()..add(pairDeviceInfo),
          devices: _state.devices.toList()..remove(pairDeviceInfo.deviceInfo)));
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      _mainBloc.emitDefaultError(e.toString());
    }
  }

  Future<void> onPairedDeviceChosen(PairDeviceInfo pairDeviceInfo) async {
    try {
      await (await Socket.connect(pairDeviceInfo.deviceInfo.ipAddress, port)).close(); //check we can work with another device
      LoadedState _state = state.loadedState;
      emit(MoveState(pairDeviceInfo: pairDeviceInfo));
      emit(_state);
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      LoadedState _state = state.loadedState;
      _mainBloc.emitDefaultError("Не удалось подключиться");
      //  emit(const ErrorState(error: "Не удалось подключиться"));
      emit(_state);
    }
  }
}

void scan(List<dynamic> args) async {
  SendPort sendPort = args[0];
  int port = args[1];
  String address = args[2];

  String subnet = address.substring(0, address.lastIndexOf('.'));
  int minHost = 1;
  int maxHost = 255;

  for (int i = minHost; i <= maxHost; i++) {
    try {
      String ip = "$subnet.$i";
      if (address == ip) continue;

      Socket.connect(InternetAddress("$subnet.$i", type: InternetAddressType.IPv4), port, timeout: const Duration(seconds: 2))
          .then((value) async {
        Socket socket = value;
        socket.add(SocketMessage(call: deviceInfoCall).toUInt8List());
        await socket.close();
        final bytes = await socket.single;
        SocketMessage socketMessage = SocketMessage.fromUInt8List(bytes);
        DeviceInfo deviceInfo = DeviceInfo.fromJsonString(socketMessage.data!);
        sendPort.send(IsolateMessage(data: deviceInfo));
      }, onError: (e, st) {});
    } catch (e, st) {
      sendPort.send(IsolateMessage(errorMessage: ErrorMessage(shortError: "Ошибка сканирования", error: e, stackTrace: st)));
    }
  }
  await Future.delayed(const Duration(seconds: 10));
  sendPort.send(IsolateMessage(done: true));
}

FutureOr<SocketMessage> pair(List args) async {
  DeviceInfo myDeviceInfo = args[0];
  DeviceInfo deviceInfo = args[1];
  String secretKey = args[2];
  return await Socket.connect(InternetAddress(deviceInfo.ipAddress!, type: InternetAddressType.IPv4), port,
          timeout: const Duration(seconds: 2))
      .then((value) async {
    Socket socket = value;
    PairDeviceInfo pairDeviceInfo = PairDeviceInfo(senderId: secretKey, deviceInfo: myDeviceInfo);

    socket.add(SocketMessage(call: pairDevicesCall, data: pairDeviceInfo.toJsonString()).toUInt8List());
    await socket.close();

    final bytes = await socket.single;
    SocketMessage socketMessage = SocketMessage.fromUInt8List(bytes);
    return socketMessage;
  }, onError: (e, st) {
    FLog.error(text: e.toString(), stacktrace: st);
    return SocketMessage(call: pairDevicesCall, error: "Ошибка при сопряжении");
  });
}
