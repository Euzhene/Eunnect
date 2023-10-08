import 'dart:convert';

import 'package:eunnect/helpers/get_it_helper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/pair_device_info.dart';

const _isFirstLaunchKey = "is_first_launch";
const _secretKey = "secret_key";
const _deviceIdKey = "device_id";
const _pairedDevicesKey = "paired_devices";

class LocalStorage {
  final SharedPreferences _preferences = GetItHelper.i<SharedPreferences>();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

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

  Future<Set<PairDeviceInfo>> getPairedDevices() async {
    String? listJsonString = (await _storage.read(key: _pairedDevicesKey));
    if (listJsonString == null) return {};
    return PairDeviceInfo.fromListJson(listJsonString).toSet();
  }

  Future<void> _savePairedDevices(Set<PairDeviceInfo> list) async {
    String json = jsonEncode(list.map((e) => e.toJsonString()).toList());
    await _storage.write(key: _pairedDevicesKey, value: json);
  }

  Future<List<PairDeviceInfo>> addPairedDevice(PairDeviceInfo pairDeviceInfo) async {
    Set<PairDeviceInfo> pairDevices = await getPairedDevices();
    pairDevices.add(pairDeviceInfo);
    await _savePairedDevices(pairDevices);
    return pairDevices.toList();
  }

  Future<List<PairDeviceInfo>> deletePairedDevice(PairDeviceInfo pairDeviceInfo) async {
    Set<PairDeviceInfo> pairDevices = await getPairedDevices();
    pairDevices.removeWhere((e) => e.senderId == pairDeviceInfo.senderId);
    await _savePairedDevices(pairDevices);
    return pairDevices.toList();
  }
}
