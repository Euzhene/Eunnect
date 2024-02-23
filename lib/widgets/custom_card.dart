import 'package:eunnect/constants.dart';
import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsets? padding;

  const CustomCard({
    super.key,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(horizontalPadding),
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    Widget _child = child;

    _child = SizedBox(
      width: double.infinity,
      child: Card(color: backgroundColor, child: _child),
    );

    return _child;
  }
}
