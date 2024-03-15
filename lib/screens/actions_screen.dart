import 'package:eunnect/blocs/command_bloc/command_bloc.dart';
import 'package:eunnect/blocs/device_actions_bloc/actions_bloc.dart';
import 'package:eunnect/constants.dart';
import 'package:eunnect/models/socket/socket_command.dart';
import 'package:eunnect/routes.dart';
import 'package:eunnect/screens/scan_screen/scan_paired_device.dart';
import 'package:eunnect/widgets/custom_card.dart';
import 'package:eunnect/widgets/custom_screen.dart';
import 'package:eunnect/widgets/custom_sized_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../models/device_info/device_info.dart';
import '../widgets/custom_text.dart';

class ActionsScreen extends StatelessWidget {
  const ActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ActionsBloc bloc = context.read();
    DeviceInfo deviceInfo = bloc.deviceInfo;

    return CustomScreen(
      appbarText: "${deviceInfo.name} (${deviceInfo.ipAddress})",
      menuButtons: [
        PopupMenuItem(
          value: () => bloc.onBreakPairing().then((value) => Navigator.of(context).pop(true)),
          child: const Text('Разорвать сопряжение'),
        ),
        PopupMenuItem(
          value: () => _showCommandBottomSheet(context),
          child: const Text('Добавить команду'),
        ),
      ],
      child: BlocConsumer<ActionsBloc, DeviceActionsState>(listener: (context, state) {
        if (state is DeletedDeviceState) bloc.onBreakPairing().then((value) => Navigator.of(context).pop(true));
      }, builder: (context, state) {
        return Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (state.isUnreachableDevice)
                      const Row(
                        children: [
                          Icon(Icons.error_outline, size: 40),
                          HorizontalSizedBox(),
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
                      _buildActionButton(text: "Включить трансляцию для устройства", onPressed: () => bloc.onEnableTranslation()),
                      _buildActionButton(text: "Получить трансляцию", onPressed: () => bloc.onGetTranslation()),
                      if (!bloc.isAndroidDeviceType) _buildActionButton(text: "Команды", onPressed: () => _showCommandBottomSheet(context)),
                    ]
                  ],
                ),
              ),
            ),
            if (bloc.rtcVideoRenderer != null) Positioned(bottom: 0,  right: 0, child: SizedBox(
              width: 300,
              height: 300,
              child: RTCVideoView(
                bloc.rtcVideoRenderer!,
              ),
            )),
          ],
        );
      }),
    );
  }

  Widget _buildActionButton({required String text, String? description, required VoidCallback onPressed}) {
    return CustomCard(
      padding: const EdgeInsets.symmetric(vertical: 30),
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(text, fontSize: 20),
          if (description != null) CustomText(description, dimmed: true),
        ],
      ),
    );
  }

  void _showCommandBottomSheet(BuildContext context) async {
    ActionsBloc bloc = context.read();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
      builder: (ctx) => BlocProvider(
          create: (ctx) => CommandBloc(deviceInfo: bloc.deviceInfo),
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: _CommandScreen(),
          )),
    );
  }

  static Future<bool?> openScreen(BuildContext context, {required ScanPairedDevice deviceInfo}) async {
    Widget screen = MultiBlocProvider(
      providers: [BlocProvider(create: (_) => ActionsBloc(deviceInfo: deviceInfo, deviceAvailable: deviceInfo.available))],
      child: const ActionsScreen(),
    );

    return pushScreen<bool?>(context, screen: screen, screenName: "ActionsScreen");
  }
}

class _CommandScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    CommandBloc bloc = context.read();

    return BlocConsumer<CommandBloc, CommandState>(
        listener: (context, state) {},
        builder: (context, state) {
          if (state is LoadingCommandState) return const Center(child: CircularProgressIndicator());
          if (state is NotGotCommandsState)
            return const Center(child: CustomText("Ошибка при получении команд", color: errorColor));

          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: verticalPadding, horizontal: horizontalPadding),
                child: Column(
                  children: [
                    if (bloc.commands.isEmpty)
                      const CustomText("Тут пока пусто. Добавьте команды на другом устройстве, чтобы видеть их здесь")
                    else
                      ListView.separated(
                          shrinkWrap: true,
                          itemCount: bloc.commands.length,
                          separatorBuilder: (context, index) => const VerticalSizedBox(),
                          itemBuilder: (context, index) {
                            SocketCommand command = bloc.commands[index];
                            return InkWell(onTap: ()=>bloc.onSendCommand(command), child: CustomText(command.name));
                          }),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
