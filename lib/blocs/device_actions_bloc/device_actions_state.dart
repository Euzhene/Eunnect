part of 'actions_bloc.dart';

class DeviceActionsState {
  final int sentBytes;
  final int allFileBytes;

  final bool inProcess;


  double get progressValue => sentBytes / allFileBytes;

  const DeviceActionsState({this.sentBytes = 0, this.inProcess = false,this.allFileBytes = 0,});

  DeviceActionsState copyWith({
    int? sentBytes,
    int? allFileBytes,
    bool? inProcess,
  }) =>
      DeviceActionsState(
        sentBytes: sentBytes ?? this.sentBytes,
        inProcess: inProcess ?? this.inProcess,
        allFileBytes: allFileBytes ?? this.allFileBytes,
      );
}
