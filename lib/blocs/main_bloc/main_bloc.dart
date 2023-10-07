import 'package:equatable/equatable.dart';
import 'package:eunnect/repo/local_storage.dart';
import 'package:f_logs/f_logs.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'main_state.dart';

class MainBloc extends Cubit<MainState> {
  final LocalStorage _storage = LocalStorage();

  MainBloc() : super(SuccessMainState());

  Future<void> checkFirstLaunch() async {
    try {
      if (!_storage.isFirstLaunch()) return;

      await _storage.setFirstLaunch();
      await _storage.setSecretKey();
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      emit(ErrorMainState(error: "Критическая ошибка при чтении из БД. Обратитесь в службу поддержки"));
    }
  }
}
