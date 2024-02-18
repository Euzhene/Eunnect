import 'package:eunnect/blocs/main_bloc/main_bloc.dart';
import 'package:eunnect/constants.dart';
import 'package:eunnect/helpers/get_it_helper.dart';
import 'package:eunnect/routes.dart';
import 'package:eunnect/widgets/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.storage.request();
  await Permission.manageExternalStorage.request();

  await GetItHelper.registerAll();
  runApp(BlocProvider(create: (_)=>GetItHelper.i<MainBloc>(), child: Eunnect()));
}

class Eunnect extends StatelessWidget {
  Eunnect({super.key});
  final _navKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: _navKey,
      title: appName,
      theme: ThemeData(
        scaffoldBackgroundColor: scaffoldBackgroundColor,
        appBarTheme:
            const AppBarTheme(backgroundColor: scaffoldBackgroundColor, centerTitle: true, foregroundColor: Colors.black),
        popupMenuTheme: const PopupMenuThemeData(color: scaffoldBackgroundColor),
        useMaterial3: true,
      ),
      builder: (context, widget) {
        MainBloc bloc = context.read<MainBloc>();
        return BlocListener<MainBloc,MainState>(
            listener: (context, state) {
              if (state is ErrorMainState)
                showErrorSnackBar(context, text: state.error);
              else if (state is SuccessMainState)
                showSuccessSnackBar(context, text: state.message);
              else if (state is PairDialogState) {
                showConfirmDialog(_navKey.currentContext!,
                    title: "Устройство ${state.deviceInfo.name} хочет установить сопряжение",
                    onConfirm: () => bloc.onPairConfirmed(state.deviceInfo),
                    onCancel: () => bloc.onPairConfirmed(null));
              }
            },
            child: widget ?? Container());
      },
      onGenerateRoute: onGenerateRoute,
      initialRoute: scanRoute,
    );
  }
}
