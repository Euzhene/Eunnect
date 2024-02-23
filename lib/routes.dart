import 'package:eunnect/blocs/device_actions_bloc/actions_bloc.dart';
import 'package:eunnect/blocs/settings_bloc/settings_bloc.dart';
import 'package:eunnect/helpers/get_it_helper.dart';
import 'package:eunnect/screens/actions_screen.dart';
import 'package:eunnect/screens/scan_screen/scan_paired_device.dart';
import 'package:eunnect/screens/scan_screen/scan_screen.dart';
import 'package:eunnect/screens/settings_screen.dart';
import 'package:f_logs/f_logs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'blocs/scan_bloc/scan_bloc.dart';


const String scanRoute = "scan-route";
const String deviceActionsRoute = "device-actions-route";
const String settingsRoute = "settings-route";

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  Widget screen;
  switch (settings.name) {
    case scanRoute:
      screen = MultiBlocProvider(
          providers: [BlocProvider(create: (_) => GetItHelper.i<ScanBloc>())], child: const ScanScreen());
      break;
    case deviceActionsRoute:
      ScanPairedDevice deviceInfo = settings.arguments as ScanPairedDevice;
      screen =
          MultiBlocProvider(providers: [BlocProvider(create: (_) => ActionsBloc(deviceInfo: deviceInfo,deviceAvailable: deviceInfo.available))], child: const ActionsScreen());
      break;
    case settingsRoute:
      screen = MultiBlocProvider(providers: [BlocProvider(create: (_)=> SettingsBloc())], child: const SettingsScreen());
      break;
    default:
      throw UnimplementedError();
  }
  FLog.trace(text: "Navigating to ${settings.name}");
  return MaterialPageRoute(builder: (context) => screen);
}
