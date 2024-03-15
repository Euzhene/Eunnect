import 'dart:io' hide SocketMessage;

import 'package:eunnect/blocs/main_bloc/main_bloc.dart';
import 'package:eunnect/helpers/get_it_helper.dart';
import 'package:eunnect/helpers/rtc_helper.dart';
import 'package:eunnect/models/socket/custom_client_socket.dart';
import 'package:eunnect/models/socket/socket_message.dart';
import 'package:eunnect/repo/local_storage.dart';
import 'package:f_logs/f_logs.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../models/device_info/device_info.dart';
import '../../models/device_info/device_type.dart';
import '../../models/socket/socket_command.dart';

part 'device_actions_state.dart';

const String _deviceKey = pairedDevicesKey;

class ActionsBloc extends Cubit<DeviceActionsState> {
  ActionsBloc({required this.deviceInfo, required bool deviceAvailable})
      : isAndroidDeviceType = deviceInfo.type == DeviceType.phone || deviceInfo.type == DeviceType.tablet,
        super(deviceAvailable ? DeviceActionsState() : UnreachableDeviceState()) {
    _init();
  }

  final MainBloc _mainBloc = GetItHelper.i<MainBloc>();
  final LocalStorage _storage = GetItHelper.i<LocalStorage>();
  final DeviceInfo myDeviceInfo = GetItHelper.i<DeviceInfo>();
  final CustomClientSocket clientSocket = GetItHelper.i<CustomClientSocket>();
  final RtcHelper rtcHelper = GetItHelper.i<RtcHelper>();
  final DeviceInfo deviceInfo;

  RTCVideoRenderer? rtcVideoRenderer;

  final bool isAndroidDeviceType;

  Future<void> _init() async {
    tryConnectToDevice();
  }

  Future<void> tryConnectToDevice() async {
    try {
      await clientSocket.checkConnection(deviceInfo.ipAddress);
      if (!isClosed) emit(DeviceActionsState());
    } catch (e, st) {
      if (!isClosed) emit(UnreachableDeviceState());
      FLog.error(text: e.toString(), stacktrace: st);
    }
  }

  void onSendBuffer() async {
    try {
      if (_checkLoadingState()) return;
      emit(LoadingState());

      String type = Clipboard.kTextPlain;
      String? text = (await Clipboard.getData(type))?.text;
      if ((text ?? "").isEmpty) {
        _mainBloc.emitDefaultError("Буфер не содержит текст");
        emit(DeviceActionsState());
        return;
      }
      SecureSocket socket = await clientSocket.connect(deviceInfo.ipAddress);
      await clientSocket.sendBuffer(socket: socket, text: text!);
      ServerMessage socketMessage = ServerMessage.fromUInt8List(await socket.single);

      await _handleServerResponse(serverMessage: socketMessage, successMessage: "Буфер успешно передан");
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      _mainBloc.emitDefaultError("Ошибка при передаче буфера");
      emit(DeviceActionsState());
    }
  }

  void onSendCommand({required SocketCommand command}) async {
    try {
      if (_checkLoadingState()) return;
      emit(LoadingState());

      SecureSocket socket = await clientSocket.connect(deviceInfo.ipAddress);
      await clientSocket.sendCommand(socket: socket, commandId: command.id);
      ServerMessage socketMessage = ServerMessage.fromUInt8List(await socket.single);
      await _handleServerResponse(serverMessage: socketMessage, successMessage: "Команда выполнена");
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      _mainBloc.emitDefaultError("Ошибка во время передачи команды");
      emit(DeviceActionsState());
    }
  }


  void onSendFile() async {
    try {
      if (_checkLoadingState()) return;

      FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: false);
      if (result == null) return;
      String? path = result.files.single.path;
      if (path == null) return;

      File file = File(path);
      Uint8List bytes = await file.readAsBytes();

      emit(LoadingState());

      String fileName = file.path.substring(file.path.lastIndexOf(Platform.pathSeparator) + 1);

      SecureSocket socket = await clientSocket.connect(deviceInfo.ipAddress);

      ServerMessage? resultMessage = await clientSocket.sendFile(socket: socket, bytes: bytes, fileName: fileName);

      resultMessage ??= ServerMessage.fromUInt8List(await socket.single);
      await _handleServerResponse(serverMessage: resultMessage, successMessage: "Файл успешно передан");
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      _mainBloc.emitDefaultError("Ошибка при передаче файла");
      emit(DeviceActionsState());
    }
  }

  Future<void> onBreakPairing() async {
    await _storage.deleteBaseDevice(deviceInfo, _deviceKey);
  }

  Future<void> onEnableTranslation() async {
      await rtcHelper.initForServer(myDeviceInfo);
  }

  Future<void> onGetTranslation() async {
    rtcVideoRenderer = null;
    rtcHelper.onVideoRendererUpdated = (RTCVideoRenderer renderer) {
      rtcVideoRenderer = renderer;
      emit(DeviceActionsState());
    };
    await rtcHelper.initForClient(pairedDeviceInfo: deviceInfo);
  }

  ///возвращает true в случае если сервер отправляет статус-ошибку, иначе false
  Future<bool> _handleServerResponse({required ServerMessage serverMessage, String? successMessage}) async {
    if (!serverMessage.isErrorStatus) {
      if (successMessage != null) _mainBloc.emitDefaultSuccess(successMessage);
      emit(DeviceActionsState());
      return false;
    }

    _mainBloc.emitDefaultError(serverMessage.getError!);

    if (serverMessage.status == 101) emit(DeletedDeviceState());

    emit(DeviceActionsState());
    return true;
  }

  bool _checkLoadingState() {
    bool res = state.isLoading;
    if (res) _mainBloc.emitDefaultError("Другая команда в процессе выполнения");
    return res;
  }


}
