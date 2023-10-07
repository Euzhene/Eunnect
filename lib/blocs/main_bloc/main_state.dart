
part of 'main_bloc.dart';

abstract class MainState extends Equatable {

  @override
  List<Object?> get props => [];

}
class ErrorMainState extends MainState {
  final String error;

  ErrorMainState({required this.error});
}

class SuccessMainState extends MainState {

}

