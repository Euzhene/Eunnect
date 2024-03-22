import 'package:eunnect/constants.dart';
import 'package:flutter/material.dart';

class CustomScreen extends StatelessWidget {
  final String appbarText;
  final List<Widget>? appbarActions;
  final List<PopupMenuItem>? menuButtons;
  final EdgeInsets padding;
  final Widget? fab;
  final FloatingActionButtonLocation? fabLocation;
  final Widget child;

  const CustomScreen({
    super.key,
    required this.appbarText,
    this.appbarActions,
    this.menuButtons,
    this.padding = const EdgeInsets.symmetric(vertical: verticalPadding, horizontal: horizontalPadding),
    this.fab,
    this.fabLocation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appbarText),
        centerTitle: true,
        actions: _getActions(),
      ),
      floatingActionButton: fab,
      floatingActionButtonLocation: fabLocation,
      body: Padding(
        padding: padding,
        child: child,
      ),
    );
  }

  List<Widget>? _getActions() {
    if (appbarActions != null) return appbarActions;
    if (menuButtons != null)
      return [
        PopupMenuButton(
          itemBuilder: (context) => menuButtons!,
          onSelected: (fn) => fn(),
        )
      ];

    return null;
  }
}
