import 'package:flutter/material.dart';

import 'custom_text.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final bool enabled;
  final double fontSize;

  const CustomButton({super.key, required this.onPressed, required this.text, this.enabled = true, this.fontSize = 14});

  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: enabled ? onPressed : null,
        child: CustomText(
          text,
          fontSize: fontSize,
        ));
  }
}
