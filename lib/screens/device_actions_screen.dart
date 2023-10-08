import 'package:eunnect/blocs/device_actions_bloc/device_actions_bloc.dart';
import 'package:eunnect/widgets/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../widgets/custom_text.dart';

class DeviceActionsScreen extends StatelessWidget {
  const DeviceActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    DeviceActionsBloc bloc = context.read();

    return Scaffold(
        appBar: AppBar(
          title: Text(bloc.deviceInfo.deviceInfo.name),
          centerTitle: true,
        ),
        body: Column(
          children: [
            InkWell(
              onTap: () =>bloc.onSendBuffer(),
              child: CustomCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: CustomText(
                    "Передать буфер обмена",
                    fontSize: 20,
                  ),
                ),
              ),
            )
          ],
        ));
  }
}
