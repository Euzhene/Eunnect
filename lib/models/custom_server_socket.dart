import 'dart:async';
import 'dart:io' hide SocketMessage;

import 'package:eunnect/helpers/get_it_helper.dart';
import 'package:eunnect/models/device_info.dart';
import 'package:eunnect/models/pair_device_info.dart';
import 'package:eunnect/repo/local_storage.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'custom_message.dart';

int port = 10242;

const deviceInfoCall = "device_info";
const pairDevicesCall = "pair_devices";
const sendBufferCall = "send_buffer";

abstract class CustomServerSocket {
  static ServerSocket? _server;
  static String? deviceIp;

  static FutureOr<DeviceInfo> Function()? onDeviceInfoCall;
  static Function(PairDeviceInfo)? onPairDeviceCall;
  static Function(String)? onBufferCall;

  static late StreamController<PairDeviceInfo?> pairStream;

  static final LocalStorage _localStorage = LocalStorage();

  static Future<void> initServer() async {
    await _server?.close();
    deviceIp = (await NetworkInfo().getWifiIP())!;
    _server = await ServerSocket.bind(deviceIp, port);
    FLog.info(text: "Сервер иницилизирован. Адрес - $deviceIp");
  }

  static void start() {
    _server?.listen((event) async {
      Uint8List bytes = await event.single;

      if (bytes.isEmpty) return;

      SocketMessage receiveMessage = SocketMessage.fromUInt8List(bytes);
      SocketMessage? sendMessage;

      switch (receiveMessage.call) {
        case deviceInfoCall:
          sendMessage = await _deviceCallHandler();
          break;
        case pairDevicesCall:
          sendMessage = await _pairDevicesHandler(receiveMessage.data);
          break;
        case sendBufferCall:
          sendMessage = await _sendBufferHandler(receiveMessage);
        default:
          sendMessage = _defaultHandler(receiveMessage.call);
          break;
      }

      sendMessage ??= _defaultHandler(receiveMessage.call);

      event.add(sendMessage.toUInt8List());
      event.close();
    }, onError: (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
    });
  }

  static Future<SocketMessage?> _pairDevicesHandler(String? data) async {
    if (data == null) return SocketMessage(call: pairDevicesCall, error: "Нет разрешения на вызов (пустой ключ)");

    try {
      PairDeviceInfo pairDeviceInfo = PairDeviceInfo.fromJsonString(data);
      onPairDeviceCall?.call(pairDeviceInfo);
      PairDeviceInfo? myPairDeviceInfo = await pairStream.stream.single;
      if (myPairDeviceInfo == null)
        return SocketMessage(call: pairDevicesCall, error: "Устройство не разрешило сопряжение");
      else
        return SocketMessage(call: pairDevicesCall, data: myPairDeviceInfo.toJsonString());
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      return SocketMessage(call: pairDevicesCall, error: "Произошла ошибка при чтении полученных данных");
    }
  }

  static Future<SocketMessage?> _deviceCallHandler() async {
    DeviceInfo? deviceInfo = await onDeviceInfoCall?.call();
    return SocketMessage(call: deviceInfoCall, data: deviceInfo?.toJsonString());
  }

  static SocketMessage _defaultHandler(String call) =>
      SocketMessage(call: call, error: "Вызов $call не поддерживается в данной версии приложения");

  static Future<SocketMessage> _sendBufferHandler(SocketMessage receiveMessage) async {
    if (receiveMessage.senderId == null)
      return SocketMessage(call: receiveMessage.call, error: "Нет разрешения на вызов (пустой ключ)");
    String secretKey = await _localStorage.getSecretKey();

    if (secretKey != receiveMessage.senderId)
      return SocketMessage(call: receiveMessage.call, error: "Нет разрешения на вызов (неверный ключ)");

    String buffer = receiveMessage.data!;
    await onBufferCall?.call(buffer);
    return SocketMessage(call: receiveMessage.call);
  }
}
