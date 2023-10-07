import 'package:eunnect/constants.dart';
import 'package:eunnect/models/device_info.dart';
import 'package:eunnect/widgets/custom_card.dart';
import 'package:eunnect/widgets/custom_sized_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../device_scan_bloc.dart';
import '../widgets/custom_text.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    DeviceScanBloc bloc = context.read<DeviceScanBloc>();
    return Scaffold(
      body: BlocConsumer<DeviceScanBloc, DeviceScanState>(
        listener: (context, state) {
        },
        builder: (context, state) => Center(
          child: Padding(
            padding: const EdgeInsets.all(horizontalPadding),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CustomCard(
                      headerText: "Доступные устройства (${state.devicesNvl.length})",
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 300),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IntrinsicWidth(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ...state.devicesNvl.map((e) => _buildDeviceItem(e)).toList()
                                ],
                              ),
                            ),
                            if (state.loading) ...[
                              const VerticalSizedBox(),
                              const CircularProgressIndicator(color: Colors.white),
                              const VerticalSizedBox(4),
                              CustomText("Поиск${state.loadingDots}"),
                            ],
                          ],
                        ),
                      )),
                  TextButton(
                      onPressed: state.loading ? null : () => bloc.onScanDevicesRequested(),
                      child: CustomText("Поиск устройств")),
                  TextButton(
                      onPressed: () => bloc.onCancelScanRequested(),
                      child: CustomText("Отменить поиск")),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceItem(DeviceInfo e) {
    IconData iconData;
    switch (e.platform) {
      case windowsPlatform:
        iconData = Icons.window_sharp;
        break;
      case androidPlatform:
        iconData = Icons.android;
        break;
      default:
        iconData = Icons.question_mark;
        break;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const VerticalSizedBox(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, color: Colors.white),
            const HorizontalSizedBox(horizontalPadding / 2),
            CustomText(e.name, fontSize: 20),
          ],
        )
      ],
    );
  }
}
