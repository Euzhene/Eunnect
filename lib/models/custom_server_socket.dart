// ignore_for_file: deprecated_export_use

import 'dart:async';
import 'dart:io' hide SocketMessage;

import 'package:eunnect/models/device_info.dart';
import 'package:eunnect/repo/local_storage.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/foundation.dart';

import 'custom_message.dart';

int port = 10242;

const deviceInfoCall = "device_info";
const pairDevicesCall = "pair_devices";
const sendBufferCall = "buffer";
const sendFileCall = "file";

const changePcStateCall = "pc_state";
const pcRestartState = "restart";
const pcShutDownState = "shut_down";
const pcSleepState = "sleep";

abstract class CustomServerSocket {
  static ServerSocket? _server;

  static FutureOr<DeviceInfo> Function()? onDeviceInfoCall;
  static Function(DeviceInfo)? onPairDeviceCall;
  static Function(String)? onBufferCall;
  static Function(FileMessage)? onFileCall;

  static late StreamController<DeviceInfo?> pairStream;

  static final LocalStorage _localStorage = LocalStorage();

  static Future<void> initServer(String ipAddress) async {
    await _server?.close();
    _server = await ServerSocket.bind(ipAddress, port);
    FLog.info(text: "Сервер иницилизирован. Адрес - $ipAddress");
  }

  static void start() {
    _server?.listen((socket) async {
      Stream<Uint8List> stream = socket.asBroadcastStream();

      Uint8List bytes = await stream.first.then((value) => value, onError: (e, st) => Uint8List(0));
      if (bytes.isEmpty) return;

      SocketMessage receiveMessage = SocketMessage.fromUInt8List(bytes);

      SocketMessage sendMessage;
      switch (receiveMessage.call) {
        case deviceInfoCall:
          sendMessage = await _deviceCallHandler();
          break;
        case pairDevicesCall:
          sendMessage = await _handlePairCall(receiveMessage.data);
          break;
        case sendBufferCall:
          sendMessage = await _handleBufferCall(receiveMessage);
          break;
        case sendFileCall:
          sendMessage = await _handleFileCall(stream, receiveMessage, socket);
          break;
        default:
          sendMessage = _handleUnknownCall(receiveMessage.call);
          break;
      }
      socket.add(sendMessage.toUInt8List());
      socket.destroy();
    }, onError: (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
    });
  }

  static Future<SocketMessage> _handlePairCall(String? data) async {
    if (data == null) return SocketMessage(call: pairDevicesCall, error: "Нет разрешения на вызов (пустой ключ)");

    try {
      DeviceInfo pairDeviceInfo = DeviceInfo.fromJsonString(data);
      onPairDeviceCall?.call(pairDeviceInfo);
      pairStream = StreamController();
      DeviceInfo? myPairDeviceInfo = await pairStream.stream.single.timeout(const Duration(seconds: 30), onTimeout: () => null);
      if (myPairDeviceInfo == null)
        return SocketMessage(call: pairDevicesCall, error: "Устройство не разрешило сопряжение");
      else
        return SocketMessage(call: pairDevicesCall, data: myPairDeviceInfo.toJsonString());
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      return SocketMessage(call: pairDevicesCall, error: "Произошла ошибка на сервере при чтении полученных данных");
    }
  }

  static Future<SocketMessage> _deviceCallHandler() async {
    DeviceInfo? deviceInfo = await onDeviceInfoCall?.call();
    return SocketMessage(call: deviceInfoCall, data: deviceInfo?.toJsonString());
  }

  static SocketMessage _handleUnknownCall(String call) =>
      SocketMessage(call: call, error: "Вызов $call не поддерживается в данной версии приложения");

  static Future<SocketMessage> _handleBufferCall(SocketMessage receiveMessage) async {
    SocketMessage? checkRes = await _checkPairDevice(receiveMessage);
    if (checkRes != null) return checkRes;

    String buffer = receiveMessage.data!;
    await onBufferCall?.call(buffer);
    return SocketMessage(call: receiveMessage.call);
  }

  static Future<SocketMessage?> _checkPairDevice(SocketMessage receiveMessage) async {
    if (receiveMessage.deviceId == null)
      return SocketMessage(call: receiveMessage.call, error: "Нет разрешения на вызов (пустой ключ)");

    if ((await _localStorage.getPairedDevice(receiveMessage.deviceId) == null))
      return SocketMessage(call: receiveMessage.call, error: "Нет разрешения на вызов (отсутствует сопряжение)");

    return null;
  }

  static Future<SocketMessage> _handleFileCall(Stream<Uint8List> stream, SocketMessage receiveMessage, Socket socket) async {
    String? error;
    try {
      SocketMessage? checkRes = await _checkPairDevice(receiveMessage);
      if (checkRes != null) return checkRes;

      FileMessage fileMessage = FileMessage.fromJsonString(receiveMessage.data!);

      var bytesBuilder = BytesBuilder();

      await for (Uint8List bytes in stream) {
        bytesBuilder.add(bytes);
      }

      if (bytesBuilder.isNotEmpty) {
        fileMessage = fileMessage.copyWith(bytes: bytesBuilder.takeBytes());
        onFileCall?.call(fileMessage);
      }
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      error = e.toString();
    }
    return SocketMessage(call: sendFileCall, error: error);
  }
}
