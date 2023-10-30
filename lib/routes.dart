import 'package:eunnect/blocs/device_actions_bloc/actions_bloc.dart';
import 'package:eunnect/models/pair_device_info.dart';
import 'package:eunnect/screens/actions_screen.dart';
import 'package:eunnect/screens/new_scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'blocs/scan_bloc/scan_bloc.dart';


const String scanRoute = "scan-route";
const String deviceActionsRoute = "device-actions-route";

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  Widget screen;
  switch (settings.name) {
    case scanRoute:
      screen = MultiBlocProvider(
          providers: [BlocProvider(create: (_) => ScanBloc()..onScanDevices())], child: const ScanScreen());
      break;
    case deviceActionsRoute:
      PairDeviceInfo deviceInfo = settings.arguments as PairDeviceInfo;
      screen =
          MultiBlocProvider(providers: [BlocProvider(create: (_) => ActionsBloc(deviceInfo: deviceInfo))], child: const ActionsScreen());
      break;
    default:
      throw UnimplementedError();
  }

  return MaterialPageRoute(builder: (context) => screen);
}
