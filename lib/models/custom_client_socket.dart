
import 'dart:io' hide SocketMessage;
import 'dart:typed_data';

import 'package:eunnect/helpers/get_it_helper.dart';
import 'package:eunnect/models/device_info.dart';

import 'custom_message.dart';
import 'custom_server_socket.dart';

abstract class CustomClientSocket {
  static final DeviceInfo myDeviceInfo = GetItHelper.i<DeviceInfo>();

  static Future<Socket> connect(String ip) {
    return Socket.connect(ip, port);
  }

  static Future<void> sendBuffer({required Socket socket, required String text}) async {
    socket.add(SocketMessage(call: sendBufferCall, data: text, deviceId: myDeviceInfo.id).toUInt8List());
    await socket.close();
  }

  static Future<void> sendCommand({required Socket socket, required String commandName}) async {
    socket.add(SocketMessage(call: changePcStateCall, data: commandName, deviceId: myDeviceInfo.id).toUInt8List());
    await socket.close();
  }

  static Future<void> sendFile({required Socket socket, required Uint8List bytes, required String fileName}) async {
    SocketMessage initialMessage = SocketMessage(
        call: sendFileCall,
        deviceId: myDeviceInfo.id,
        data: FileMessage(fileSize: bytes.length, filename: fileName).toJsonString());

    socket.add(initialMessage.toUInt8List());
    await Future.delayed(const Duration(seconds: 1)); //дает возможность успеть серверу получить только начальное сообщение

    socket.add(bytes);
    await socket.close();
  }
}