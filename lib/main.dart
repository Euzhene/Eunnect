import 'package:eunnect/blocs/main_bloc/main_bloc.dart';
import 'package:eunnect/constants.dart';
import 'package:eunnect/helpers/get_it_helper.dart';
import 'package:eunnect/routes.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.root.level = Level.FINE;
  Logger.root.onRecord.listen((record) {
    print(
        '${DateFormat.Hms().format(record.time)}: ${record.level.name}: ${record.loggerName}: ${record.message} ${record.error} ${record.stackTrace}');
  });

  await GetItHelper.registerAll();
  GetItHelper.i<MainBloc>().checkFirstLaunch();
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
        useMaterial3: true,
      ),
      onGenerateRoute: onGenerateRoute,
      initialRoute: scanRoute,
    );
  }
}
