import 'package:eunnect/blocs/main_bloc/main_bloc.dart';
import 'package:eunnect/constants.dart';
import 'package:eunnect/helpers/get_it_helper.dart';
import 'package:eunnect/routes.dart';
import 'package:eunnect/widgets/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetItHelper.registerAll();
  runApp(const Eunnect());
}

class Eunnect extends StatelessWidget {
  const Eunnect({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      theme: ThemeData(
        scaffoldBackgroundColor: scaffoldBackgroundColor,
        appBarTheme:
            const AppBarTheme(backgroundColor: scaffoldBackgroundColor, centerTitle: true, foregroundColor: Colors.black),
        useMaterial3: true,
      ),
      builder: (context, widget) {

        return BlocListener(
            bloc: GetItHelper.i<MainBloc>(),
            listener: (context, state) {
              if (state is ErrorMainState)
                showErrorSnackBar(context, text: state.error);
              else if (state is SuccessMainState)
                showSuccessSnackBar(context, text: state.message);
              else if (state is PairDialogState) {
                MainBloc bloc = context.read<MainBloc>();
                showConfirmDialog(context,
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
