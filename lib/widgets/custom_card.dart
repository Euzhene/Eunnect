import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsets padding;
  final VoidCallback? onPressed;
  final double? elevation;

  const CustomCard({
    super.key,
    this.backgroundColor,
    this.onPressed,
    this.padding = const EdgeInsets.symmetric(),
    this.elevation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    Widget _child = child;

    _child = SizedBox(
      width: double.infinity,
      child: Card(
        elevation: elevation,
        color: backgroundColor,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
          padding: padding,
          child: _child,
        ),
        ),
      ),
    );

    return _child;
  }
}
