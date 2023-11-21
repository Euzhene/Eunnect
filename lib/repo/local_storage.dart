import 'dart:convert';

import 'package:eunnect/extensions.dart';
import 'package:eunnect/helpers/get_it_helper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/device_info.dart';

const _isFirstLaunchKey = "is_first_launch";

const _isFoundDeviceListExpanded = "is_found_device_list_expanded";
const _isPairedDeviceListExpanded = "is_paired_device_list_expanded";

const _secretKey = "secret_key";
const _deviceIdKey = "device_id";
const _pairedDevicesKey = "paired_devices";

class LocalStorage {
  final SharedPreferences _preferences = GetItHelper.i<SharedPreferences>();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool getFoundDeviceListExpanded() {
    return _preferences.getBool(_isFoundDeviceListExpanded) ?? true;
  }

  Future<void> setFoundDeviceListExpanded(bool expanded) async {
    await _preferences.setBool(_isFoundDeviceListExpanded, expanded);
  }

  bool getPairedDeviceListExpanded() {
    return _preferences.getBool(_isPairedDeviceListExpanded) ?? true;
  }

  Future<void> setPairedDeviceListExpanded(bool expanded) async {
    await _preferences.setBool(_isPairedDeviceListExpanded, expanded);
  }



  bool isFirstLaunch() {
    return _preferences.getBool(_isFirstLaunchKey) ?? true;
  }

  Future<void> setFirstLaunch() async {
    await _preferences.setBool(_isFirstLaunchKey, false);
  }



  Future<void> setSecretKey() async {
    String secretKey = const Uuid().v4();
    await _storage.write(key: _secretKey, value: secretKey);
  }

  Future<String> getSecretKey() async {
    return (await _storage.read(key: _secretKey))!;
  }

  Future<void> setDeviceId() async {
    String deviceId = const Uuid().v4();
    await _preferences.setString(_deviceIdKey, deviceId);
  }

  String getDeviceId() {
    return _preferences.getString(_deviceIdKey)!;
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
    await _preferences.clear();
  }



  Future<List<DeviceInfo>> getPairedDevices() async {
    String? listJsonString = (await _storage.read(key: _pairedDevicesKey));
    if (listJsonString == null) return [];
    return DeviceInfo.fromJsonList(listJsonString);
  }

  Future<DeviceInfo?> getPairedDevice(String? id) async {
    if (id == null) return null;
    List<DeviceInfo> devices = (await getPairedDevices()).where((element) => element.id == id).toList();
    return devices.isEmpty ? null : devices.first;
  }

  Future<void> _savePairedDevices(List<DeviceInfo> list) async {
    String json = jsonEncode(list.map((e) => e.toJsonString()).toList());
    await _storage.write(key: _pairedDevicesKey, value: json);
  }

  Future<void> addPairedDevice(DeviceInfo pairDeviceInfo) async {
    List<DeviceInfo> pairDevices = await getPairedDevices();
    if (pairDevices.containsSameDeviceId(pairDeviceInfo)) return;

    pairDevices.add(pairDeviceInfo);
    await _savePairedDevices(pairDevices);
  }

  Future<void> updatePairedDevice(DeviceInfo pairDeviceInfo) async {
    List<DeviceInfo> pairDevices = await getPairedDevices();
    int deviceInfoIndex = pairDevices.findIndexWithDeviceId(pairDeviceInfo);
    if (deviceInfoIndex < 0 || pairDevices[deviceInfoIndex] == pairDeviceInfo) return;

    pairDevices[deviceInfoIndex] = pairDeviceInfo;

    await _savePairedDevices(pairDevices);
  }

  Future<void> deletePairedDevice(DeviceInfo pairDeviceInfo) async {
    List<DeviceInfo> pairDevices = await getPairedDevices();
    pairDevices.removeWhere((e) => e.id == pairDeviceInfo.id);
    await _savePairedDevices(pairDevices);
  }
}
