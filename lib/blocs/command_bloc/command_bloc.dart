import 'dart:io';

import 'package:eunnect/blocs/main_bloc/main_bloc.dart';
import 'package:eunnect/helpers/get_it_helper.dart';
import 'package:eunnect/models/socket/socket_command.dart';
import 'package:f_logs/f_logs.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/device_info/device_info.dart';
import '../../models/socket/custom_client_socket.dart';
import '../../models/socket/socket_message.dart';

part 'command_state.dart';

class CommandBloc extends Cubit<CommandState> {
  final MainBloc _mainBloc = GetItHelper.i<MainBloc>();
  final CustomClientSocket clientSocket = GetItHelper.i<CustomClientSocket>();
  final DeviceInfo myDeviceInfo = GetItHelper.i<DeviceInfo>();
  final DeviceInfo deviceInfo;

  List<SocketCommand> commands = [];


  CommandBloc({required this.deviceInfo}) : super(LoadingCommandState()) {
    _getCommands();
  }


  Future<void> onSendCommand(SocketCommand command) async {
    try {
      SecureSocket socket = await clientSocket.connect(deviceInfo.ipAddress);
      await clientSocket.sendCommand(socket: socket, commandId: command.id);
    }catch(e,st) {
      _mainBloc.emitDefaultError(e.toString());
      FLog.error(text: e.toString(), stacktrace: st);
    }
  }

  Future<void> _getCommands() async {
    try {
      emit(LoadingCommandState());

      SecureSocket socket = await clientSocket.connect(deviceInfo.ipAddress);
      ServerMessage serverMessage = await clientSocket.getCommands(socket: socket);

      bool isError = await _handleServerResponse(serverMessage: serverMessage);
      if (isError) return;

      commands = serverMessage.data == null ? [] : SocketCommand.fromJsonList(serverMessage.data!);
      if (!isClosed) emit(CommandState());
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      _mainBloc.emitDefaultError("Ошибка во время передачи команды");
      emit(NotGotCommandsState());
    }
  }


  ///возвращает true в случае если сервер отправляет статус-ошибку, иначе false
  Future<bool> _handleServerResponse({required ServerMessage serverMessage, String? successMessage}) async {
    if (!serverMessage.isErrorStatus) {
      if (successMessage != null) _mainBloc.emitDefaultSuccess(successMessage);
      emit(CommandState());
      return false;
    }

    _mainBloc.emitDefaultError(serverMessage.getError!);

    emit(NotGotCommandsState());
    return true;
  }

}
