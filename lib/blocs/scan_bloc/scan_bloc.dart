import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:eunnect/blocs/scan_bloc/scan_state.dart';
import 'package:eunnect/helpers/get_it_helper.dart';
import 'package:eunnect/models/custom_message.dart';
import 'package:eunnect/models/custom_server_socket.dart';
import 'package:eunnect/models/device_info.dart';
import 'package:f_logs/f_logs.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ScanBloc extends Cubit<ScanState> {
  Isolate? _scanIsolate;
  ReceivePort _receivePort = ReceivePort();

  ScanBloc() : super(const ScanState()) {
    const int period = 6;

    Timer.periodic(const Duration(seconds: period), (timer) {
      DateTime curDate = DateTime.now();

      Set<DeviceInfo> foundDevices = state.foundDevices.toSet()
        ..removeWhere((element) {
          if ((curDate.difference(devicesTime[element.id] ?? DateTime.now()).inSeconds) >= period) {
            devicesTime.remove(element.id);
            return true;
          }
          return false;
        });
      if (!isClosed)
        emit(state.copyWith.call(foundDevices: foundDevices));
    });
  }

  Map<String, DateTime> devicesTime = {};

  void onScanDevices() async {
    _scanIsolate?.kill();
    _receivePort.close();
    _receivePort = ReceivePort();

    _receivePort.listen((message) {
      message as IsolateMessage;
      ErrorMessage? errorMessage = message.errorMessage;
      if (errorMessage != null) {
        FLog.error(text: errorMessage.shortError, exception: errorMessage.error, stacktrace: errorMessage.stackTrace);
        return;
      }

      DeviceInfo deviceInfo = message.data;
      devicesTime[deviceInfo.id] = DateTime.now();

      Set<DeviceInfo> foundDevices = state.foundDevices.toSet()..add(deviceInfo);
      emit(state.copyWith.call(foundDevices: foundDevices));
    });

    _scanIsolate =
        await Isolate.spawn(_scanDevices, [_receivePort.sendPort, GetItHelper.i<DeviceInfo>(), RootIsolateToken.instance]);
  }
}

void _scanDevices(List args) async {
  SendPort sendPort = args[0];
  DeviceInfo myDeviceInfo = args[1];
  RootIsolateToken token = args[2];

  BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  if (Platform.isAndroid) {
    await const MethodChannel("multicast").invokeMethod("release");
    await const MethodChannel("multicast").invokeMethod("acquire");
  }
  var internetAddress = InternetAddress("229.30.13.47");

  RawDatagramSocket receiver = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
  receiver.joinMulticast(internetAddress);

  RawDatagramSocket sender = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
  sender.joinMulticast(internetAddress);
  sender.broadcastEnabled = true;
  sender.multicastLoopback = false;

  receiver.listen((e) {
    Datagram? datagram = receiver.receive();
    if (datagram != null) {
      DeviceInfo deviceInfo = DeviceInfo.fromUInt8List(datagram.data);
      if (deviceInfo.id != myDeviceInfo.id) {
        sendPort.send(IsolateMessage(data: deviceInfo));
      }
    }
  }, onError: (e, st) {
    sendPort.send(IsolateMessage(errorMessage: ErrorMessage(shortError: "Error in receiver", error: e, stackTrace: st)));
  });

  Timer.periodic(const Duration(seconds: 3), (timer) async {
    try {
      sender.send(myDeviceInfo.toJsonString().codeUnits, internetAddress, port);
    } catch (e, st) {
      sendPort.send(IsolateMessage(errorMessage: ErrorMessage(shortError: "Error in sender", error: e, stackTrace: st)));
    }
  });
}
