import 'package:eunnect/blocs/developer_console_bloc/developer_console_bloc.dart';
import 'package:eunnect/helpers/log_helper.dart';
import 'package:f_logs/f_logs.dart';
import 'package:sembast/sembast.dart';
import 'package:intl/intl.dart';

abstract class Command {
  final String command;
  final String description;

  Command({required this.command, required this.description});

  Future<void> execute({required DeveloperConsoleBloc bloc, required String text});

  bool validate(String text) => text == command;
}

class ClearCommand extends Command {
  ClearCommand() : super(command: "clear", description: "Стирает все с консоли");

  @override
  Future<void> execute({required DeveloperConsoleBloc bloc, required String text}) async {
    bloc.textController.text = "";
    await FLog.clearLogs();
    await bloc.updateLogs();
  }
}

class ResetCommand extends Command {
  ResetCommand() : super(command: "reset", description: "Сбрасывает все фильтры");

  @override
  Future<void> execute({required DeveloperConsoleBloc bloc, required String text}) async {
    bloc.textController.text = "";
    bloc.logFilters.clear();
    await bloc.updateLogs();
  }
}
abstract class SearchCommand extends Command {
  final String specSymbol;
  SearchCommand(this.specSymbol, String description): super(command: "$specSymbol<your text>", description: description);

  Filter getFilter(String text);

  @override
  Future<void> execute({required DeveloperConsoleBloc bloc, required String text}) async {
    text = text.substring(1);
    bloc.logFilters.clear();
    bloc.logFilters.addAll([getFilter(text)]);
    await bloc.updateLogs();
  }



  @override
  bool validate(String text) {
    return text.length > 1 && text.startsWith(specSymbol);
  }
}

abstract class TimestampCommand extends Command {
  final String specSymbol;

  TimestampCommand(this.specSymbol, String description)
      : super(command: "${specSymbol}hh:mm", description: "Фильтрует логи, которые появились $description");

  List<Filter> getFilters(DateTime filterDate);

  @override
  Future<void> execute({required DeveloperConsoleBloc bloc, required String text}) async {
    text = text.substring(1);
    List<String> split = text.split(":");
    int hours = int.parse(split[0]);
    int minutes = int.parse(split[1]);
    DateTime curDate = DateTime.now();
    DateTime filterDate = DateTime(curDate.year, curDate.month, curDate.day, hours, minutes);

    List<Filter> filters = getFilters(filterDate);
    bloc.logFilters.clear();
    bloc.logFilters.addAll(filters);
    await bloc.updateLogs();
  }

  @override
  bool validate(String text) {
    if (text.length > 6) return false;
    return text.contains(RegExp(specSymbol + r'\d\d:\d\d'));
  }
}

class ExcludeCommand extends SearchCommand {
  ExcludeCommand(): super("-", "Убирает логи, которые содержат заданный текст сразу после символа '-'");

  @override
  Filter getFilter(String text) => Filter.not(Filter.matches(DBConstants.FIELD_TEXT, text));
}

class IncludeCommand extends SearchCommand {
  IncludeCommand(): super("+", "Показывает логи, которые содержат заданный текст сразу после символа '+'");

  @override
  Filter getFilter(String text) =>Filter.matches(DBConstants.FIELD_TEXT, text);
}

class GreaterThanTimestampCommand extends TimestampCommand {
  GreaterThanTimestampCommand() : super(">", "позже заданного времени");

  @override
  List<Filter> getFilters(DateTime filterDate) =>
      [Filter.greaterThanOrEquals(DBConstants.FIELD_TIMESTAMP, DateFormat(logTimestampFormat).format(filterDate))];
}

class LessThanTimestampCommand extends TimestampCommand {
  LessThanTimestampCommand() : super("<", "раньше заданного времени");

  @override
  List<Filter> getFilters(DateTime filterDate) =>
      [Filter.lessThanOrEquals(DBConstants.FIELD_TIMESTAMP, DateFormat(logTimestampFormat).format(filterDate))];
}

class EqualTimestampCommand extends TimestampCommand {
  EqualTimestampCommand() : super("=", "в заданное время");

  @override
  List<Filter> getFilters(DateTime filterDate) => [
    Filter.lessThan(DBConstants.FIELD_TIMESTAMP, DateFormat(logTimestampFormat).format(filterDate.add(const Duration(minutes: 1)))),
    Filter.greaterThanOrEquals(DBConstants.FIELD_TIMESTAMP, DateFormat(logTimestampFormat).format(filterDate)),
      ];
}
