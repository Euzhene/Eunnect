import 'package:eunnect/constants.dart';
import 'package:flutter/material.dart';

class CustomText extends StatelessWidget {
  const CustomText(
    this.data, {
    super.key,
    this.fontSize = 15,
    this.color,
    this.textAlign = TextAlign.center,
    this.overflow,
    this.dimmed = false,
  });

  final String data;
  final double fontSize;
  final Color? color;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    Color? _color = color;
    if (dimmed) {
      bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
      _color = isDarkMode ? darkTextDimmedColor : textDimmedColor;
    }
    Widget _child = Text(
      data,
      textAlign: textAlign,
      overflow: overflow,
      style: TextStyle(
        fontSize: fontSize,
        color: _color,
      ),
    );
    return _child;
  }
}
