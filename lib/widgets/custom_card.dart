import 'package:eunnect/constants.dart';
import 'package:eunnect/widgets/custom_sized_box.dart';
import 'package:eunnect/widgets/custom_text.dart';
import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final String? headerText;
  final Color headerBackgroundColor;
  final Color headerTextColor;
  final EdgeInsets? padding;

  const CustomCard({
    super.key,
    this.backgroundColor = cardContentBackground,
    this.headerText,
    this.headerBackgroundColor = cardTitleColor,
    this.headerTextColor = Colors.white,
    this.padding = const EdgeInsets.all(horizontalPadding),
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    Widget _child = child;

    if (headerText != null)
      _child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: padding,
            color: headerBackgroundColor,
            child: CustomText(
              headerText!,
              color: headerTextColor,
              fontSize: 20,
            ),
          ),
          const VerticalSizedBox(),
          _child
        ],
      );
    _child = SizedBox(
      width: double.infinity,
      child: Card(
        color: backgroundColor,
        child: _child,
      ),
    );

    return _child;
  }
}
