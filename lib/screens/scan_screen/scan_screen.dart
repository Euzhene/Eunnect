import 'package:eunnect/blocs/main_bloc/main_bloc.dart';
import 'package:eunnect/constants.dart';
import 'package:eunnect/models/device_info/device_info.dart';
import 'package:eunnect/routes.dart';
import 'package:eunnect/screens/scan_screen/scan_paired_device.dart';
import 'package:eunnect/widgets/custom_sized_box.dart';
import 'package:eunnect/widgets/device_icon.dart';
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
        appBar: AppBar(title: const Text("Подключение Устройств"),actions: [IconButton(onPressed: ()=>Navigator.pushNamed(context, settingsRoute), icon: const Icon(Icons.settings))],),
        body: BlocConsumer<ScanBloc, ScanState>(
            listener: (context, state) {
              if (state is MoveToLastOpenDeviceState) _onMoveToActionScreen(context: context, deviceInfo: state.device);
            },
            buildWhen: (prevS, curS) {
              return true;
            },
            builder: (context, state) {
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
                      _buildPairedDeviceList(devices: bloc.pairedDevices, bloc: bloc, context: context),
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

  //todo вынести группирующий виджет в отдельный класс
  Widget _buildBaseDeviceList({required List devices, required String label, required List<Widget> list,required bool initiallyExpanded,  required Function(bool) onExpansionChanged}) {
    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      shape: const Border(),
      title: CustomText("$label ${devices.isNotEmpty ? "(${devices.length})" : ""}", fontSize: 17,textAlign: TextAlign.start),
      onExpansionChanged: onExpansionChanged,
      children: devices.isEmpty
          ? [const Align(alignment: Alignment.center, child: CustomText("Не найдено"))]
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
        onPressed: () => _onMoveToActionScreen(context: context, deviceInfo: e),
    );
  }

  Widget _buildFoundDeviceItem({required DeviceInfo e, required ScanBloc bloc}) {
    return _buildBaseDeviceItem(deviceInfo: e, onPressed: () => bloc.onPairRequested(e));
  }

  Widget _buildBaseDeviceItem(
      {required DeviceInfo deviceInfo,
      required VoidCallback onPressed,
      String additionalText = "",
      bool highlightDevice = false}) {

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
                DeviceIcon(deviceType: deviceInfo.type, highLight: highlightDevice),
                const HorizontalSizedBox(horizontalPadding / 2),
                Expanded(
                  child: CustomText(
                    "${deviceInfo.name} $additionalText",
                    fontSize: 20,
                    color: highlightDevice ? Colors.green : null,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Future<void> _onMoveToActionScreen({required BuildContext context, required ScanPairedDevice deviceInfo}) async {
    ScanBloc bloc = context.read();
    bloc.onSaveLastOpenDevice(deviceInfo);
    dynamic res = await Navigator.of(context).pushNamed(deviceActionsRoute, arguments: deviceInfo);
    bloc.onDeleteLastOpenDevice();
    if (res == true) bloc.getSavedDevices();
}
}
