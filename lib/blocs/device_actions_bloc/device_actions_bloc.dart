import 'dart:io' hide SocketMessage;

import 'package:eunnect/blocs/main_bloc/main_bloc.dart';
import 'package:eunnect/helpers/get_it_helper.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/custom_message.dart';
import '../../models/custom_server_socket.dart';
import '../../models/pair_device_info.dart';

part 'device_actions_state.dart';

class DeviceActionsBloc extends Cubit<DeviceActionsState> {
  final MainBloc _mainBloc = GetItHelper.i<MainBloc>();
  final PairDeviceInfo deviceInfo;

  DeviceActionsBloc({required this.deviceInfo}) : super(DeviceActionsState());

  void onSendBuffer() async {
    String type = Clipboard.kTextPlain;
    String? text = (await Clipboard.getData(type))?.text;
    if ((text ?? "").isEmpty)
      _mainBloc.emitDefaultError("Буфер не содержит текст");
    else {
      Socket socket = await Socket.connect(deviceInfo.deviceInfo.ipAddress, port);
      socket.add(SocketMessage(call: sendBufferCall, data: text, senderId: deviceInfo.senderId).toUInt8List());
      await socket.close();
      SocketMessage socketMessage = SocketMessage.fromUInt8List(await socket.single);
      socket.destroy();
      if (socketMessage.error != null) {
        _mainBloc.emitDefaultError(socketMessage.error!);
        return;
      }
      _mainBloc.emitDefaultSuccess("Буфер успешно передан");
    }
  }
}
