// ignore_for_file: deprecated_export_use

import 'dart:async';
import 'dart:io' hide SocketMessage;

import 'package:eunnect/models/device_info.dart';
import 'package:eunnect/models/pair_device_info.dart';
import 'package:eunnect/repo/local_storage.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/foundation.dart';

import 'custom_message.dart';

int port = 10242;

const deviceInfoCall = "device_info";
const pairDevicesCall = "pair_devices";
const sendBufferCall = "buffer";
const sendFileCall = "file";

abstract class CustomServerSocket {
  static ServerSocket? _server;

  static FutureOr<DeviceInfo> Function()? onDeviceInfoCall;
  static Function(PairDeviceInfo)? onPairDeviceCall;
  static Function(String)? onBufferCall;
  static Function(FileMessage)? onFileCall;

  static late StreamController<PairDeviceInfo?> pairStream;

  static final LocalStorage _localStorage = LocalStorage();

  static Future<void> initServer(String ipAddress) async {
    await _server?.close();
    _server = await ServerSocket.bind(ipAddress, port);
    FLog.info(text: "Сервер иницилизирован. Адрес - $ipAddress");
  }

  static void start() {
    _server?.listen((socket) async {
      SocketMessage? receiveMessage;
      SocketMessage? sendMessage;
      var bytesBuilder = BytesBuilder();
      Stream<Uint8List> stream = socket.asBroadcastStream();
      FileMessage? fileMessage;

      Uint8List bytes = await stream.first;
      receiveMessage = SocketMessage.fromUInt8List(bytes);

      stream.listen((bytes) async {
        if (bytes.isEmpty) return;

        bytesBuilder.add(bytes);
        socket.add(bytes);
      }, onDone: () {
        if (receiveMessage!.call != sendFileCall) return;

        if (bytesBuilder.isNotEmpty) {
          fileMessage = fileMessage!.copyWith(bytes: bytesBuilder.takeBytes());
          onFileCall?.call(fileMessage!);
        }
        socket.destroy();
      }, onError: (e, st) {
        FLog.error(text: e.toString(), stacktrace: st);
        socket.destroy();
      });

      switch (receiveMessage.call) {
        case deviceInfoCall:
          sendMessage = await _deviceCallHandler();
          break;
        case pairDevicesCall:
          sendMessage = await _pairDevicesHandler(receiveMessage.data);
          break;
        case sendBufferCall:
          sendMessage = await _sendBufferHandler(receiveMessage);
          break;
        case sendFileCall:
          fileMessage = FileMessage.fromJsonString(receiveMessage.data!);
          //   sendMessage = await _sendFileHandler(receiveMessage, s,socket);
          return;
        default:
          sendMessage = _defaultHandler(receiveMessage.call);
          break;
      }
      socket.add(sendMessage!.toUInt8List());
      socket.destroy();
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
    SocketMessage? checkRes = await _checkPairDevice(receiveMessage);
    if (checkRes != null) return checkRes;

    String buffer = receiveMessage.data!;
    await onBufferCall?.call(buffer);
    return SocketMessage(call: receiveMessage.call);
  }

  // static Future<SocketMessage> _sendFileHandler(SocketMessage receiveMessage, Stream<Uint8List> stream, Socket socket) async {
  //   SocketMessage? checkRes = await _checkPairDevice(receiveMessage);
  //   if (checkRes != null) return checkRes;
  //   var bytesBuilder = BytesBuilder();
  //
  //   stream.listen((bytes) async {
  //     if (bytes.isEmpty) return;
  //
  //     bytesBuilder.add(bytes);
  //     socket.add(bytes);
  //     print("listen");
  //   }, onDone: () {
  //     print("done");
  //     if (bytesBuilder.isEmpty) return;
  //
  //     onFileCall?.call(bytesBuilder.takeBytes());
  //     socket.close();
  //   });
  //
  //   return SocketMessage(call: receiveMessage.call);
  // }

  static Future<SocketMessage?> _checkPairDevice(SocketMessage receiveMessage) async {
    if (receiveMessage.senderId == null)
      return SocketMessage(call: receiveMessage.call, error: "Нет разрешения на вызов (пустой ключ)");
    String secretKey = await _localStorage.getSecretKey();

    if (secretKey != receiveMessage.senderId)
      return SocketMessage(call: receiveMessage.call, error: "Нет разрешения на вызов (неверный ключ)");

    return null;
  }
}
