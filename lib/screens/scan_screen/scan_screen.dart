import 'package:eunnect/blocs/main_bloc/main_bloc.dart';
import 'package:eunnect/constants.dart';
import 'package:eunnect/models/device_info/device_info.dart';
import 'package:eunnect/routes.dart';
import 'package:eunnect/screens/scan_screen/scan_paired_device.dart';
import 'package:eunnect/widgets/custom_expansion_tile.dart';
import 'package:eunnect/widgets/device_info_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        appBar: AppBar(
          title: const Text("Подключение Устройств"),
          actions: [IconButton(onPressed: () => Navigator.pushNamed(context, settingsRoute), icon: const Icon(Icons.settings))],
        ),
        body: BlocConsumer<ScanBloc, ScanState>(listener: (context, state) {
          if (state is MoveToLastOpenDeviceState) _onMoveToActionScreen(context: context, deviceInfo: state.device);
        }, buildWhen: (prevS, curS) {
          return true;
        }, builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 3 * horizontalPadding),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const CustomText(
                    "Другие устройства, запустившие $appName в той же сети, должны появиться здесь.",
                    textAlign: TextAlign.start,
                    fontSize: 16,
                  ),
                  if (mainBloc.hasConnection) _buildFoundDeviceList(devices: bloc.foundDevices, bloc: bloc),
                  _buildPairedDeviceList(devices: bloc.pairedDevices, bloc: bloc),
                ],
              ),
            ),
          );
        }),
      );
    });
  }

  Widget _buildFoundDeviceList({required List<DeviceInfo> devices, required ScanBloc bloc}) => CustomExpansionTile(
        initiallyExpanded: bloc.isFoundDeviceListExpanded,
        onExpansionChanged: bloc.onFoundDeviceExpansionChanged,
        text: "Обнаруженные устройства ${devices.isNotEmpty ? "(${devices.length})" : ""}",
        children: devices
            .map((e) => DeviceInfoWidget(
                  deviceInfo: e,
                  onTap: () => bloc.onPairRequested(e),
                ))
            .toList(),
      );

  Widget _buildPairedDeviceList({required List<ScanPairedDevice> devices, required ScanBloc bloc}) => Builder(
      builder: (context) => CustomExpansionTile(
            initiallyExpanded: bloc.isPairedDeviceListExpanded,
            onExpansionChanged: bloc.onPairedDeviceExpansionChanged,
            text: "Сопряженные устройства ${devices.isNotEmpty ? "(${devices.length})" : ""}",
            children: devices
                .map((e) => DeviceInfoWidget(
                      deviceInfo: e,
                      highlightDevice: e.available,
                      additionalText: e.available ? "" : "(не доступно)",
                      onTap: () => _onMoveToActionScreen(context: context, deviceInfo: e),
                    ))
                .toList(),
          ));

//todo вынести в actions_screen
  Future<void> _onMoveToActionScreen({required BuildContext context, required ScanPairedDevice deviceInfo}) async {
    ScanBloc bloc = context.read();
    bloc.onSaveLastOpenDevice(deviceInfo);
    dynamic res = await Navigator.of(context).pushNamed(deviceActionsRoute, arguments: deviceInfo);
    bloc.onDeleteLastOpenDevice();
    if (res == true) bloc.getSavedDevices();
  }
}
