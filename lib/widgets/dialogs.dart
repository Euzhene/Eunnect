import 'package:flutter/material.dart';

import '../constants.dart';
import 'custom_button.dart';
import 'custom_card.dart';

showSnackBar(BuildContext context,
    {required String text, Color? backgroundColor = white, Color? textColor = black, Color? closeIconColor}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  return ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: closeIconColor == null ? const Duration(milliseconds: 4000) : const Duration(minutes: 1),
      showCloseIcon: closeIconColor != null,
      closeIconColor: closeIconColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
      backgroundColor: backgroundColor,
      content: Text(text, style: TextStyle(color: textColor))));
}

showErrorSnackBar(BuildContext context, {required String text, bool withCloseIcon = false}) =>
    showSnackBar(context, text: text, backgroundColor: errorColor, textColor: white, closeIconColor: withCloseIcon ? white : null);

showSuccessSnackBar(BuildContext context, {required String text}) =>
    showSnackBar(context, text: text, backgroundColor: successColor, textColor: white);

showConfirmDialog(BuildContext context,
    {required String title, String? content, List<Widget>? actions, VoidCallback? onConfirm, VoidCallback? onCancel}) {
  return showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildDialog(
          actions: actions ??
              [
                CustomButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onConfirm?.call();
                    },
                    text: "Сопряжение"),
                CustomButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onCancel?.call();
                    },
                    text: "Нет"),
              ],
          title: title,
          content: content,
        );
      });
}

Widget _buildDialog({required List<Widget> actions, required String title, required String? content}) {
  return AlertDialog(
      title: Text(title, textAlign: TextAlign.center),
      content: content == null ? null : SingleChildScrollView(child: CustomCard(backgroundColor: white, child: Text(content))),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: actions);
}
