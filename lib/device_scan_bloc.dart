import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:eunnect/custom_message.dart';
import 'package:eunnect/device_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'main.dart';

part 'device_scan_state.dart';

class DeviceScanBloc extends Cubit<DeviceScanState> {
  ServerSocket? _server;
  Isolate? _scanIsolate;
  ReceivePort? _scanPort;

  DeviceScanBloc() : super(const DeviceScanState()) {
    Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!state.loading) return;
      String loadingDots = state.loadingDots;
      emit(state.copyWith(loadingDots: loadingDots.length < 3 ? loadingDots += "." : ""));
    });
  }

  Future<void> onInitServer() async {
    DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

    await _server?.close();
    String deviceIp = (await NetworkInfo().getWifiIP())!;
    _server = await ServerSocket.bind(deviceIp, port);
    print("Сервер иницилизирован. Адрес - $deviceIp");

    _server!.listen((event) async {
      Uint8List bytes = await event.single;
      if (bytes.isNotEmpty) {
        String data = utf8.decode(bytes);
        print(data);
        DeviceInfo deviceInfo;
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfoPlugin.androidInfo;
          deviceInfo = DeviceInfo(name: androidInfo.model, platform: androidPlatform);
        } else if (Platform.isWindows) {
          final windowsInfo = await deviceInfoPlugin.windowsInfo;
          deviceInfo = DeviceInfo(name: windowsInfo.computerName, platform: windowsPlatform);
        } else {
          deviceInfo = const DeviceInfo(name: "Unknown", platform: "");
        }

        event.add(utf8.encode(deviceInfo.toJsonString()));
        event.close();
      }
    }, onError: (e, st) {
      print(e);
    });
    await Future.delayed(const Duration(minutes: 10));
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
        socket.add(utf8.encode("device_info"));
        await socket.close();
        final bytes = await socket.single;
        String serverDeviceInfoJson = utf8.decode(bytes);
        DeviceInfo deviceInfo = DeviceInfo.fromJson(jsonDecode(serverDeviceInfoJson));
        sendPort.send(IsolateMessage(data: deviceInfo));
      }, onError: (e, st) {
        //sendPort.send(IsolateMessage(errorMessage: ErrorMessage(shortError: "Ошибка сканирования", error: e, stackTrace: st)));
      });
    } catch (e, st) {
      sendPort.send(IsolateMessage(errorMessage: ErrorMessage(shortError: "Ошибка сканирования", error: e, stackTrace: st)));
    }
  }
  await Future.delayed(const Duration(seconds: 15));
  sendPort.send(IsolateMessage(done: true));
}
