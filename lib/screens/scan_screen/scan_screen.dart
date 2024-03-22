import 'package:eunnect/blocs/main_bloc/main_bloc.dart';
import 'package:eunnect/constants.dart';
import 'package:eunnect/models/device_info/device_info.dart';
import 'package:eunnect/screens/actions_screen.dart';
import 'package:eunnect/screens/scan_screen/add_device_by_qr_screen.dart';
import 'package:eunnect/screens/scan_screen/scan_paired_device.dart';
import 'package:eunnect/screens/settings_screen/settings_screen.dart';
import 'package:eunnect/screens/scan_screen/add_device_by_ip_dialog.dart';
import 'package:eunnect/widgets/custom_expansion_tile.dart';
import 'package:eunnect/widgets/custom_screen.dart';
import 'package:eunnect/widgets/device_info_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

import '../../blocs/scan_bloc/scan_bloc.dart';
import '../../blocs/scan_bloc/scan_state.dart';
import '../../helpers/get_it_helper.dart';
import '../../widgets/custom_text.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ScanBloc bloc = context.read<ScanBloc>();
    MainBloc mainBloc = context.read<MainBloc>();

    return BlocBuilder<MainBloc, MainState>(
        builder: (context, state) => CustomScreen(
            appbarText: "Подключение Устройств",
            padding: const EdgeInsets.symmetric(vertical: verticalPadding, horizontal: horizontalPadding * 3),
            appbarActions: [IconButton(onPressed: () => SettingsScreen.openScreen(context), icon: const Icon(Icons.settings))],
            fabLocation: ExpandableFab.location,
            fab: _buildFab(),
            child: BlocConsumer<ScanBloc, ScanState>(listener: (context, state) {
              if (state is MoveToLastOpenDeviceState) _onMoveToActionScreen(context: context, deviceInfo: state.device);
            }, buildWhen: (prevS, curS) {
              return true;
            }, builder: (context, state) {
              return RefreshIndicator(
                displacement: 20,
                onRefresh: bloc.onScanDevices,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      CustomText(
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
            })));
  }

  Widget _buildFab() => Builder(builder: (context) {
        return ExpandableFab(
          openButtonBuilder: RotateFloatingActionButtonBuilder(child: const Icon(Icons.add)),
          children: [
            FloatingActionButton(
              heroTag: "ip",
              tooltip: "Добавить по IP",
              child: const Icon(Icons.location_on_rounded),
              onPressed: () => AddDeviceByIpDialog.openDialog(context),
            ),
            FloatingActionButton(
              heroTag: "qr",
              tooltip: "Добавить по QR",
              child: const Icon(Icons.qr_code_2),
              onPressed: () async {
                ScanBloc bloc = context.read();
                DeviceInfo? deviceInfo = await AddDeviceByQrScreen.openScreen(context);
                if (deviceInfo != null) bloc.onPairRequested(deviceInfo);
              },
            ),
          ],
        );
      });

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

  Future<void> _onMoveToActionScreen({required BuildContext context, required ScanPairedDevice deviceInfo}) async {
    ScanBloc bloc = context.read();
    bloc.onSaveLastOpenDevice(deviceInfo);
    bool? res = await ActionsScreen.openScreen(context, deviceInfo: deviceInfo);
    bloc.onDeleteLastOpenDevice();
    if (res == true) bloc.getSavedDevices();
  }

  static Widget getScreen() {
    return MultiBlocProvider(providers: [BlocProvider(create: (_) => GetItHelper.i<ScanBloc>())], child: const ScanScreen());
  }
}
