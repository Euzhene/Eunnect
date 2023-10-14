import 'package:flutter/material.dart';

class CustomText extends Text {
  CustomText(super.data, {super.key, double fontSize = 15, Color? color = Colors.white, TextAlign textAlign = TextAlign.center})
      : super(style: TextStyle(fontSize: fontSize, color: color),textAlign: textAlign);
}
