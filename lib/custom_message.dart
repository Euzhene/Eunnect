
class IsolateMessage {
  final ErrorMessage? errorMessage;
  final bool done;
  final dynamic data;

  IsolateMessage({this.errorMessage, this.done = false, this.data});
}


class ErrorMessage {
  final String shortError;
  final Object? error;
  final StackTrace? stackTrace;

  ErrorMessage({required this.shortError, this.error, this.stackTrace});
}