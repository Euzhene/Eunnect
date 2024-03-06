import 'package:flutter/material.dart';

import 'custom_text.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final bool enabled;
  final double fontSize;
  final Color? textColor;
  final double? opacity;

  const CustomButton(
      {super.key, required this.onPressed, required this.text, this.enabled = true, this.fontSize = 14, this.textColor, this.opacity});

  @override
  Widget build(BuildContext context) {
    Widget _child = TextButton(
        onPressed: enabled ? onPressed : null,
        child: CustomText(
          text,
          fontSize: fontSize,
          color: textColor,
        ));
    if (opacity != null) _child = Opacity(
      opacity: opacity!,
      child: _child,
    );
    return _child;
  }
}
