import 'dart:io';

import 'package:eunnect/constants.dart';
import 'package:eunnect/models/device_info.dart';
import 'package:eunnect/routes.dart';
import 'package:eunnect/widgets/custom_button.dart';
import 'package:eunnect/widgets/custom_card.dart';
import 'package:eunnect/widgets/custom_sized_box.dart';
import 'package:eunnect/widgets/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/scan_bloc/scan_bloc.dart';
import '../blocs/scan_bloc/scan_state.dart';
import '../widgets/custom_text.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ScanBloc bloc = context.read<ScanBloc>();
    return Scaffold(
      body: BlocConsumer<ScanBloc, ScanState>(listener: (context, state) {
        // if (state is PairDialogState)
        //   showConfirmDialog(context,
        //       title: "Устройство ${state.pairDeviceInfo.deviceInfo.name} хочет сделать сопряжение",
        //       onConfirm: () => bloc.onPairConfirmed(state.pairDeviceInfo),
        //       onCancel: () => bloc.onPairConfirmed(null));
      }, buildWhen: (prevS, curS) {
        return true;
      }, builder: (context, state) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(horizontalPadding),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        CustomCard(
                            headerText: "Доступные устройства (${state.foundDevices.length + state.pairedDevices.length})",
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
                                        if (state.pairedDevices.isNotEmpty)
                                          CustomText(
                                            "Сопряженные",
                                            fontSize: 15,
                                          ),
                                        ...state.pairedDevices
                                            .map((e) =>
                                                _buildDeviceItem(e: e, onPressed: (){}))
                                            .toList(),
                                        if (state.foundDevices.isNotEmpty)
                                          CustomText(
                                            "Найденные",
                                            fontSize: 15,
                                          ),
                                        ...state.foundDevices
                                            .map((e) => _buildDeviceItem(
                                                e: e,
                                                onPressed: () async {
                                               //   Navigator.of(context).pushNamed(deviceActionsRoute, arguments: state.foundDevices);
                                                }))
                                            .toList()
                                      ],
                                    ),
                                  ),
                                  // if (state.loading) ...[
                                  //   const VerticalSizedBox(),
                                  //   const CircularProgressIndicator(color: Colors.white),
                                  //   const VerticalSizedBox(4),
                                  //   CustomText("Поиск${state.loadingDots}"),
                                  // ],
                                ],
                              ),
                            )),
                        // TextButton(
                        //     onPressed: state.loading ? null : () => bloc.onScanDevicesRequested(),
                        //     child: CustomText("Поиск устройств")),
                        // TextButton(onPressed: () => bloc.onCancelScanRequested(), child: CustomText("Отменить поиск")),
                      ],
                    ),
                  ),
                ),
                if (!Platform.isWindows)
                  Positioned(
                      bottom: 0,
                      right: 0,
                      child: CustomButton(
                        onPressed: () {},
                        text: "Отправить логи",
                        textColor: white,
                      ))
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDeviceItem({required DeviceInfo e, required VoidCallback onPressed}) {
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
        InkWell(
          onTap: onPressed,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconData, color: Colors.white),
              const HorizontalSizedBox(horizontalPadding / 2),
              CustomText(e.name, fontSize: 20),
            ],
          ),
        )
      ],
    );
  }
}
