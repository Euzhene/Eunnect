import 'package:eunnect/blocs/scan_bloc/scan_bloc.dart';
import 'package:eunnect/blocs/scan_bloc/scan_state.dart';
import 'package:eunnect/constants.dart';
import 'package:eunnect/widgets/custom_button.dart';
import 'package:eunnect/widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddDeviceByIpDialog extends StatefulWidget {
  final TextEditingController controller = TextEditingController();

  static Future<void> openDialog(BuildContext context, ScanBloc bloc) {
    return showDialog(context: context, builder: (context) => BlocProvider(create: (ctx) => bloc, child: AddDeviceByIpDialog()));
  }

  @override
  State<StatefulWidget> createState() => _AddDeviceByIpState();
}

class _AddDeviceByIpState extends State<AddDeviceByIpDialog> {
  bool isValid = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: BlocBuilder<ScanBloc, ScanState>(builder: (context, state) {
        return Padding(
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
              if (state is AwaitPairingDeviceState && state.deviceInfo == null)
                const CircularProgressIndicator()
              else
                CustomButton(
                    enabled: isValid,
                    onPressed: () => context.read<ScanBloc>().onAddDeviceByIp(widget.controller.text),
                    text: "Добавить"),
              if (state is AwaitPairingDeviceState && state.deviceInfo != null)
                CustomText("Ожидание ответа от ${state.deviceInfo!.name}...")
            ],
          ),
        );
      }),
    );
  }
}
