// ignore_for_file: deprecated_export_use

import 'dart:async';
import 'dart:io' hide SocketMessage;

import 'package:eunnect/models/device_info.dart';
import 'package:eunnect/models/socket/socket_message.dart';
import 'package:eunnect/repo/local_storage.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../../constants.dart';
import '../../helpers/ssl_helper.dart';
import '../custom_message.dart';


const pairDevicesCall = "pair_devices";
const sendBufferCall = "buffer";
const sendFileCall = "file";

const changePcStateCall = "pc_state";
const pcRestartState = "restart";
const pcShutDownState = "shut_down";
const pcSleepState = "sleep";

class CustomServerSocket {
  SecureServerSocket? _server;

  Function(DeviceInfo)? onPairDeviceCall;
  Function(String)? onBufferCall;
  Function(FileMessage)? onFileCall;

  late StreamController<DeviceInfo?> pairStream;

  final LocalStorage storage;

  CustomServerSocket({required this.storage});

  Future<void> initServer() async {
    await _server?.close();
    String? ipAddress = await NetworkInfo().getWifiIP();
    if (ipAddress == null) return;
    SslHelper sslHelper = SslHelper(storage);
    SecurityContext context = await sslHelper.getServerSecurityContext();
    _server = await SecureServerSocket.bind(ipAddress, port, context);
    FLog.info(text: "Server is initiated. Address - $ipAddress");
    _start();
  }

  void _start() {
    late SecureSocket socket;
    _server?.listen((s) async {
      socket = s;
      Stream<Uint8List> stream = socket.asBroadcastStream();

      Uint8List bytes = await stream.first.then((value) => value, onError: (e, st) => Uint8List(0));
      if (bytes.isEmpty) return;

      ClientMessage receiveMessage = ClientMessage.fromUInt8List(bytes);

      ServerMessage sendMessage;
      switch (receiveMessage.call) {
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
      if (e is! SocketException){
        socket.add(ServerMessage(status: 105).toUInt8List());
        socket.destroy();
      }
    });
  }

  Future<ServerMessage> _handlePairCall(String data) async {
    try {
      DeviceInfo pairDeviceInfo = DeviceInfo.fromJsonString(data);
      onPairDeviceCall?.call(pairDeviceInfo);
      pairStream = StreamController();
      DeviceInfo? myPairDeviceInfo = await pairStream.stream.single.timeout(const Duration(seconds: 30), onTimeout: () => null);
      if (myPairDeviceInfo == null)
        return ServerMessage(status: 103);
      else
        return ServerMessage(status: 200, data: myPairDeviceInfo.toJsonString());
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      return ServerMessage(status: 104);
    }
  }

  static ServerMessage _handleUnknownCall(String call) => ServerMessage(status: 102);

  Future<ServerMessage> _handleBufferCall(ClientMessage receiveMessage) async {
    ServerMessage? checkRes = await _checkPairDevice(receiveMessage);
    if (checkRes != null) return checkRes;

    String buffer = receiveMessage.data;
    await onBufferCall?.call(buffer);
    return ServerMessage(status: 200);
  }

  Future<ServerMessage?> _checkPairDevice(ClientMessage clientMessage) async {
    if ((await storage.getPairedDevice(clientMessage.deviceId) == null))
      return ServerMessage(status: 101);

    return null;
  }

  Future<ServerMessage> _handleFileCall(Stream<Uint8List> stream, ClientMessage receiveMessage, Socket socket) async {
    int status = 200;
    try {
      ServerMessage? checkRes = await _checkPairDevice(receiveMessage);
      if (checkRes != null) return checkRes;

      FileMessage fileMessage = FileMessage.fromJsonString(receiveMessage.data);

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
      status = 105;
    }
    return ServerMessage(status: status);
  }
}
