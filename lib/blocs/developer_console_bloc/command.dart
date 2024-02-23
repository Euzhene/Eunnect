import 'package:eunnect/blocs/developer_console_bloc/developer_console_bloc.dart';
import 'package:f_logs/f_logs.dart';

abstract class Command {
  final String command;
  final String description;

  Command({required this.command, required this.description});

  Future<void> execute(DeveloperConsoleBloc bloc);
}

class ClearCommand extends Command {
  ClearCommand():super(command: "clear", description: "Стирает все с консоли");

  @override
  Future<void> execute(DeveloperConsoleBloc bloc) async {
    await FLog.clearLogs();
    await bloc.updateLogs();
  }
}

