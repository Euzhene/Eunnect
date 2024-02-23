import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sembast/sembast.dart';
import 'package:intl/intl.dart';

import 'package:f_logs/f_logs.dart';
import 'package:share_plus/share_plus.dart';

import '../constants.dart';

const String _timestampFormat = TimestampFormat.TIME_FORMAT_FULL_1;
const Duration _deleteAfterDuration = Duration(days: 1);

abstract class LogHelper {
  static Future<void> start() async {
    await _init();
    await _deleteOldLogs();
  }

  static Future<void> _init() async {
    LogsConfig logsConfig = FLog.getDefaultConfigurations();
    logsConfig.timestampFormat = _timestampFormat;
    logsConfig.activeLogLevel = LogLevel.ALL;
    logsConfig.fieldOrderFormatCustom = [
      FieldName.LOG_LEVEL,
      FieldName.TEXT,
      FieldName.EXCEPTION,
      FieldName.METHOD_NAME,
      FieldName.CLASSNAME,
      FieldName.TIMESTAMP,
      FieldName.STACKTRACE
    ];
    FLog.applyConfigurations(logsConfig);
  }

  static Future<void> _deleteOldLogs() async {
    Filter filter = Filter.lessThan(
        DBConstants.FIELD_TIMESTAMP, DateFormat(_timestampFormat).format(DateTime.now().subtract(_deleteAfterDuration)));
    await FLog.deleteAllLogsByFilter(filters: [filter]);
  }

  static Future<void> export({VoidCallback? onEmptyLogs, VoidCallback? onSuccess, Function(String)? onError}) async {
    try {
      File logs = await FLog.exportLogs();
      if ((await logs.length()) == 0) {
        onEmptyLogs?.call();
        return;
      }
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String shareName = "${packageInfo.appName} ${dateFormat.format(DateTime.now())}";
      ShareResult res = await Share.shareXFiles([XFile(logs.path)], text: shareName);
      if (res.status == ShareResultStatus.success) onSuccess?.call();
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      onError?.call(e.toString());
    }
  }
}
