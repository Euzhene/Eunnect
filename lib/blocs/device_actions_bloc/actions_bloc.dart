import 'dart:io' hide SocketMessage;

import 'package:eunnect/blocs/main_bloc/main_bloc.dart';
import 'package:eunnect/helpers/get_it_helper.dart';
import 'package:eunnect/models/custom_client_socket.dart';
import 'package:eunnect/repo/local_storage.dart';
import 'package:f_logs/f_logs.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/custom_message.dart';
import '../../models/custom_server_socket.dart';
import '../../models/device_info.dart';

part 'device_actions_state.dart';

class ActionsBloc extends Cubit<DeviceActionsState> {
  ActionsBloc({required this.deviceInfo, required bool deviceAvailable})
      : isAndroidDeviceType = deviceInfo.type == DeviceType.phone || deviceInfo.type == DeviceType.tablet,
        super(deviceAvailable ? DeviceActionsState() : UnreachableDeviceState()) {
    tryConnectToDevice();
  }

  final MainBloc _mainBloc = GetItHelper.i<MainBloc>();
  final LocalStorage _storage = GetItHelper.i<LocalStorage>();
  final DeviceInfo myDeviceInfo = GetItHelper.i<DeviceInfo>();
  final DeviceInfo deviceInfo;

  final bool isAndroidDeviceType;


  Future<void> tryConnectToDevice() async {
    try {
      (await Socket.connect(deviceInfo.ipAddress, port)).destroy(); //check we can work with another device
      if (!isClosed) emit(DeviceActionsState());
    } catch (e, st) {
      if (!isClosed) emit(UnreachableDeviceState());
      FLog.error(text: e.toString(), stacktrace: st);
    }
  }

  void onSendBuffer() async {
    try {
      if (state.isSendingFile) {
        _mainBloc.emitDefaultError("Другой файл в процессе передачи");
        return;
      }

      String type = Clipboard.kTextPlain;
      String? text = (await Clipboard.getData(type))?.text;
      if ((text ?? "").isEmpty)
        _mainBloc.emitDefaultError("Буфер не содержит текст");
      else {
        Socket socket = await CustomClientSocket.connect(deviceInfo.ipAddress);
        await CustomClientSocket.sendBuffer(socket: socket, text: text!);
        SocketMessage socketMessage = SocketMessage.fromUInt8List(await socket.single);
        if (socketMessage.error != null) {
          _mainBloc.emitDefaultError(socketMessage.error!);
          return;
        }
        _mainBloc.emitDefaultSuccess("Буфер успешно передан");
      }
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      _mainBloc.emitDefaultError("Ошибка при передаче буфера");
    }
  }

  void onSendRestartCommand() {
    _onSendCommand(commandName: pcRestartState);
  }

  void onSendSleepCommand() {
    _onSendCommand(commandName: pcSleepState);
  }

  void onSendShutDownCommand() {
    _onSendCommand(commandName: pcShutDownState);
  }

  void _onSendCommand({required String commandName}) async {
    try {
      Socket socket = await CustomClientSocket.connect(deviceInfo.ipAddress);
      await CustomClientSocket.sendCommand(socket: socket, commandName: commandName);
      SocketMessage socketMessage = SocketMessage.fromUInt8List(await socket.single);
      if (socketMessage.error != null) {
        _mainBloc.emitDefaultError(socketMessage.error!);
        return;
      }
      _mainBloc.emitDefaultSuccess("Команда выполнена");
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      _mainBloc.emitDefaultError("Ошибка во время передачи команды");
    }
  }

  void onSendFile() async {
    try {
      if (state.isSendingFile) {
        _mainBloc.emitDefaultError("Файл в процессе передачи");
        return;
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: false);
      if (result == null) return;
      String? path = result.files.single.path;
      if (path == null) return;

      File file = File(path);
      Uint8List bytes = await file.readAsBytes();

      emit(SendingFileState());

      String fileName = file.path.substring(file.path.lastIndexOf(Platform.pathSeparator) + 1);

      Socket socket = await CustomClientSocket.connect(deviceInfo.ipAddress);

      await CustomClientSocket.sendFile(socket: socket, bytes: bytes, fileName: fileName);

      SocketMessage resultMessage = SocketMessage.fromUInt8List(await socket.single);
      if (resultMessage.error != null)
        _mainBloc.emitDefaultError(resultMessage.error!);
      else
        _mainBloc.emitDefaultSuccess("Файл успешно передан");
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      _mainBloc.emitDefaultError("Ошибка при передаче файла");
    }finally{
      emit(DeviceActionsState());
    }
  }

  Future<void> onBreakPairing() async {
    await _storage.deletePairedDevice(deviceInfo);
  }
}
