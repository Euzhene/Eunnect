import 'package:f_logs/f_logs.dart';
import 'package:flutter/material.dart';

Future<T?> pushScreen<T>(BuildContext context, {required Widget screen, required String screenName}) async {
  return _basePush(screenName: screenName, action: Navigator.of(context).push(_getRoute(screen)));
}

Future<T?> pushDialog<T>(BuildContext context, {required Widget screen, required String screenName}) async {
  return _basePush(screenName: screenName, action: showDialog<T?>(context: context, builder: (context) => screen));
}

Future<T?> _basePush<T>({required String screenName, required Future<T?> action}) async {
  FLog.trace(text: "Navigating to $screenName");
  T? res = await action;
  FLog.trace(text: "Leaving $screenName");
  return res;
}

Route<T> _getRoute<T>(Widget screen) => MaterialPageRoute(builder: (context) => screen);
