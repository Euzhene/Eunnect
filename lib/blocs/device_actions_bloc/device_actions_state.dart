part of 'actions_bloc.dart';

class DeviceActionsState {
  bool get isSendingFile => this is SendingFileState;
}

class SendingFileState extends DeviceActionsState {
  SendingFileState({
    this.sentBytes = 0,
    this.allFileBytes = 0,
  });

  final int sentBytes;
  final int allFileBytes;

  double get progressValue => sentBytes / allFileBytes;

  SendingFileState copyWith({
    int? sentBytes,
  }) =>
      SendingFileState(
        sentBytes: sentBytes ?? this.sentBytes,
        allFileBytes: this.allFileBytes,
      );
}
