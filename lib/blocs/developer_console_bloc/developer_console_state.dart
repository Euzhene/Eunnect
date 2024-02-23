part of 'developer_console_bloc.dart';

class DeveloperConsoleState {
  DeveloperConsoleState copyWith()=>DeveloperConsoleState();
}

class LoadingConsoleState extends DeveloperConsoleState {
  @override
  DeveloperConsoleState copyWith() => LoadingConsoleState();
}
