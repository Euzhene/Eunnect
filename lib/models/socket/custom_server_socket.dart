// ignore_for_file: deprecated_export_use

import 'dart:async';
import 'dart:io' hide SocketMessage;

import 'package:eunnect/helpers/notification/notification_file.dart';
import 'package:eunnect/models/device_info/device_info.dart';
import 'package:eunnect/models/socket/socket_message.dart';
import 'package:eunnect/repo/local_storage.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:uuid/uuid.dart';

import '../../constants.dart';
import '../../helpers/ssl_helper.dart';
import '../custom_message.dart';


const pairDevicesCall = "pair_devices";
const deviceInfoCall = "device_info";
const isPairedCall = "is_paired";
const unpairCall = "unpair";
const sendBufferCall = "buffer";
const sendFileCall = "file";
const getCommandsCall = "get_commands";
const sendCommandCall = "send_command";


class CustomServerSocket {
  SecureServerSocket? _server;

  Function(DeviceInfo)? onPairDeviceCall;
  Function(String)? onBufferCall;

  Future<NotificationFile?> Function(FileMessage, DeviceInfo)? onFileStartReceivingCall;
  Function(NotificationFile?, FileMessage)? onFileFullReceivedCall;
  Function(NotificationFile?)? onFileNotFullyReceivedCall;
  Function(int, NotificationFile?)? onFileBytesReceivedCall;
  VoidCallback? onDeviceUnpaired;
  Function(String)? onPairingRequestTimeOut;

  late StreamController<DeviceInfo?> pairStream;

  final LocalStorage storage;
  final SslHelper sslHelper;
  late DeviceInfo myDeviceInfo;
  final Map<String, SecureSocket> fileMessagesSocket = {};

  CustomServerSocket({required this.storage, required this.sslHelper});

  Future<void> initServer(DeviceInfo myDeviceInfo) async {
    this.myDeviceInfo = myDeviceInfo;
    await _server?.close();
    fileMessagesSocket.clear();
    String? ipAddress = await NetworkInfo().getWifiIP();
    if (ipAddress == null) return;
    SecurityContext context = await sslHelper.getServerSecurityContext();
    _server = await SecureServerSocket.bind(ipAddress, port, context);
    FLog.info(text: "Server is initiated. Address - $ipAddress");
    _start();
  }

  void destroySocket(FileMessage fileMessage) {
    SecureSocket? socket = fileMessagesSocket.remove(fileMessage.id);
    socket?.destroy();
  }

  void _start() {
    _server?.listen((s) async {
      try {
        Stream<Uint8List> stream = s.asBroadcastStream();

        Uint8List bytes = await stream.first.then((value) => value, onError: (e, st) => Uint8List(0));
        if (bytes.isEmpty) return;

        ClientMessage receiveMessage = ClientMessage.fromUInt8List(bytes);

        ServerMessage sendMessage;
        switch (receiveMessage.call) {
          case deviceInfoCall:
            sendMessage = await _handleDeviceInfoCall();
            break;
          case pairDevicesCall:
            sendMessage = await _handlePairCall(receiveMessage.data);
            break;
          case sendBufferCall:
            sendMessage = await _handleBufferCall(receiveMessage);
            break;
          case sendFileCall:
            sendMessage = await _handleFileCall(stream, receiveMessage, s);
            break;
          case isPairedCall:
            sendMessage = await _handleIsPairedCall(receiveMessage.deviceId);
            break;
          case unpairCall:
            sendMessage = await _handleUnpairCall(receiveMessage.deviceId);
            break;
          default:
            sendMessage = _handleUnknownCall(receiveMessage.call);
            break;
        }
        s.add(sendMessage.toUInt8List());
        s.destroy();
      }catch(e,st) {
        FLog.error(text: e.toString(), stacktrace: st);
        if (e is HandshakeException) {

        }
        else if (e is! SocketException) {
          s.add(ServerMessage(status: 105).toUInt8List());
          s.destroy();
        }
      }
      FLog.debug(text: "${fileMessagesSocket.length} sockets remains");
    }, onError: (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
    });
  }

  Future<ServerMessage> _handleDeviceInfoCall() async {
    try {
      return ServerMessage(status: 200, data: myDeviceInfo.toJsonString());
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      return ServerMessage(status: 104);
    }
  }

  Future<ServerMessage> _handlePairCall(String data) async {
    try {
      DeviceInfo pairDeviceInfo = DeviceInfo.fromJsonString(data);
      onPairDeviceCall?.call(pairDeviceInfo);
      pairStream = StreamController();
      DeviceInfo? myPairDeviceInfo = await pairStream.stream.single.timeout(const Duration(seconds: 30), onTimeout: () {
        onPairingRequestTimeOut?.call(pairDeviceInfo.id);
        return null;
      });
      if (myPairDeviceInfo == null)
        return ServerMessage(status: 103);
      else
        return ServerMessage(status: 200, data: myPairDeviceInfo.toJsonString());
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      return ServerMessage(status: 104);
    }
  }

  Future<ServerMessage> _handleIsPairedCall(String deviceId) async {
    try {
      bool isPairedDevice = (await storage.getBaseDevice(deviceId, pairedDevicesKey)) != null;
      return ServerMessage(status: isPairedDevice ? 200 : 101);
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      return ServerMessage(status: 104);
    }
  }

  Future<ServerMessage> _handleUnpairCall(String deviceId) async {
    try {
      await storage.deleteBaseDevice(deviceId: deviceId, deviceKey: pairedDevicesKey);
      onDeviceUnpaired?.call();
      return ServerMessage(status: 200);
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      return ServerMessage(status: 104);
    }
  }


  Future<ServerMessage> _handleBufferCall(ClientMessage receiveMessage) async {
    ServerMessage? checkRes = await _checkPairDevice(receiveMessage);
    if (checkRes != null) return checkRes;

    String buffer = receiveMessage.data;
    await onBufferCall?.call(buffer);
    return ServerMessage(status: 200);
  }

  Future<ServerMessage?> _checkPairDevice(ClientMessage clientMessage) async {
    if ((await storage.getBaseDevice(clientMessage.deviceId, pairedDevicesKey) == null))
      return ServerMessage(status: 101);

    return null;
  }

  Future<ServerMessage> _handleFileCall(Stream<Uint8List> stream, ClientMessage receiveMessage, SecureSocket socket) async {
    int status = 200;
    FileMessage? fileMessage;
    try {
      ServerMessage? checkRes = await _checkPairDevice(receiveMessage);
      if (checkRes != null) return checkRes;

      fileMessage = FileMessage.fromJsonString(receiveMessage.data);
      fileMessage = fileMessage.copyWith(id: const Uuid().v4());
      fileMessagesSocket[fileMessage.id!] = socket;
      DeviceInfo otherDeviceInfo = (await storage.getBaseDevice(receiveMessage.deviceId, pairedDevicesKey))!;
      NotificationFile? notificationFile = await onFileStartReceivingCall?.call(fileMessage, otherDeviceInfo);

      var bytesBuilder = BytesBuilder();

      await for (Uint8List bytes in stream) {
        onFileBytesReceivedCall?.call(bytesBuilder.length, notificationFile);
        bytesBuilder.add(bytes);
      }

      if (bytesBuilder.isNotEmpty && bytesBuilder.length == fileMessage.fileSize) {
        fileMessage = fileMessage.copyWith(bytes: bytesBuilder.takeBytes());
        onFileFullReceivedCall?.call(notificationFile, fileMessage);
      } else onFileNotFullyReceivedCall?.call(notificationFile);

    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      status = 105;
    }

    fileMessagesSocket.remove(fileMessage?.id);
    return ServerMessage(status: status);
  }

  static ServerMessage _handleUnknownCall(String call) => ServerMessage(status: 102);

}
