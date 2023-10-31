
part of 'main_bloc.dart';

class MainState extends Equatable {

  @override
  List<Object?> get props => [];

}
class ErrorMainState extends MainState {
  final String error;

  ErrorMainState({required this.error});
}

class SuccessMainState extends MainState {
  final String message;

  SuccessMainState({required this.message});
}

class PairDialogState extends MainState {
  final DeviceInfo deviceInfo;

  PairDialogState({required this.deviceInfo});

  @override
  List<Object?> get props => [deviceInfo];
}



