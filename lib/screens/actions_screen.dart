import 'package:eunnect/blocs/device_actions_bloc/actions_bloc.dart';
import 'package:eunnect/constants.dart';
import 'package:eunnect/widgets/custom_card.dart';
import 'package:eunnect/widgets/custom_sized_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/device_info.dart';
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
                    value: () =>bloc.onBreakPairing().then((value) => Navigator.of(context).pop(true)),
                    child: const Text('Разорвать сопряжение'),
                  ),
                ];
              },
              onSelected: (fn) => fn(),
            )
          ],
        ),
        body: BlocBuilder<ActionsBloc, DeviceActionsState>(builder: (context, state) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (state.isUnreachableDevice)
                    const Row(
                      children: [
                        Icon(Icons.error_outline, size: 40),
                        HorizontalSizedBox(),
                        Expanded(
                            child: Text(
                          "Не удалось достичь сопряженное устройство. Убедитесь, что оно подключено к той же сети.",
                          style: TextStyle(fontSize: 20),
                        )),
                      ],
                    )
                  else if (state is SendingFileState) ...[
                    CircularProgressIndicator(value: state.progressValue, color: Colors.lightBlueAccent),
                    const VerticalSizedBox(),
                    CustomText(
                        "${bloc.getFileSizeString(bytes: state.sentBytes)} / ${bloc.getFileSizeString(bytes: state.allFileBytes)}")
                  ] else ...[
                    InkWell(
                      onTap: () => bloc.onSendBuffer(),
                      child: CustomCard(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: CustomText(
                            "Передать буфер обмена",
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => bloc.onSendFile(),
                      child: CustomCard(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: CustomText(
                            "Передать файл",
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          );
        }));
  }
}
