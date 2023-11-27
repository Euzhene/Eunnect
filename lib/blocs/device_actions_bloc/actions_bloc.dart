import 'dart:io' hide SocketMessage;

import 'package:eunnect/blocs/main_bloc/main_bloc.dart';
import 'package:eunnect/helpers/get_it_helper.dart';
import 'package:eunnect/models/socket/custom_client_socket.dart';
import 'package:eunnect/models/socket/socket_message.dart';
import 'package:eunnect/repo/local_storage.dart';
import 'package:f_logs/f_logs.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/device_info.dart';
import '../../models/socket/custom_server_socket.dart';

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
      await CustomClientSocket.checkConnection(deviceInfo.ipAddress);
      if (!isClosed) emit(DeviceActionsState());
    } catch (e, st) {
      if (!isClosed) emit(UnreachableDeviceState());
      FLog.error(text: e.toString(), stacktrace: st);
    }
  }

  void onSendBuffer() async {
    try {
      if (checkLoadingState()) return;
      emit(LoadingState());

      String type = Clipboard.kTextPlain;
      String? text = (await Clipboard.getData(type))?.text;
      if ((text ?? "").isEmpty)
        _mainBloc.emitDefaultError("Буфер не содержит текст");
      else {
        Socket socket = await CustomClientSocket.connect(deviceInfo.ipAddress);
        await CustomClientSocket.sendBuffer(socket: socket, text: text!);
        ServerMessage socketMessage = ServerMessage.fromUInt8List(await socket.single);

        await _handleServerResponse(serverMessage: socketMessage, successMessage: "Буфер успешно передан");
      }
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      _mainBloc.emitDefaultError("Ошибка при передаче буфера");
      emit(DeviceActionsState());
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
      if (checkLoadingState()) return;
      emit(LoadingState());

      Socket socket = await CustomClientSocket.connect(deviceInfo.ipAddress);
      await CustomClientSocket.sendCommand(socket: socket, commandName: commandName);
      ServerMessage socketMessage = ServerMessage.fromUInt8List(await socket.single);
      await _handleServerResponse(serverMessage: socketMessage, successMessage: "Команда выполнена");

    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      _mainBloc.emitDefaultError("Ошибка во время передачи команды");
      emit(DeviceActionsState());
    }
  }
  bool checkLoadingState() {
    bool res = state.isLoading;
    if (res) _mainBloc.emitDefaultError("Другая команда в процессе выполнения");
    return res;
  }
  ///возвращает true в случае если сервер отправляет статус-ошибку, иначе false
  Future<bool> _handleServerResponse({required ServerMessage serverMessage, required String successMessage}) async {
    if (!serverMessage.isErrorStatus) {
      _mainBloc.emitDefaultSuccess(successMessage);
      emit(DeviceActionsState());
      return false;
    }

    _mainBloc.emitDefaultError(serverMessage.getError!);

    if (serverMessage.status == 101) emit(DeletedDeviceState());

    return true;
  }

  void onSendFile() async {
    try {
      if (checkLoadingState()) return;

      FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: false);
      if (result == null) return;
      String? path = result.files.single.path;
      if (path == null) return;

      File file = File(path);
      Uint8List bytes = await file.readAsBytes();

      emit(LoadingState());

      String fileName = file.path.substring(file.path.lastIndexOf(Platform.pathSeparator) + 1);

      Socket socket = await CustomClientSocket.connect(deviceInfo.ipAddress);

      ServerMessage? resultMessage = await CustomClientSocket.sendFile(socket: socket, bytes: bytes, fileName: fileName);

      resultMessage ??= ServerMessage.fromUInt8List(await socket.single);
      await _handleServerResponse(serverMessage: resultMessage, successMessage: "Файл успешно передан");
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      _mainBloc.emitDefaultError("Ошибка при передаче файла");
      emit(DeviceActionsState());
    }
  }

  Future<void> onBreakPairing() async {
    await _storage.deletePairedDevice(deviceInfo);
  }
}
