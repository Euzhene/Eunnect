import 'dart:async';

import 'package:eunnect/blocs/developer_console_bloc/command.dart';
import 'package:eunnect/blocs/main_bloc/main_bloc.dart';
import 'package:eunnect/helpers/get_it_helper.dart';
import 'package:f_logs/f_logs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'developer_console_state.dart';

class DeveloperConsoleBloc extends Cubit<DeveloperConsoleState> {
  final MainBloc _mainBloc = GetItHelper.i<MainBloc>();
  final List<Command> commands = [ClearCommand()];
  final TextEditingController controller = TextEditingController();
  late final Timer _timer;
  final List<Log> logs = [];

  DeveloperConsoleBloc() : super(LoadingConsoleState()) {
    _listenToLogs();
  }

  bool get isTextValid => controller.text.trim().isNotEmpty;

  Future<void> onExecuteCommand() async {
    if (!isTextValid) return;

    String text = controller.text.trim().toLowerCase();

    List<Command> foundCommands = commands.where((c) => c.command == text).toList();
    if (foundCommands.isEmpty) {
      _mainBloc.emitDefaultError("Неизвестная команда");
      return;
    }
    await commands.first.execute(this);
  }

  void onChangedText() {
    emit(state.copyWith());
  }

  Future<void> updateLogs() async {
    logs.clear();
    logs.addAll(await FLog.getAllLogs());
    emit(DeveloperConsoleState());
  }

  void _listenToLogs() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      await updateLogs();
    });
  }

  @override
  Future<void> close() {
    _timer.cancel();
    return super.close();
  }
}
