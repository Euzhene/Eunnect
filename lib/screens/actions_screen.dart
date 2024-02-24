import 'package:eunnect/blocs/device_actions_bloc/actions_bloc.dart';
import 'package:eunnect/constants.dart';
import 'package:eunnect/widgets/custom_card.dart';
import 'package:eunnect/widgets/custom_sized_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/device_info/device_info.dart';
import '../widgets/custom_text.dart';

class ActionsScreen extends StatelessWidget {
  const ActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ActionsBloc bloc = context.read();
    DeviceInfo deviceInfo = bloc.deviceInfo;

    return Scaffold(
        appBar: AppBar(
          title: Text("${deviceInfo.name} (${deviceInfo.ipAddress})"),
          centerTitle: true,
          actions: [
            PopupMenuButton<void Function()>(
              itemBuilder: (context) {
                return [
                  PopupMenuItem(
                    value: () => bloc.onBreakPairing().then((value) => Navigator.of(context).pop(true)),
                    child: const Text('Разорвать сопряжение'),
                  ),
                ];
              },
              onSelected: (fn) => fn(),
            )
          ],
        ),
        body: BlocConsumer<ActionsBloc, DeviceActionsState>(listener: (context, state) {
          if (state is DeletedDeviceState) bloc.onBreakPairing().then((value) => Navigator.of(context).pop(true));
        }, builder: (context, state) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (state.isUnreachableDevice)
                    Row(
                      children: [
                        const Icon(Icons.error_outline, size: 40),
                        const HorizontalSizedBox(),
                        Expanded(
                            child: CustomText(
                          "Не удалось достичь сопряженное устройство. Убедитесь, что оно подключено к той же сети.",
                          fontSize: 20,
                        )),
                      ],
                    )
                  else ...[
                    _buildActionButton(text: "Передать буфер обмена", onPressed: () => bloc.onSendBuffer()),
                    _buildActionButton(text: "Передать файл", onPressed: () => bloc.onSendFile()),
                    if (!bloc.isAndroidDeviceType) ...[
                      _buildActionButton(text: "Перезапустить ПК", onPressed: () => bloc.onSendRestartCommand()),
                      _buildActionButton(text: "Выключить ПК", onPressed: () => bloc.onSendShutDownCommand()),
                      _buildActionButton(text: "Включить спящий режим", onPressed: () => bloc.onSendSleepCommand()),
                    ]
                  ]
                ],
              ),
            ),
          );
        }));
  }

  Widget _buildActionButton({required String text, required VoidCallback onPressed}) {
    return CustomCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: CustomText(text, fontSize: 20),
        ),
      ),
    );
  }
}
