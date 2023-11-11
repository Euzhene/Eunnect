import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:eunnect/blocs/main_bloc/main_bloc.dart';
import 'package:eunnect/blocs/scan_bloc/scan_state.dart';
import 'package:eunnect/helpers/get_it_helper.dart';
import 'package:eunnect/models/custom_message.dart';
import 'package:eunnect/models/custom_server_socket.dart';
import 'package:eunnect/models/device_info.dart';
import 'package:eunnect/repo/local_storage.dart';
import 'package:eunnect/screens/scan_screen/scan_paired_device.dart';
import 'package:f_logs/f_logs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../constants.dart';

class ScanBloc extends Cubit<ScanState> {
  final LocalStorage _localStorage = LocalStorage();
  final MainBloc _mainBloc = GetItHelper.i<MainBloc>();
  final DeviceInfo _myDeviceInfo = GetItHelper.i<DeviceInfo>();

  Isolate? _scanIsolate;
  ReceivePort _receivePort = ReceivePort();

  List<DeviceInfo> foundDevices = [];
  List<ScanPairedDevice> pairedDevices = [];

  ScanBloc() : super(ScanState()) {
    const int period = 6;

    /*
      В этом таймере раз в 6 секунд происходит проверка: если инфа об устройстве не получена в течение 6 секунд - удаляем это устройство из списка обнаруженных устройств.
      В случае, если это сопряженное устройство, - показываем юзеру что оно недоступно (цветом или надписью)
     */
    Timer.periodic(const Duration(seconds: period), (timer) {
      DateTime curDate = DateTime.now();

      devicesTime.removeWhere((key, value) {
        if ((curDate.difference(value).inSeconds) >= period) {
          foundDevices.removeWhere((element) => element.id == key);
          int index = pairedDevices.indexWhere((element) => element.id == key);

          if (index >= 0) {
            ScanPairedDevice pairedDevice = pairedDevices[index];
            pairedDevices[index] = (pairedDevice.copyWith(available: false));
          }
          _emitScanState();
          return true;
        }
        return false;
      });
    });
    getSavedDevices();

    _mainBloc.onPairedDeviceChanged = (DeviceInfo deviceInfo) {
      getSavedDevices();
      foundDevices.remove(deviceInfo);
      _emitScanState();
    };
  }

  void _emitScanState() {
    if (!isClosed) emit(ScanState());
  }

  void getSavedDevices() {
    _localStorage.getPairedDevices().then((value) {
      pairedDevices.clear();
      pairedDevices.addAll(value.map((e) => ScanPairedDevice.fromDeviceInfo(e)));
      _emitScanState();
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

      ScanPairedDevice? pairedDevice = pairedDevices.where((element) => element.id == deviceInfo.id).firstOrNull;
      if (pairedDevice != null) {
        pairedDevices.remove(pairedDevice);
        pairedDevices.add(pairedDevice.copyWith(available: true));
      } else {
        foundDevices.add(deviceInfo);
      }

      _emitScanState();
    });

    _scanIsolate =
        await Isolate.spawn(_scanDevices, [_receivePort.sendPort, GetItHelper.i<DeviceInfo>(), RootIsolateToken.instance]);
  }

  Future<void> onSendLogs() async {
    File logs = await FLog.exportLogs();
    if ((await logs.length()) == 0) {
      _mainBloc.emitDefaultSuccess("Лог пуст!");
      return;
    }

    ShareResult res = await Share.shareXFiles([XFile(logs.path)], text: "$appName ${dateFormat.format(DateTime.now())}");
    if (res.status == ShareResultStatus.success) {
      _mainBloc.emitDefaultSuccess("Логи очищены");
      FLog.clearLogs();
    }
  }

  Future<void> onPairedDeviceChosen(ScanPairedDevice pairDeviceInfo) async {
    try {
      await (await Socket.connect(pairDeviceInfo.ipAddress, port)).close(); //check we can work with another device
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      _mainBloc.emitDefaultError("Не удалось подключиться");
    }
  }

  Future<void> onPairRequested(DeviceInfo deviceInfo) async {
    try {
      SocketMessage socketMessage = await compute<List, SocketMessage>(pair, [_myDeviceInfo, deviceInfo]);

      if (socketMessage.error != null) {
        _mainBloc.emitDefaultError(socketMessage.error!);
        return;
      }

      await _localStorage.addPairedDevice(deviceInfo);
      ScanPairedDevice scanPairedDevice = ScanPairedDevice.fromDeviceInfo(deviceInfo, true);
      if (!pairedDevices.contains(scanPairedDevice)) {
        pairedDevices.add(scanPairedDevice);
      }
      foundDevices.remove(deviceInfo);
      _mainBloc.emitDefaultSuccess("Успешно сопряжено");

      _emitScanState();
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      _mainBloc.emitDefaultError(e.toString());
    }
  }
}

FutureOr<SocketMessage> pair(List args) async {
  DeviceInfo myDeviceInfo = args[0];
  DeviceInfo deviceInfo = args[1];
  return await Socket.connect(InternetAddress(deviceInfo.ipAddress, type: InternetAddressType.IPv4), port,
          timeout: const Duration(seconds: 2))
      .then((value) async {
    Socket socket = value;

    socket.add(SocketMessage(call: pairDevicesCall, data: myDeviceInfo.toJsonString()).toUInt8List());
    await socket.close();

    final bytes = await socket.single;
    SocketMessage socketMessage = SocketMessage.fromUInt8List(bytes);
    return socketMessage;
  }, onError: (e, st) {
    FLog.error(text: e.toString(), stacktrace: st);
    return SocketMessage(call: pairDevicesCall, error: "Ошибка при сопряжении");
  });
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
