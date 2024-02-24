import 'package:eunnect/blocs/main_bloc/main_bloc.dart';
import 'package:eunnect/helpers/get_it_helper.dart';
import 'package:eunnect/models/device_info/device_type.dart';
import 'package:eunnect/models/socket/socket_command.dart';
import 'package:eunnect/repo/local_storage.dart';
import 'package:f_logs/f_logs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'choose_device_type.dart';

part 'command_state.dart';

class CommandBloc extends Cubit<CommandState> {
  final LocalStorage _storage = GetItHelper.i<LocalStorage>();
  final MainBloc _mainBloc = GetItHelper.i<MainBloc>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController commandController = TextEditingController();
  final List<ChooseDeviceType> deviceTypeList = [
    ChooseDeviceType(type: DeviceType.windows, isAdded: false),
    ChooseDeviceType(type: DeviceType.linux, isAdded: false),
  ];

  CommandBloc() : super(CommandState());

  bool get _isNameValid => nameController.text.trim().isNotEmpty;
  bool get _isDescriptionValid => true;
  bool get _isCommandValid => commandController.text.trim().isNotEmpty;
  bool get _isDeviceTypeListValid => deviceTypeList.where((e) => e.isAdded).isNotEmpty;
  bool get isAllValid => _isNameValid && _isDescriptionValid && _isCommandValid && _isDeviceTypeListValid;

  void onSelectDeviceType(ChooseDeviceType type) {
    int index = deviceTypeList.indexOf(type);
    ChooseDeviceType foundType = deviceTypeList[index];
    deviceTypeList[index] = foundType.copyWith(isAdded: !foundType.isAdded);
    emit(CommandState());
  }

  Future<void> onAddCommand() async {
    try {
      if (!isAllValid) return;

      String name = nameController.text.trim();
      String? description = descriptionController.text.trim();
      if (description.isEmpty) description = null;
      String command = commandController.text.trim();

      SocketCommand socketCommand = SocketCommand(
        id: const Uuid().v4(),
        name: name,
        description: description,
        command: command,
        deviceTypeList: deviceTypeList.where((e) => e.isAdded).map((e) => e.type).toList(),
      );
      await _storage.addSocketCommand(socketCommand);
      _mainBloc.emitDefaultSuccess("Команда создана");
      emit(CloseScreen());
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      _mainBloc.emitDefaultError(e.toString());
    }
  }

  void onTextChanged() => emit(CommandState());
}
