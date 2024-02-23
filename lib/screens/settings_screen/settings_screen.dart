import 'package:eunnect/blocs/settings_bloc/settings_bloc.dart';
import 'package:eunnect/routes.dart';
import 'package:eunnect/widgets/custom_button.dart';
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
      return Scaffold(
        appBar: AppBar(title: const Text("Настройки")),
        body: Center(
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
                      _buildGroup(title: "Заблокированные устройства"),
                      const VerticalSizedBox(),
                      _buildGroup(title: "Доверенные устройства"),
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
                          text: "Полный сброс настроек",),
                      const VerticalSizedBox(),
                      CustomButton(
                        opacity: 0.5,
                        onPressed: () => Navigator.of(context).pushNamed(developerConsoleRoute),
                        text: "Консоль разработчика",
                      ),
                      const VerticalSizedBox(),
                      _buildDeviceInfo(),
                      const VerticalSizedBox(),
                    ],
                  ),
          ),
        ),
      );
    });
  }

  Widget _buildDeviceNameField() {
    return Builder(builder: (context) {
      SettingsBloc bloc = context.read();
      return Padding(
        //todo добавить CustomPadding
        padding: const EdgeInsets.symmetric(horizontal: horizontalPadding * 2),
        child: Column(
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
        ),
      );
    });
  }

  Widget _buildGroup({required String title}) {
    return ExpansionTile(
      initiallyExpanded: false,
      shape: const Border(),
      title: CustomText(title, fontSize: 17, textAlign: TextAlign.start),
      children: [const VerticalSizedBox(), Align(alignment: Alignment.center, child: CustomText("Здесь пока пусто"))],
    );
  }

  Widget _buildDeviceInfo() {
    return Builder(builder: (context) {
      SettingsBloc bloc = context.read();
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText("${bloc.coreDeviceModel} ${bloc.coreDeviceAdditionalInfo}", dimmed: true,),
          CustomText("${bloc.packageInfo.appName} v${bloc.packageInfo.version}", dimmed: true,),
          //todo вынести этот цвет в конструктор CustomText.dimmed()
        ],
      );
    });
  }

  Widget _buildDarkThemeSwitch() {
    return Builder(builder: (context) {
      SettingsBloc bloc = context.read();
      return CheckboxListTile(
        value: bloc.isDarkTheme,
        onChanged: (val) {
          bloc
              .onDarkThemeValueChangeRequested()
              .then((value) => context.findAncestorStateOfType<EunnectState>()!.onThemeModeChanged());
        },
        title: CustomText(
          "Темная тема",
          textAlign: TextAlign.start,
          fontSize: 17,
        ), //добавить CustomText.header()
        secondary: const Icon(Icons.dark_mode),
      );
    });
  }
}
