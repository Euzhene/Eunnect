import 'dart:io';

import 'package:eunnect/blocs/main_bloc/main_bloc.dart';
import 'package:eunnect/constants.dart';
import 'package:eunnect/models/device_info.dart';
import 'package:eunnect/routes.dart';
import 'package:eunnect/screens/scan_screen/scan_paired_device.dart';
import 'package:eunnect/widgets/custom_button.dart';
import 'package:eunnect/widgets/custom_sized_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../blocs/scan_bloc/scan_bloc.dart';
import '../../blocs/scan_bloc/scan_state.dart';
import '../../widgets/custom_text.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ScanBloc bloc = context.read<ScanBloc>();
    MainBloc mainBloc = context.read<MainBloc>();

    return BlocBuilder<MainBloc, MainState>(builder: (context, state) {
      return Scaffold(
        appBar: AppBar(title: const Text("Подключение Устройств")),
        body: BlocConsumer<ScanBloc, ScanState>(
            listener: (context, state) {},
            buildWhen: (prevS, curS) {
              return true;
            },
            builder: (context, state) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 3 * horizontalPadding),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            CustomText(
                              "Другие устройства, запустившие $appName в той же сети, должны появиться здесь.",
                              textAlign: TextAlign.start,
                              fontSize: 16,
                            ),
                            if (mainBloc.hasConnection) _buildFoundDeviceList(devices: bloc.foundDevices, bloc: bloc),
                            _buildPairedDeviceList(devices: bloc.pairedDevices, bloc: bloc, context: context),
                          ],
                        ),
                      ),
                      if (!Platform.isWindows)
                        Positioned(
                            bottom: 0,
                            right: 0,
                            child: CustomButton(
                              onPressed: () => bloc.onSendLogs(),
                              text: "Отправить логи",
                              textColor: black,
                            ))
                    ],
                  ),
                ),
              );
            }),
      );
    });
  }

  Widget _buildFoundDeviceList({required List<DeviceInfo> devices, required ScanBloc bloc}) => _buildBaseDeviceList(
      devices: devices,
      label: "Обнаруженные устройства",
      initiallyExpanded: bloc.isFoundDeviceListExpanded,
      onExpansionChanged: (expanded)=>bloc.onFoundDeviceExpansionChanged(expanded),
      list: devices.map((e) => _buildFoundDeviceItem(e: e, bloc: bloc)).toList());

  Widget _buildPairedDeviceList(
          {required List<ScanPairedDevice> devices, required ScanBloc bloc, required BuildContext context}) =>
      _buildBaseDeviceList(
          devices: devices,
          label: "Сопряженные устройства",
          initiallyExpanded: bloc.isPairedDeviceListExpanded,
          onExpansionChanged: (expanded)=>bloc.onPairedDeviceExpansionChanged(expanded),
          list: devices.map((e) => _buildPairedDeviceItem(e: e, context: context)).toList());

  Widget _buildBaseDeviceList({required List devices, required String label, required List<Widget> list,required bool initiallyExpanded,  required Function(bool) onExpansionChanged}) {
    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      shape: const Border(),
      title: CustomText("$label ${devices.isNotEmpty ? "(${devices.length})" : ""}", fontSize: 17,textAlign: TextAlign.start),
      onExpansionChanged: onExpansionChanged,
      children: devices.isEmpty
          ? [const VerticalSizedBox(verticalPadding * 2), Align(alignment: Alignment.center, child: CustomText("Не найдено"))]
          : [
              Padding(
                padding: const EdgeInsets.all(horizontalPadding),
                child: Column(mainAxisSize: MainAxisSize.min, children: list),
              )
            ],
    );
  }

  Widget _buildPairedDeviceItem({required ScanPairedDevice e, required BuildContext context}) {
    return _buildBaseDeviceItem(
        deviceInfo: e,
        additionalText: e.available ? "" : "(не доступно)",
        highlightDevice: e.available,
        onPressed: () => Navigator.of(context).pushNamed(deviceActionsRoute, arguments: e).then((value) {
              if (value == true) context.read<ScanBloc>().getSavedDevices();
            }));
  }

  Widget _buildFoundDeviceItem({required DeviceInfo e, required ScanBloc bloc}) {
    return _buildBaseDeviceItem(deviceInfo: e, onPressed: () => bloc.onPairRequested(e));
  }

  Widget _buildBaseDeviceItem(
      {required DeviceInfo deviceInfo,
      required VoidCallback onPressed,
      String additionalText = "",
      bool highlightDevice = false}) {
    IconData iconData;
    switch (deviceInfo.type) {
      case DeviceType.windows:
        iconData = FontAwesomeIcons.windows;
        break;
      case DeviceType.linux:
        iconData = FontAwesomeIcons.linux;
        break;
      case DeviceType.phone:
        iconData = Icons.phone_android;
        break;
      case DeviceType.tablet:
        iconData = Icons.tablet_mac_sharp;
        break;
      default:
        iconData = Icons.question_mark;
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(verticalPadding),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconData, color: highlightDevice ? Colors.green : Colors.black),
                const HorizontalSizedBox(horizontalPadding / 2),
                CustomText(
                  "${deviceInfo.name} $additionalText",
                  fontSize: 20,
                  color: highlightDevice ? Colors.green : Colors.black,
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildNoConnectionWidget() {
    return const Center(
      child: Text("Нет подключения к сети"),
    );
  }
}
