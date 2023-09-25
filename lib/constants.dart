
import 'dart:io';

import 'package:flutter/material.dart';

bool get isDesktop => Platform.isWindows || Platform.isMacOS || Platform.isLinux;
bool get isMobile => Platform.isAndroid || Platform.isIOS;

const double verticalPadding = 8;
const double horizontalPadding = 8;

const Color scaffoldBackgroundColor = Color(0xff006E77);
const Color cardTitleColor = Color(0xff014E6A);
const Color cardContentBackground = Color(0xff197279);