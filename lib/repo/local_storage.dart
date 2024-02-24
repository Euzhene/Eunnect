import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:eunnect/extensions.dart';
import 'package:eunnect/models/socket/socket_command.dart';
import 'package:f_logs/f_logs.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/device_info/device_info.dart';

const _isFirstLaunchKey = "is_first_launch";

const _isFoundDeviceListExpanded = "is_found_device_list_expanded";
const _isPairedDeviceListExpanded = "is_paired_device_list_expanded";
const _isDarkThemeKey = "is_dark_theme";
const _lastOpenDeviceKey = "last_open_device";
const commandsKey = "commands";

const _deviceIdKey = "device_id";
const _deviceNameKey = "device_name";
const pairedDevicesKey = "paired_devices";
const blockedDevicesKey = "blocked_devices";

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




  Future<List<DeviceInfo>> getBaseDevices(String deviceKey) async {
    String? listJsonString = (await secureStorage.read(key: deviceKey));
    if (listJsonString == null) return [];
    return DeviceInfo.fromJsonList(listJsonString);
  }

  Future<DeviceInfo?> getBaseDevice(String? id, String deviceKey) async {
    if (id == null) return null;
    List<DeviceInfo> devices = (await getBaseDevices(deviceKey)).where((element) => element.id == id).toList();
    return devices.isEmpty ? null : devices.first;
  }

  Future<void> saveBaseDevices(List<DeviceInfo> list, String deviceKey) async {
    String json = jsonEncode(list.map((e) => e.toJsonString()).toList());
    await secureStorage.write(key: deviceKey, value: json);
    FLog.trace(text: "$deviceKey devices were saved");
  }

  Future<void> addBaseDevice(DeviceInfo deviceInfo, String deviceKey) async {
    List<DeviceInfo> baseDevices = await getBaseDevices(deviceKey);
    if (baseDevices.containsSameDeviceId(deviceInfo)) return;

    baseDevices.add(deviceInfo);
    await saveBaseDevices(baseDevices, deviceKey);
    FLog.trace(text: "a new $deviceKey device was added to the local storage");
  }

  Future<void> updateBaseDevice(DeviceInfo deviceInfo, String deviceKey) async {
    List<DeviceInfo> baseDevices = await getBaseDevices(deviceKey);
    int deviceInfoIndex = baseDevices.findIndexWithDeviceId(deviceInfo);
    if (deviceInfoIndex < 0 || baseDevices[deviceInfoIndex] == deviceInfo) return;
    baseDevices[deviceInfoIndex] = deviceInfo;
    await saveBaseDevices(baseDevices, deviceKey);
    FLog.trace(text: "a $deviceKey device was updated to the local storage");
  }

  Future<void> deleteBaseDevice(DeviceInfo deviceInfo, String deviceKey) async {
    List<DeviceInfo> baseDevices = await getBaseDevices(deviceKey);
    baseDevices.removeWhere((e) => e.id == deviceInfo.id);
    await saveBaseDevices(baseDevices, deviceKey);
    FLog.trace(text: "a $deviceKey device was deleted from the local storage");
  }

  Future<List<SocketCommand>> getSocketCommands() async {
    String? listJsonString = (await secureStorage.read(key: commandsKey));
    if (listJsonString == null) return [];
    return SocketCommand.fromJsonList(listJsonString);
  }

  Future<SocketCommand?> getSocketCommand(String? id) async {
    if (id == null) return null;
    List<SocketCommand> commands = (await getSocketCommands()).where((element) => element.id == id).toList();
    return commands.isEmpty ? null : commands.first;
  }

  Future<void> saveSocketCommands(List<SocketCommand> list) async {
    String json = jsonEncode(list.map((e) => e.toJsonString()).toList());
    await secureStorage.write(key: commandsKey, value: json);
    FLog.trace(text: "socket commands were saved");
  }

  Future<void> addSocketCommand(SocketCommand command) async {
    List<SocketCommand> commands = await getSocketCommands();
    if (commands.where((e) => e.id == command.id).isNotEmpty) return;

    commands.add(command);
    await saveSocketCommands(commands);
    FLog.trace(text: "a new command was added to the local storage");
  }

  Future<void> updateSocketCommand(SocketCommand command) async {
    List<SocketCommand> commands = await getSocketCommands();
    int commandIndex = commands.indexWhere((e) => e.id == command.id);
    if (commandIndex < 0 || commands[commandIndex] == command) return;
    commands[commandIndex] = command;
    await saveSocketCommands(commands);
    FLog.trace(text: "a command was updated to the local storage");
  }

  Future<void> deleteSocketCommand(SocketCommand command) async {
    List<SocketCommand> commands = await getSocketCommands();
    commands.removeWhere((e) => e.id == command.id);
    await saveSocketCommands(commands);
    FLog.trace(text: "a command was deleted from the local storage");
  }


}
