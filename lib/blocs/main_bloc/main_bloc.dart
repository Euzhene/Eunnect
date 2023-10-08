import 'package:equatable/equatable.dart';
import 'package:eunnect/repo/local_storage.dart';
import 'package:f_logs/f_logs.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'main_state.dart';

class MainBloc extends Cubit<MainState> {
  final LocalStorage _storage = LocalStorage();

  MainBloc() : super(MainState());

  Future<void> checkFirstLaunch() async {
    try {
      if (!_storage.isFirstLaunch()) return;

      await _storage.clearAll();
      await _storage.setSecretKey();
      await _storage.setDeviceId();
      await _storage.setFirstLaunch();
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      emit(ErrorMainState(error: "Критическая ошибка при чтении из БД. Обратитесь в службу поддержки"));
    }
  }

  void emitDefaultError(String error) {
    emit(ErrorMainState(error: error));
    emit(MainState());
  }

  void emitDefaultSuccess(String message) {
    emit(SuccessMainState(message: message));
    emit(MainState());
  }
}
