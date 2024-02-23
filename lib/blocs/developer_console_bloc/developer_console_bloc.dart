import 'dart:async';

import 'package:eunnect/blocs/developer_console_bloc/command.dart';
import 'package:eunnect/blocs/main_bloc/main_bloc.dart';
import 'package:eunnect/helpers/get_it_helper.dart';
import 'package:f_logs/f_logs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sembast/sembast.dart';


part 'developer_console_state.dart';

class DeveloperConsoleBloc extends Cubit<DeveloperConsoleState> {
  final MainBloc _mainBloc = GetItHelper.i<MainBloc>();
  final List<Command> commands = [ClearCommand(), GreaterThanTimestampCommand(), LessThanTimestampCommand(), EqualTimestampCommand()];
  final TextEditingController textController = TextEditingController();
  final ScrollController logsScrollController = ScrollController();
  late final Timer _timer;
  final List<Log> logs = [];
  final List<Filter> logFilters = [];

  bool haveNewLogs = false;

  DeveloperConsoleBloc() : super(LoadingConsoleState()) {
    _listenToLogs();
  }

  bool get isTextValid => textController.text.trim().isNotEmpty;
  bool get _isAtTheBottom => logsScrollController.position.maxScrollExtent - logsScrollController.offset <= 50;

  Future<void> onExecuteCommand() async {
    if (!isTextValid) return;

    String text = textController.text.trim().toLowerCase();

    List<Command> foundCommands = commands.where((c) => c.validate(text)).toList();
    if (foundCommands.isEmpty) {
      _mainBloc.emitDefaultError("Неизвестная команда");
      return;
    }
    try {
      await foundCommands.first.execute(bloc: this, text: text);
    }catch(e,st) {
      FLog.error(text: e.toString(), stacktrace: st);
    _mainBloc.emitDefaultError(e.toString());

    }
  }

  void onChangedText() {
    emit(state.copyWith());
  }

  Future<void> updateLogs() async {
    int oldLogsLength = logs.length;
    logs.clear();
    logs.addAll(await FLog.getAllLogsByCustomFilter(filters: logFilters));
    if (logsScrollController.hasClients) {
      if (_isAtTheBottom) onMoveToBottom();
      else if(!haveNewLogs) haveNewLogs = oldLogsLength != logs.length;
    }
    emit(DeveloperConsoleState());
  }

  void onMoveToBottom() {
    ScrollPosition scrollPosition = logsScrollController.position;
    logsScrollController.animateTo(
        scrollPosition.viewportDimension + scrollPosition.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.linear);

    haveNewLogs = false;
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
