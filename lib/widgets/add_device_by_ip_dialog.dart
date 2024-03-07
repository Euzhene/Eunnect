import 'package:eunnect/blocs/scan_bloc/scan_bloc.dart';
import 'package:eunnect/constants.dart';
import 'package:eunnect/widgets/custom_button.dart';
import 'package:eunnect/widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddDeviceByIpDialog extends StatefulWidget {
  final ScanBloc bloc;
  final TextEditingController controller = TextEditingController();

  AddDeviceByIpDialog._(this.bloc);

  static Future<void> openDialog(BuildContext context, ScanBloc bloc) {
    return showDialog(context: context, builder: (context) => AddDeviceByIpDialog._(bloc));
  }

  @override
  State<StatefulWidget> createState() => _AddDeviceByIpState();
}

class _AddDeviceByIpState extends State<AddDeviceByIpDialog> {
  bool isValid = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: verticalPadding, horizontal: horizontalPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CustomText("Введите IP устройства, которое хотите добавить"),
            TextFormField(
              controller: widget.controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter(RegExp(r'[\d\.]'), allow: true)],
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.devices),
                hintText: "IP устройства",
              ),
              onChanged: (val) => setState(() {
                isValid = RegExp(r'^(([01]?[0-9][0-9]?|[2][0-4][0-9]|25[0-5])\.?\b){4}$').hasMatch(val);
              }),
            ),
            CustomButton(enabled: isValid, onPressed: () => widget.bloc.onAddDeviceByIp(widget.controller.text), text: "Добавить"),
          ],
        ),
      ),
    );
  }
}
