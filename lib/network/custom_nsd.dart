import 'dart:async';
import 'dart:typed_data';

import 'package:f_logs/f_logs.dart';
import 'package:flutter/services.dart';
import 'package:nsd/nsd.dart';

import '../constants.dart';
import '../models/device_info/device_info.dart';

const String _nsdType = "_makuku._tcp";

class CustomNsd {
  Registration? _registration;
  Discovery? _discovery;
  Timer? _timer;

  void Function(List<DeviceInfo>)? onDevicesFound;

  Future<void> init(DeviceInfo myDeviceInfo) async {
    try {
      await _reset();

      register(Service(name: myDeviceInfo.id, type: _nsdType, port: port, txt: myDeviceInfo.toNsdJson())).then((value) {
        _registration = value;
        FLog.debug(text: "service registered");
      });
      _discovery = await startDiscovery(_nsdType);
      FLog.debug(text: "nsd started discovery");
      _discovery!.addListener(() {
        FLog.debug(text: "Discovery noticed ${_discovery!.services.length} changes");
        _getFoundServices(myDeviceInfo);
      });
      _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
        _getFoundServices(myDeviceInfo);
      });
    }catch(e,st) {
      FLog.error(text: e.toString(), stacktrace: st);
    }
  }

  void _getFoundServices(DeviceInfo myDeviceInfo) {
    List<Service> services = _discovery!.services;
    Set<DeviceInfo> foundDevices = {};
    for (var service in services) {
      if (service.txt != null) {
        Map<String, Uint8List?> attributes = service.txt!;
        DeviceInfo deviceInfo = DeviceInfo.fromNsdJson(attributes);
        if (myDeviceInfo.id == deviceInfo.id) continue;
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
    _timer?.cancel();

    FLog.debug(text: "nsd was reseted");
  }
}
