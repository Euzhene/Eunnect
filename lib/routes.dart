import 'package:eunnect/screens/scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'device_scan_bloc.dart';

const String scanRoute = "scan-route";

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  Widget screen;
  switch (settings.name) {
    case scanRoute:
      screen = MultiBlocProvider(providers: [BlocProvider(create: (_) => DeviceScanBloc()..onInitServer())], child: ScanScreen());
      break;
    default:
      throw UnimplementedError();
  }

  return MaterialPageRoute(builder: (context) => screen);
}
