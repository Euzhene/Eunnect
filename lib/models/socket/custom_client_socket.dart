import 'dart:io' hide SocketMessage;
import 'dart:typed_data';

import 'package:eunnect/helpers/ssl_helper.dart';
import 'package:eunnect/models/device_info/device_info.dart';
import 'package:eunnect/models/socket/socket_message.dart';
import 'package:eunnect/repo/local_storage.dart';

import '../../constants.dart';
import '../custom_message.dart';
import 'custom_server_socket.dart';

class CustomClientSocket {
  final DeviceInfo myDeviceInfo;
  final LocalStorage storage;

  CustomClientSocket({required this.myDeviceInfo, required this.storage});

  Future<SecureSocket> connect(String ip) async {
    List<String> pairedDevicesId = (await storage.getBaseDevices(pairedDevicesKey)).map((e) => e.id).toList();
    return SecureSocket.connect(ip, port, onBadCertificate: (X509Certificate certificate) {
      return SslHelper.handleSelfSignedCertificate(certificate: certificate, pairedDevicesId: pairedDevicesId);
    });
  }

  ///Проверка того, что устройство, с которым мы хотим работать, доступно для подключения
  Future<void> checkConnection(String ip) async {
    return (await connect(ip)).destroy();
  }

  Future<void> sendBuffer({required SecureSocket socket, required String text}) async {
    socket.add(ClientMessage(call: sendBufferCall, data: text, deviceId: myDeviceInfo.id).toUInt8List());
    await socket.close();
  }

  Future<void> sendCommand({required SecureSocket socket, required String commandName}) async {
    socket.add(ClientMessage(call: changePcStateCall, data: commandName, deviceId: myDeviceInfo.id).toUInt8List());
    await socket.close();
  }

  ///возвращает false, если не получилось отправить файл из-за отсутствия сопряжения
  Future<ServerMessage?> sendFile({required SecureSocket socket, required Uint8List bytes, required String fileName}) async {
    ClientMessage initialMessage = ClientMessage(
        call: sendFileCall,
        deviceId: myDeviceInfo.id,
        data: FileMessage(fileSize: bytes.length, filename: fileName).toJsonString());

    socket.add(initialMessage.toUInt8List());
    await Future.delayed(const Duration(seconds: 1)); //дает возможность успеть серверу получить только начальное сообщение
    try {
      socket.add(bytes);
      await socket.flush();
    } catch (e, st) {
      return ServerMessage(status: 101);
    }
    await socket.close();
    return null;
  }
}
