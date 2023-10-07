import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:equatable/equatable.dart';
import 'package:eunnect/helpers/get_it_helper.dart';
import 'package:eunnect/models/custom_message.dart';
import 'package:eunnect/models/custom_server_socket.dart';
import 'package:eunnect/models/device_info.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:network_info_plus/network_info_plus.dart';

part 'device_scan_state.dart';


class DeviceScanBloc extends Cubit<DeviceScanState> {
  Isolate? _scanIsolate;
  ReceivePort? _scanPort;
  final DeviceInfo _deviceInfo = GetItHelper.i<DeviceInfo>();

  DeviceScanBloc() : super(const DeviceScanState()) {
    Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!state.loading) return;
      String loadingDots = state.loadingDots;
      emit(state.copyWith(loadingDots: loadingDots.length < 3 ? loadingDots += "." : ""));
    });
  }

  Future<void> onInitServer() async {
    await CustomServerSocket.initServer();
    CustomServerSocket.onDeviceInfoCall = (){
      return _deviceInfo;
    };

    CustomServerSocket.start();
  }

  Future<void> onCancelScanRequested() async {
    _scanPort?.close();
    _scanIsolate?.kill();
    emit(state.copyWith(loading: false));
  }

  Future<void> onScanDevicesRequested() async {
    try {
      emit(state.copyWith(devices: [], loading: true));
      _scanPort = ReceivePort();
      _scanIsolate = await Isolate.spawn(scan, [_scanPort!.sendPort, port, (await NetworkInfo().getWifiIP())!]);
      _scanPort!.listen((message) {
        message as IsolateMessage;
        if (message.errorMessage != null) {
          ErrorMessage e = message.errorMessage!;
          Logger.root.info(e.shortError, e.error, e.stackTrace);
          return;
        }
        if (message.data != null) {
          emit(state.copyWith(devices: (state.devices ?? []).toList()..add(message.data!)));
        }

        if (message.done) {
          onCancelScanRequested();
        }
      });
    } catch (e, st) {
      Logger.root.info(e.toString(), e, st);
      emit(state.copyWith(loading: false));
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
  await Future.delayed(const Duration(seconds: 15));
  sendPort.send(IsolateMessage(done: true));
}
