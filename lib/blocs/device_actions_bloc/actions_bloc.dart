import 'dart:io' hide SocketMessage;
import 'dart:math';

import 'package:eunnect/blocs/main_bloc/main_bloc.dart';
import 'package:eunnect/helpers/get_it_helper.dart';
import 'package:f_logs/f_logs.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/custom_message.dart';
import '../../models/custom_server_socket.dart';
import '../../models/device_info.dart';

part 'device_actions_state.dart';

class ActionsBloc extends Cubit<DeviceActionsState> {
  final MainBloc _mainBloc = GetItHelper.i<MainBloc>();
  final DeviceInfo deviceInfo;

  ActionsBloc({required this.deviceInfo, required bool deviceAvailable}) : super(deviceAvailable ? DeviceActionsState() : UnreachableDeviceState()) {
    tryConnectDevice();
  }

  Future<void> tryConnectDevice() async {
    try {
      await (await Socket.connect(deviceInfo.ipAddress, port)).close(); //check we can work with another device
      emit(DeviceActionsState());
    } catch (e, st) {
      emit(UnreachableDeviceState());
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
        Socket socket = await Socket.connect(deviceInfo.ipAddress, port);
        socket.add(SocketMessage(call: sendBufferCall, data: text, deviceId: deviceInfo.id).toUInt8List());
        await socket.close();
        SocketMessage socketMessage = SocketMessage.fromUInt8List(await socket.single);
        socket.destroy();
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

  String getFileSizeString({required int bytes, int decimals = 0}) {
    const suffixes = ["Б", "КБ", "МБ", "ГБ"];
    if (bytes == 0) return '0${suffixes[0]}';
    var i = (log(bytes) / log(1024)).floor();
    return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) + suffixes[i];
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

      SendingFileState _state = SendingFileState(allFileBytes: bytes.lengthInBytes);
      emit(_state);
      Socket socket = await Socket.connect(deviceInfo.ipAddress, port);
      String fileName = file.path.substring(file.path.lastIndexOf(Platform.pathSeparator) + 1);

      SocketMessage initialMessage = SocketMessage(
          call: sendFileCall, deviceId: deviceInfo.id, data: FileMessage(bytes: [], filename: fileName).toJsonString());
      socket.add(initialMessage.toUInt8List());
      socket.listen((event) {
        emit(_state.copyWith(sentBytes: event.lengthInBytes + _state.sentBytes));
      }, onDone: () {
        emit(DeviceActionsState());
        _mainBloc.emitDefaultSuccess("Файл успешно передан");
      });

      await Future.delayed(const Duration(seconds: 1));
      socket.add(bytes);
      await socket.close();
    } catch (e, st) {
      emit(DeviceActionsState());
      FLog.error(text: e.toString(), stacktrace: st);
      _mainBloc.emitDefaultError("Ошибка при передаче файла");
    }
  }
}
