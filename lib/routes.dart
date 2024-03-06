import 'package:f_logs/f_logs.dart';
import 'package:flutter/material.dart';

Future<T?> pushScreen<T>(BuildContext context, {required Widget screen, required String screenName}) async {
  FLog.trace(text: "Navigating to $screenName");
  T res = await Navigator.of(context).push(_getRoute(screen));
  FLog.trace(text: "Leaving $screenName");
  return res;
}

Route _getRoute(Widget screen) => MaterialPageRoute(builder: (context) => screen);
