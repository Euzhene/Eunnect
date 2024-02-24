import 'package:eunnect/blocs/main_bloc/main_bloc.dart';
import 'package:eunnect/constants.dart';
import 'package:eunnect/helpers/get_it_helper.dart';
import 'package:eunnect/helpers/log_helper.dart';
import 'package:eunnect/helpers/notification_helper.dart';
import 'package:eunnect/repo/local_storage.dart';
import 'package:eunnect/routes.dart';
import 'package:eunnect/widgets/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.storage.request();
  await Permission.manageExternalStorage.request();
  await Permission.notification.request();

  LogHelper.start();

  NotificationHelper.init();

  await GetItHelper.registerAll();

  bool isDarkMode = GetItHelper.i<LocalStorage>().isDarkTheme();
  ThemeMode themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
  runApp(BlocProvider(create: (_) => GetItHelper.i<MainBloc>(), child: Eunnect(initialThemeMode: themeMode,)));
}



class Eunnect extends StatefulWidget {
  Eunnect({super.key, required this.initialThemeMode});

  final _navKey = GlobalKey<NavigatorState>();
  final ThemeMode initialThemeMode;

  @override
  State<StatefulWidget> createState() => EunnectState();
}

class EunnectState extends State<Eunnect> {
  late ThemeMode themeMode;

  @override
  void initState() {
    themeMode = widget.initialThemeMode;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: widget._navKey,
      title: appName,
      themeMode: themeMode,
      darkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: darkScaffoldBackgroundColor,
          textTheme: const TextTheme(bodyMedium: TextStyle(color:darkTextColor)),
          textButtonTheme: TextButtonThemeData(style: ButtonStyle(
              foregroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.disabled)) return darkTextDisabledColor;
                return darkTextColor;
              })
          )),
          cardTheme: const CardTheme(color: darkCardContentBackground),
          appBarTheme:
              const AppBarTheme(backgroundColor: darkScaffoldBackgroundColor, centerTitle: true, foregroundColor: white),
          popupMenuTheme: const PopupMenuThemeData(color: darkScaffoldBackgroundColor),
          useMaterial3: true,
          floatingActionButtonTheme: const FloatingActionButtonThemeData(shape: CircleBorder())),
      theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: scaffoldBackgroundColor,
          textTheme: const TextTheme(bodyMedium: TextStyle(color:textColor)),
          textButtonTheme: TextButtonThemeData(style: ButtonStyle(
            foregroundColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.disabled)) return textDisabledColor;
              return textColor;
            })
          )),
          cardTheme: const CardTheme(color: cardContentBackground),
          appBarTheme:
              const AppBarTheme(backgroundColor: scaffoldBackgroundColor, centerTitle: true, foregroundColor: black),
          popupMenuTheme: const PopupMenuThemeData(color: scaffoldBackgroundColor),
          useMaterial3: true,
          floatingActionButtonTheme: const FloatingActionButtonThemeData(shape: CircleBorder())),
      builder: (context, child) {
        MainBloc bloc = context.read<MainBloc>();
        return BlocListener<MainBloc, MainState>(
            listener: (context, state) {
              if (state is ErrorMainState)
                showErrorSnackBar(context, text: state.error);
              else if (state is SuccessMainState)
                showSuccessSnackBar(context, text: state.message);
              else if (state is PairDialogState) {
                showConfirmDialog(widget._navKey.currentContext!,
                    title: "Устройство ${state.deviceInfo.name} хочет установить сопряжение",
                    onConfirm: () => bloc.onPairConfirmed(state.deviceInfo),
                    onCancel: () => bloc.onPairConfirmed(null));
              }
            },
            child: child ?? Container());
      },
      onGenerateRoute: onGenerateRoute,
      initialRoute: scanRoute,
    );
  }

  Future<void> onThemeModeChanged() async {
    bool isDarkMode = GetItHelper.i<LocalStorage>().isDarkTheme();
    setState((){
      themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }
}

