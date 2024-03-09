import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:eunnect/blocs/main_bloc/main_bloc.dart';
import 'package:eunnect/blocs/scan_bloc/scan_state.dart';
import 'package:eunnect/extensions.dart';
import 'package:eunnect/helpers/get_it_helper.dart';
import 'package:eunnect/helpers/ssl_helper.dart';
import 'package:eunnect/models/custom_message.dart';
import 'package:eunnect/models/device_info/device_info.dart';
import 'package:eunnect/network/custom_nsd.dart';
import 'package:eunnect/repo/local_storage.dart';
import 'package:eunnect/screens/scan_screen/scan_paired_device.dart';
import 'package:f_logs/f_logs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../constants.dart';
import '../../models/socket/custom_server_socket.dart';
import '../../models/socket/socket_message.dart';

const String _deviceKey = pairedDevicesKey;

class ScanBloc extends Cubit<ScanState> {
  final LocalStorage _localStorage = GetItHelper.i<LocalStorage>();
  final MainBloc _mainBloc = GetItHelper.i<MainBloc>();
  final CustomNsd nsd = GetItHelper.i<CustomNsd>();

  List<DeviceInfo> foundDevices = [];
  List<ScanPairedDevice> pairedDevices = [];

  bool isFoundDeviceListExpanded = true;
  bool isPairedDeviceListExpanded = true;

  ScanBloc() : super(ScanState()) {
    _checkLastOpenDevice();
    isFoundDeviceListExpanded = _localStorage.getFoundDeviceListExpanded();
    isPairedDeviceListExpanded = _localStorage.getPairedDeviceListExpanded();

    getSavedDevices();

    _mainBloc.onPairedDeviceChanged = (DeviceInfo deviceInfo) {
      getSavedDevices();
      foundDevices.remove(deviceInfo);
      _emitScanState();
    };
  }

  void getSavedDevices() {
    _localStorage.getBaseDevices(_deviceKey).then((value) {
      pairedDevices.clear();
      pairedDevices.addAll(value.map((e) => ScanPairedDevice.fromDeviceInfo(e)));
      _emitScanState();
    });
  }

  Future<void> onScanDevices() async {
    DeviceInfo myDeviceInfo = GetItHelper.i<DeviceInfo>();
    if (myDeviceInfo.ipAddress.isEmpty) return;
    nsd.onDevicesFound = (List<DeviceInfo> devices) {
      foundDevices = [];

      for (DeviceInfo deviceInfo in devices) {
        if (pairedDevices.containsSameDeviceId(deviceInfo)) {
          ScanPairedDevice updatedPairedDevice = ScanPairedDevice.fromDeviceInfo(deviceInfo, true);
          pairedDevices.updateWithDeviceId(updatedPairedDevice);
          _localStorage.updateBaseDevice(deviceInfo, _deviceKey);
        } else
          foundDevices.add(deviceInfo);
      }
      _emitScanState();
    };
    await nsd.init(myDeviceInfo);
  }

  Future<void> onSaveLastOpenDevice(DeviceInfo deviceInfo) async {
    await _localStorage.setLastOpenDevice(deviceInfo.id);
  }

  Future<void> onDeleteLastOpenDevice() async {
    await _localStorage.setLastOpenDevice(null);
  }

  Future<void> onPairRequested(DeviceInfo deviceInfo) async {
    try {
      ReceivePort receivePort = ReceivePort();
      receivePort.listen((message) {
        message as IsolateMessage;
        ErrorMessage? error = message.errorMessage;
        if (error != null) FLog.error(text: error.shortError, stacktrace: error.stackTrace);
        else FLog.trace(text: message.data);
      });
      ServerMessage socketMessage = await compute<List, ServerMessage>(_pair, [receivePort.sendPort, GetItHelper.i<DeviceInfo>(), deviceInfo]);

      if (socketMessage.isErrorStatus) {
        _mainBloc.emitDefaultError(socketMessage.getError!);
        return;
      }

      await _localStorage.addBaseDevice(deviceInfo, _deviceKey);

      _updateNewPairedDevice(deviceInfo);

      _mainBloc.emitDefaultSuccess("Успешно сопряжено");

      _emitScanState();
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      _mainBloc.emitDefaultError(e.toString());
    }
  }

  Future<void> onAddDeviceByIp(String ip) async {
    try {
      FLog.trace(text: "getting info of a device by ip...");
      SecureSocket socket = await SecureSocket.connect(InternetAddress(ip, type: InternetAddressType.IPv4), port,
          timeout: const Duration(seconds: 2), onBadCertificate: (X509Certificate certificate) {
            return SslHelper.handleSelfSignedCertificate(certificate: certificate, pairedDevicesId: [], deviceIdCheck: false);
          });

      socket.add(ClientMessage(call: deviceInfoCall, data: "", deviceId: GetItHelper.i<DeviceInfo>().id).toUInt8List());
      await socket.close();

      final bytes = await socket.single;
      ServerMessage socketMessage = ServerMessage.fromUInt8List(bytes);
      if (socketMessage.isErrorStatus) {
        FLog.error(text: socketMessage.getError!);
        return;
      }
      DeviceInfo pairingDeviceInfo = DeviceInfo.fromJsonString(socketMessage.data!);

      onPairRequested(pairingDeviceInfo);
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
    }
  }

  void onFoundDeviceExpansionChanged(bool expanded) {
    _localStorage.setFoundDeviceListExpanded(expanded);
  }

  void onPairedDeviceExpansionChanged(bool expanded) {
    _localStorage.setPairedDeviceListExpanded(expanded);
  }

  void _emitScanState() {
    if (!isClosed) emit(ScanState());
  }

  void _updateNewPairedDevice(DeviceInfo deviceInfo) {
    ScanPairedDevice scanPairedDevice = ScanPairedDevice.fromDeviceInfo(deviceInfo, true);
    if (!pairedDevices.contains(scanPairedDevice)) pairedDevices.add(scanPairedDevice);

    foundDevices.remove(deviceInfo);
  }

  Future<void> _checkLastOpenDevice() async {
    String? lastOpenDeviceId = _localStorage.getLastOpenDevice();
    if (lastOpenDeviceId == null) return;
    DeviceInfo? lastOpenDevice = await _localStorage.getBaseDevice(lastOpenDeviceId, _deviceKey);
    if (lastOpenDevice != null) emit(MoveToLastOpenDeviceState(ScanPairedDevice.fromDeviceInfo(lastOpenDevice)));
  }
}

FutureOr<ServerMessage> _pair(List args) async {
  SendPort sendPort = args[0];
  DeviceInfo myDeviceInfo = args[1];
  DeviceInfo deviceInfo = args[2];
  try{
    sendPort.send(IsolateMessage(data: "a pairing with a new device ${deviceInfo.name} was requested"));
    SecureSocket socket = await SecureSocket.connect(InternetAddress(deviceInfo.ipAddress, type: InternetAddressType.IPv4), port,
        timeout: const Duration(seconds: 2), onBadCertificate: (X509Certificate certificate) {
          return SslHelper.handleSelfSignedCertificate(certificate: certificate, pairedDevicesId: [deviceInfo.id]);
        });

    socket.add(ClientMessage(call: pairDevicesCall, data: myDeviceInfo.toJsonString(), deviceId: deviceInfo.id).toUInt8List());
    await socket.close();

    final bytes = await socket.single;
    ServerMessage socketMessage = ServerMessage.fromUInt8List(bytes);
    if (socketMessage.isErrorStatus) sendPort.send(IsolateMessage(errorMessage: ErrorMessage(shortError: socketMessage.getError!)));
    else sendPort.send(IsolateMessage(data: "Pairing is successful!"));

    return socketMessage;
  } catch (e, st) {
    sendPort.send(IsolateMessage(errorMessage: ErrorMessage(shortError: e.toString(),stackTrace: st)));
    return ServerMessage(status: 105);
  }
}
