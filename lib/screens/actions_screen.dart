import 'package:eunnect/blocs/command_bloc/choose_device_type.dart';
import 'package:eunnect/blocs/command_bloc/command_bloc.dart';
import 'package:eunnect/blocs/device_actions_bloc/actions_bloc.dart';
import 'package:eunnect/constants.dart';
import 'package:eunnect/models/device_info/device_type.dart';
import 'package:eunnect/routes.dart';
import 'package:eunnect/screens/scan_screen/scan_paired_device.dart';
import 'package:eunnect/widgets/custom_button.dart';
import 'package:eunnect/widgets/custom_card.dart';
import 'package:eunnect/widgets/custom_sized_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/device_info/device_info.dart';
import '../widgets/custom_text.dart';

//todo добавить класс CustomScreen
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
                  PopupMenuItem(
                    value: () => _showCommandBottomSheet(context),
                    child: const Text('Добавить команду'),
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
                      if (!bloc.isAndroidDeviceType)
                        ...bloc.commands
                            .map((e) => _buildActionButton(
                                text: e.name, description: e.description, onPressed: () => bloc.onSendCommand(command: e)))
                            .toList(),
                    ]
                  ],
                ),
              ),
            ),
          );
        }));
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
    dynamic res = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => BlocProvider(
          create: (ctx) => CommandBloc(),
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: _CommandScreen(),
          )),
    );
    if (res == true) bloc.onGetLocalCommands();
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

    return BlocConsumer<CommandBloc, CommandState>(listener: (context, state) {
      if (state is CloseScreen) Navigator.of(context).pop(true);
    }, builder: (context, state) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: verticalPadding, horizontal: horizontalPadding),
          child: Column(
            children: [
              _buildTextField(
                controller: bloc.nameController,
                label: "Название",
                prefixIconData: Icons.title,
                textCapitalization: TextCapitalization.sentences,
              ),
              const VerticalSizedBox(),
              _buildTextField(
                controller: bloc.descriptionController,
                label: "Описание (опционально)",
                prefixIconData: Icons.comment,
                textCapitalization: TextCapitalization.sentences,
              ),
              const VerticalSizedBox(),
              _buildTextField(
                controller: bloc.commandController,
                label: "Команда",
                prefixIconData: Icons.keyboard_command_key,
              ),
              const VerticalSizedBox(),
              _buildDeviceTypeList(),
              const VerticalSizedBox(),
              _buildAddButton(),
              const VerticalSizedBox(),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIconData,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Builder(builder: (context) {
      return TextFormField(
        textCapitalization: textCapitalization,
        controller: controller,
        onChanged: (val) => context.read<CommandBloc>().onTextChanged(),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(prefixIconData),
        ),
      );
    });
  }

  Widget _buildDeviceTypeList() {
    return Builder(builder: (context) {
      CommandBloc bloc = context.read();
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CustomText("Поддерживаемые устройства "),
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 2,
            childAspectRatio: 3,
            padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
            crossAxisSpacing: horizontalPadding,
            children: bloc.deviceTypeList.map((e) => _buildDeviceTypeWidget(e)).toList(),
          ),
        ],
      );
    });
  }

  Widget _buildAddButton() {
    return Builder(builder: (context) {
      CommandBloc bloc = context.read();
      return CustomButton(enabled: bloc.isAllValid, onPressed: bloc.onAddCommand, text: "Добавить");
    });
  }

  Widget _buildDeviceTypeWidget(ChooseDeviceType deviceType) {
    bool isAdded = deviceType.isAdded;
    return Builder(builder: (context) {
      return CustomCard(
          onPressed: () => context.read<CommandBloc>().onSelectDeviceType(deviceType),
          backgroundColor: isAdded ? null : Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: verticalPadding / 2),
          child: Row(
            children: [
              Icon(DeviceTypeConverter.iconFromType(deviceType.type)),
              const HorizontalSizedBox(),
              Expanded(
                  child: CustomText(
                deviceType.type.name,
                overflow: TextOverflow.ellipsis,
              )),
              const HorizontalSizedBox(),
              Icon(
                isAdded ? Icons.close : Icons.add,
                color: isAdded ? errorColor : successColor,
              )
            ],
          ));
    });
  }
}
