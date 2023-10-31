import 'package:intl/intl.dart';
import 'dart:io';

import 'package:flutter/material.dart';

bool get isDesktop => Platform.isWindows || Platform.isMacOS || Platform.isLinux;
bool get isMobile => Platform.isAndroid || Platform.isIOS;

const double verticalPadding = 8;
const double horizontalPadding = 8;

const Color scaffoldBackgroundColor = Color(0xffF2F2F2);
const Color cardTitleColor = Color(0xff014E6A);
const Color cardContentBackground = Color(0xff197279);


const Color white = Colors.white;
const Color black = Colors.black;

const Color errorColor = Colors.red;
const Color successColor = Colors.green;
const Color warnColor = Colors.yellow;


final DateFormat dateFormat = DateFormat("dd-MM-y");

const String appName = "MaKuKu Connect";