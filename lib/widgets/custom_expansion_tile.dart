import 'package:flutter/material.dart';

import '../constants.dart';
import 'custom_text.dart';

class CustomExpansionTile extends StatelessWidget {
  final bool initiallyExpanded;
  final String text;
  final Function(bool)? onExpansionChanged;
  final List<Widget> children;
  final EdgeInsets childrenPadding;

  const CustomExpansionTile({
    super.key,
    this.initiallyExpanded = false,
    required this.text,
    this.onExpansionChanged,
    required this.children,
    this.childrenPadding = const EdgeInsets.all(horizontalPadding),
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      shape: const Border(),
      title: CustomText(text, fontSize: 17, textAlign: TextAlign.start),
      onExpansionChanged: onExpansionChanged,
      children: children.isEmpty
          ? [const Align(alignment: Alignment.center, child: CustomText("Не найдено"))]
          : [
              Padding(
                padding: childrenPadding,
                child: Column(mainAxisSize: MainAxisSize.min, children: children),
              )
            ],
    );
  }
}
