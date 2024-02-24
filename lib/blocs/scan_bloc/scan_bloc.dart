import 'dart:async';
import 'dart:io';

import 'package:eunnect/blocs/main_bloc/main_bloc.dart';
import 'package:eunnect/blocs/scan_bloc/scan_state.dart';
import 'package:eunnect/extensions.dart';
import 'package:eunnect/helpers/get_it_helper.dart';
import 'package:eunnect/models/device_info.dart';
import 'package:eunnect/network/custom_nsd.dart';
import 'package:eunnect/repo/local_storage.dart';
import 'package:eunnect/screens/scan_screen/scan_paired_device.dart';
import 'package:f_logs/f_logs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../constants.dart';
import '../../models/socket/custom_server_socket.dart';
import '../../models/socket/socket_message.dart';

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

  Future<void> onScanDevices() async {
    DeviceInfo myDeviceInfo = GetItHelper.i<DeviceInfo>();
    if (myDeviceInfo.ipAddress.isEmpty) return;
    nsd.onDevicesFound = (List<DeviceInfo> devices) {
      foundDevices = [];

      for (DeviceInfo deviceInfo in devices) {
        if (pairedDevices.containsSameDeviceId(deviceInfo)) {
          ScanPairedDevice updatedPairedDevice = ScanPairedDevice.fromDeviceInfo(deviceInfo, true);
          pairedDevices.updateWithDeviceId(updatedPairedDevice);
          _localStorage.updatePairedDevice(deviceInfo);
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
      FLog.trace(text: "a pairing with a new device was requested");
      ServerMessage socketMessage = await compute<List, ServerMessage>(pair, [GetItHelper.i<DeviceInfo>(), deviceInfo]);

      if (socketMessage.isErrorStatus) {
        _mainBloc.emitDefaultError(socketMessage.getError!);
        return;
      }

      await _localStorage.addPairedDevice(deviceInfo);

      _updateNewPairedDevice(deviceInfo);

      _mainBloc.emitDefaultSuccess("Успешно сопряжено");

      _emitScanState();
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      _mainBloc.emitDefaultError(e.toString());
    }
  }

  void _updateNewPairedDevice(DeviceInfo deviceInfo) {
    ScanPairedDevice scanPairedDevice = ScanPairedDevice.fromDeviceInfo(deviceInfo, true);
    if (!pairedDevices.contains(scanPairedDevice)) pairedDevices.add(scanPairedDevice);

    foundDevices.remove(deviceInfo);
  }

  void onFoundDeviceExpansionChanged(bool expanded) {
    _localStorage.setFoundDeviceListExpanded(expanded);
  }

  void onPairedDeviceExpansionChanged(bool expanded) {
    _localStorage.setPairedDeviceListExpanded(expanded);
  }

  Future<void> _checkLastOpenDevice() async {
    String? lastOpenDeviceId = _localStorage.getLastOpenDevice();
    if (lastOpenDeviceId == null) return;
    DeviceInfo? lastOpenDevice = await _localStorage.getPairedDevice(lastOpenDeviceId);
    if (lastOpenDevice != null) emit(MoveToLastOpenDeviceState(ScanPairedDevice.fromDeviceInfo(lastOpenDevice)));
  }
}

FutureOr<ServerMessage> pair(List args) async {
  DeviceInfo myDeviceInfo = args[0];
  DeviceInfo deviceInfo = args[1];
  try {
    FLog.trace(text: "pairing with a new device...");
    SecureSocket socket = await SecureSocket.connect(InternetAddress(deviceInfo.ipAddress, type: InternetAddressType.IPv4), port,
        timeout: const Duration(seconds: 2), onBadCertificate: (X509Certificate certificate) {
      //todo: общий обработчик для самоподписанных сертификатов. Можно вынести в SSLHelper
      String issuer = certificate.issuer;
      bool containsAppName = issuer.toUpperCase().contains("MAKUKU");
      if (!containsAppName) {
        FLog.info(text: "The issuer ($issuer) of the provided certificate is not Makuku. Closing connection");
        return false;
      }
      bool containsPairedDeviceId = issuer.contains(deviceInfo.id);
      if (!containsPairedDeviceId) FLog.info(text: "Server device id is unknown to this device. Closing connection");
      return containsPairedDeviceId;
    });

    socket.add(ClientMessage(call: pairDevicesCall, data: myDeviceInfo.toJsonString(), deviceId: deviceInfo.id).toUInt8List());
    await socket.close();

    final bytes = await socket.single;
    ServerMessage socketMessage = ServerMessage.fromUInt8List(bytes);
    FLog.trace(text: "Pairing is successful!");

    return socketMessage;
  } catch (e, st) {
    FLog.error(text: "Caught error while pairing. Error: $e", stacktrace: st);
    return ServerMessage(status: 105);
  }
}
