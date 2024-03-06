import 'package:eunnect/blocs/settings_bloc/settings_bloc.dart';
import 'package:eunnect/models/device_info/device_info.dart';
import 'package:eunnect/routes.dart';
import 'package:eunnect/screens/settings_screen/developer_console_screen.dart';
import 'package:eunnect/widgets/custom_button.dart';
import 'package:eunnect/widgets/custom_expansion_tile.dart';
import 'package:eunnect/widgets/custom_screen.dart';
import 'package:eunnect/widgets/device_info_widget.dart';
import 'package:eunnect/widgets/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../constants.dart';
import '../../main.dart';
import '../../widgets/custom_sized_box.dart';
import '../../widgets/custom_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SettingsBloc bloc = context.read();
    return BlocBuilder<SettingsBloc, SettingsState>(builder: (context, state) {
      return CustomScreen(
          appbarText: "Настройки",
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: state is LoadingScreenState
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        _buildDeviceNameField(),
                        const VerticalSizedBox(),
                        _buildDarkThemeSwitch(),
                        const VerticalSizedBox(),
                        _buildBlockedGroup(),
                        const VerticalSizedBox(),
                        _buildGroup(title: "Доверенные устройства", children: []),
                        const VerticalSizedBox(),
                        CustomButton(onPressed: bloc.onSendLogs, text: "Сообщить об ошибке"),
                        const VerticalSizedBox(),
                        CustomButton(
                          opacity: 0.5,
                          onPressed: () {
                            showConfirmDialog(
                              context,
                              title: "Сброс настроек",
                              content:
                                  "Вы уверены, что хотите сбросить настройки к стандартным? После подтверждения действия вам придется заново устанавливать сопряжение с другими устройствами, а ваше устройство будет опознано как новое.",
                              cancelText: "Назад",
                              confirmText: "Продолжить",
                              onConfirm: () => bloc.onResetSettings(),
                            );
                          },
                          text: "Полный сброс настроек",
                        ),
                        const VerticalSizedBox(),
                        CustomButton(
                          opacity: 0.5,
                          onPressed: () => DeveloperConsoleScreen.openScreen(context),
                          text: "Консоль разработчика",
                        ),
                        const VerticalSizedBox(),
                        _buildDeviceInfo(),
                        const VerticalSizedBox(),
                      ],
                    ),
            ),
          ));
    });
  }

  Widget _buildDeviceNameField() {
    return Builder(builder: (context) {
      SettingsBloc bloc = context.read();
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: bloc.deviceNameController,
            maxLength: 40,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.devices),
              suffixIcon: IconButton(
                  onPressed: bloc.isDeviceNameValid ? () => bloc.onUpdateDeviceName() : null, icon: const Icon(Icons.save)),
              labelText: "Имя устройства",
            ),
          ),
        ],
      );
    });
  }

  Widget _buildBlockedGroup() {
    return Builder(builder: (context) {
      SettingsBloc bloc = context.read();
      return _buildGroup(
        title: "Заблокированные устройства ${bloc.blockedDevices.isEmpty ? "" : "(${bloc.blockedDevices.length})"}",
        children: bloc.blockedDevices
            .map((e) => _buildGroupDevice(deviceInfo: e, onDelete: () => bloc.onDeleteBlockedDevice(e)))
            .toList(),
      );
    });
  }

  Widget _buildGroup({required String title, required List<Widget> children}) {
    return CustomExpansionTile(
      text: title,
      childrenPadding: const EdgeInsets.symmetric(horizontal: horizontalPadding * 3),
      children: children,
    );
  }

  Widget _buildGroupDevice({required DeviceInfo deviceInfo, required VoidCallback onDelete}) {
    return DeviceInfoWidget(
      deviceInfo: deviceInfo,
      suffixIcon: IconButton(
        onPressed: onDelete,
        icon: const Icon(Icons.close, color: errorColor),
      ),
    );
  }

  Widget _buildDeviceInfo() {
    return Builder(builder: (context) {
      SettingsBloc bloc = context.read();
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(
            "${bloc.coreDeviceModel} ${bloc.coreDeviceAdditionalInfo}",
            dimmed: true,
          ),
          CustomText(
            "${bloc.packageInfo.appName} v${bloc.packageInfo.version}",
            dimmed: true,
          ),
        ],
      );
    });
  }

  Widget _buildDarkThemeSwitch() {
    return Builder(builder: (context) {
      SettingsBloc bloc = context.read();
      return CheckboxListTile(
        value: bloc.isDarkTheme,
        onChanged: (val) => bloc
            .onDarkThemeValueChangeRequested()
            .then((value) => context.findAncestorStateOfType<EunnectState>()!.onThemeModeChanged()),
        title: const CustomText(
          "Темная тема",
          textAlign: TextAlign.start,
          fontSize: 17,
        ), //добавить CustomText.header()
        secondary: const Icon(Icons.dark_mode),
      );
    });
  }

  static Future<void> openScreen(BuildContext context) {
    Widget screen = MultiBlocProvider(providers: [BlocProvider(create: (_) => SettingsBloc())], child: const SettingsScreen());
    return pushScreen<void>(context, screen: screen, screenName: "SettingsScreen");
  }
}
