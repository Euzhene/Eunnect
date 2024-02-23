import 'dart:async';
import 'dart:typed_data';

import 'package:f_logs/f_logs.dart';
import 'package:flutter/services.dart';
import 'package:nsd/nsd.dart';

import '../constants.dart';
import '../models/device_info.dart';

const String _nsdType = "_http._tcp";

class CustomNsd {
  Registration? _registration;
  Discovery? _discovery;

  void Function(List<DeviceInfo>)? onDevicesFound;

  Future<void> init(DeviceInfo myDeviceInfo) async {
    try {
      await _reset();

      register(Service(name: 'MAKUKU', type: _nsdType, port: port, txt: myDeviceInfo.toNsdJson())).then((value) {
        _registration = value;
        FLog.debug(text: "service registered");
      });
      _discovery = await startDiscovery(_nsdType);
      FLog.debug(text: "nsd started discovery");

      _getServices(myDeviceInfo);
      _discovery!.addListener(() {
        FLog.debug(text: "Discovery noticed ${_discovery!.services.length} changes");
        _getServices(myDeviceInfo);
      });
    }catch(e,st) {
      FLog.error(text: e.toString(), stacktrace: st);
    }
  }

  void _getServices(DeviceInfo myDeviceInfo) {
    List<Service> services = _discovery!.services;
    Set<DeviceInfo> foundDevices = {};
    for (var service in services) {
      if ((service.name ?? "").contains("MAKUKU") && service.txt != null) {
        Map<String, Uint8List?> attributes = service.txt!;
        DeviceInfo deviceInfo = DeviceInfo.fromNsdJson(attributes);
        FLog.debug(text: "Device found: ${deviceInfo.name}");
        if (myDeviceInfo == deviceInfo) continue;
        foundDevices.add(deviceInfo);
      }
    }
    onDevicesFound?.call(foundDevices.toList());
  }

  Future<void> _reset() async {
    Registration? _reg = _registration;
    if (_reg != null) await unregister(_reg);
    _discovery?.removeListener(() {});
    _discovery?.dispose();

    FLog.debug(text: "nsd was reseted");
  }
}
