import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

bool get isDesktop => Platform.isWindows || Platform.isMacOS || Platform.isLinux;
bool get isMobile => Platform.isAndroid || Platform.isIOS;

const double verticalPadding = 8;
const double horizontalPadding = 8;

const Color scaffoldBackgroundColor = Color(0xffF2F2F2);
const Color darkScaffoldBackgroundColor = Color(0xff262626);

const Color cardContentBackground = Color(0xffd3faff);
const Color darkCardContentBackground = Color(0xff808080);

const Color textColor = black;
const Color textDisabledColor = Colors.black54;
const Color textDimmedColor = Colors.black38;
const Color darkTextColor = white;
const Color darkTextDisabledColor = Colors.white70;
const Color darkTextDimmedColor = Colors.white38;


const Color white = Colors.white;
const Color black = Colors.black;

const Color errorColor = Colors.red;
const Color successColor = Colors.green;


final DateFormat dateFormat = DateFormat("dd-MM-y");

const String appName = "MaKuKu Connect"; //todo получать название приложения из названия пакета

const int port = 10242;