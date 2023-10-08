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
      title: 'MaKuKu Connect',
      theme: ThemeData(
        scaffoldBackgroundColor: scaffoldBackgroundColor,
        appBarTheme: AppBarTheme(backgroundColor: scaffoldBackgroundColor, centerTitle: true,foregroundColor: white),
        useMaterial3: true,
      ),
      builder: (context, widget) {
        return BlocListener(
          bloc: GetItHelper.i<MainBloc>(),
            listener: (context, state) {
              if (state is ErrorMainState) showErrorSnackBar(context, text: state.error);
              else if (state is SuccessMainState) showSuccessSnackBar(context, text: state.message);
            },
            child: widget ?? Container());
      },
      onGenerateRoute: onGenerateRoute,
      initialRoute: scanRoute,
    );
  }
}
