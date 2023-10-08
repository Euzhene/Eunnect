import 'package:eunnect/blocs/device_actions_bloc/device_actions_bloc.dart';
import 'package:eunnect/models/pair_device_info.dart';
import 'package:eunnect/screens/device_actions_screen.dart';
import 'package:eunnect/screens/scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'device_scan_bloc.dart';

const String scanRoute = "scan-route";
const String deviceActionsRoute = "device-actions-route";

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  Widget screen;
  switch (settings.name) {
    case scanRoute:
      screen = MultiBlocProvider(
          providers: [BlocProvider(create: (_) => DeviceScanBloc()..onInitServer())], child: const ScanScreen());
      break;
    case deviceActionsRoute:
      PairDeviceInfo deviceInfo = settings.arguments as PairDeviceInfo;
      screen =
          MultiBlocProvider(providers: [BlocProvider(create: (_) => DeviceActionsBloc(deviceInfo: deviceInfo))], child: const DeviceActionsScreen());
      break;
    default:
      throw UnimplementedError();
  }

  return MaterialPageRoute(builder: (context) => screen);
}
