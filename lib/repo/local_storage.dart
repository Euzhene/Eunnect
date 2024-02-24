import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:eunnect/extensions.dart';
import 'package:f_logs/f_logs.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/device_info.dart';

const _isFirstLaunchKey = "is_first_launch";

const _isFoundDeviceListExpanded = "is_found_device_list_expanded";
const _isPairedDeviceListExpanded = "is_paired_device_list_expanded";
const _isDarkThemeKey = "is_dark_theme";
const _lastOpenDeviceKey = "last_open_device";

const _deviceIdKey = "device_id";
const _deviceNameKey = "device_name";
const _pairedDevicesKey = "paired_devices";
const _blockedDevicesKey = "blocked_devices";
const _privateKeyField = "private_key";
const _publicKeyField = "public_key";
const _certificateField = "certificate";

class LocalStorage {
  final SharedPreferences preferences;
  final FlutterSecureStorage secureStorage;

  LocalStorage({required this.preferences, required this.secureStorage});

  Future<String?> getPublicKey() {
    return secureStorage.read(key: _publicKeyField);
  }
  Future<void> setPublicKey(String publicKey) async {
    return secureStorage.write(key: _publicKeyField, value: publicKey);
  }
  Future<String?> getPrivateKey() {
    return secureStorage.read(key: _privateKeyField);
  }
  Future<void> setPrivateKey(String privateKey) {
    return secureStorage.write(key: _privateKeyField, value: privateKey);
  }

  Future<String?> getCertificate() {
    return secureStorage.read(key: _certificateField);
  }
  Future<void> setCertificate(String certificatePem) {
    return secureStorage.write(key: _certificateField, value: certificatePem);
  }


  bool getFoundDeviceListExpanded() {
    return preferences.getBool(_isFoundDeviceListExpanded) ?? true;
  }
  Future<void> setFoundDeviceListExpanded(bool expanded) async {
    await preferences.setBool(_isFoundDeviceListExpanded, expanded);
  }

  bool getPairedDeviceListExpanded() {
    return preferences.getBool(_isPairedDeviceListExpanded) ?? true;
  }
  Future<void> setPairedDeviceListExpanded(bool expanded) async {
    await preferences.setBool(_isPairedDeviceListExpanded, expanded);
  }

  bool isDarkTheme() {
    return preferences.getBool(_isDarkThemeKey) ?? false;
  }
  Future<void> setIsDarkTheme(bool isDarkTheme) async {
    await preferences.setBool(_isDarkThemeKey, isDarkTheme);
  }

  String? getLastOpenDevice() {
    return preferences.getString(_lastOpenDeviceKey);
  }
  Future<void> setLastOpenDevice(String? deviceId) async {
    if (deviceId == null) await preferences.remove(_lastOpenDeviceKey);
    else await preferences.setString(_lastOpenDeviceKey, deviceId);
  }

  bool isFirstLaunch() {
    return preferences.getBool(_isFirstLaunchKey) ?? true;
  }

  Future<void> setFirstLaunch([isFirstLaunch = false]) async {
    await preferences.setBool(_isFirstLaunchKey, isFirstLaunch);
  }


  Future<void> setDeviceId() async {
    String deviceId = const Uuid().v4();
    await preferences.setString(_deviceIdKey, deviceId);
  }
  String getDeviceId() {
    return preferences.getString(_deviceIdKey)!;
  }

  Future<void> setDeviceName(String deviceName) async {
    await preferences.setString(_deviceNameKey, deviceName);
  }

  Future<String> getDeviceName() async {
    String? deviceName = preferences.getString(_deviceNameKey);
    if (deviceName == null) {
      FLog.info(text: "device name was not set in the local storage. Setting a default one.");
      DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        deviceName = androidInfo.model;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        deviceName = iosInfo.name;
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfoPlugin.windowsInfo;
        deviceName = windowsInfo.computerName;
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfoPlugin.linuxInfo;
        deviceName = linuxInfo.prettyName;
      } else deviceName = "Unknown";
    }
    await setDeviceName(deviceName);
    return deviceName;
  }

  Future<void> clearAll() async {
    await secureStorage.deleteAll();
    await preferences.clear();
    FLog.trace(text: "the local storage was fully cleared");
  }



  Future<List<DeviceInfo>> getPairedDevices() async {
    String? listJsonString = (await secureStorage.read(key: _pairedDevicesKey));
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
    await secureStorage.write(key: _pairedDevicesKey, value: json);
    FLog.trace(text: "paired devices were saved");
  }

  Future<void> addPairedDevice(DeviceInfo pairDeviceInfo) async {
    List<DeviceInfo> pairDevices = await getPairedDevices();
    if (pairDevices.containsSameDeviceId(pairDeviceInfo)) return;

    pairDevices.add(pairDeviceInfo);
    await _savePairedDevices(pairDevices);
    FLog.trace(text: "a new paired device was added to the local storage");
  }

  Future<void> updatePairedDevice(DeviceInfo pairDeviceInfo) async {
    List<DeviceInfo> pairDevices = await getPairedDevices();
    int deviceInfoIndex = pairDevices.findIndexWithDeviceId(pairDeviceInfo);
    if (deviceInfoIndex < 0 || pairDevices[deviceInfoIndex] == pairDeviceInfo) return;

    pairDevices[deviceInfoIndex] = pairDeviceInfo;

    await _savePairedDevices(pairDevices);
    FLog.trace(text: "a paired device was updated to the local storage");
  }

  Future<void> deletePairedDevice(DeviceInfo pairDeviceInfo) async {
    List<DeviceInfo> pairDevices = await getPairedDevices();
    pairDevices.removeWhere((e) => e.id == pairDeviceInfo.id);
    await _savePairedDevices(pairDevices);
    FLog.trace(text: "a paired device was deleted from the local storage");
  }

  Future<List<DeviceInfo>> getBlockedDevices() async {
    String? listJsonString = (await secureStorage.read(key: _blockedDevicesKey));
    if (listJsonString == null) return [];
    return DeviceInfo.fromJsonList(listJsonString);
  }

  Future<DeviceInfo?> getBlockedDevice(String? id) async {
    if (id == null) return null;
    List<DeviceInfo> devices = (await getBlockedDevices()).where((element) => element.id == id).toList();
    return devices.isEmpty ? null : devices.first;
  }

  Future<void> _saveBlockedDevices(List<DeviceInfo> list) async {
    String json = jsonEncode(list.map((e) => e.toJsonString()).toList());
    await secureStorage.write(key: _blockedDevicesKey, value: json);
    FLog.trace(text: "blocked devices were saved");
  }

  Future<void> addBlockedDevice(DeviceInfo deviceInfo) async {
    List<DeviceInfo> blockedDevices = await getBlockedDevices();
    if (blockedDevices.containsSameDeviceId(deviceInfo)) return;

    blockedDevices.add(deviceInfo);
    await _saveBlockedDevices(blockedDevices);
    FLog.trace(text: "a new blocked device was added to the local storage");
  }

  Future<void> deleteBlockedDevice(DeviceInfo deviceInfo) async {
    List<DeviceInfo> blockedDevices = await getBlockedDevices();
    blockedDevices.removeWhere((e) => e.id == deviceInfo.id);
    await _saveBlockedDevices(blockedDevices);
    FLog.trace(text: "a blocked device was deleted from the local storage");
  }
}
