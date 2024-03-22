import 'package:app_settings/app_settings.dart';
import 'package:eunnect/blocs/scan_bloc/add_device_by_qr_bloc.dart';
import 'package:eunnect/helpers/get_it_helper.dart';
import 'package:eunnect/models/device_info/device_info.dart';
import 'package:eunnect/widgets/custom_button.dart';
import 'package:eunnect/widgets/custom_screen.dart';
import 'package:eunnect/widgets/custom_sized_box.dart';
import 'package:eunnect/widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../constants.dart';
import '../../routes.dart';

class AddDeviceByQrScreen extends StatefulWidget {
  final GlobalKey qrKey = GlobalKey();
  final DeviceInfo deviceInfo = GetItHelper.i<DeviceInfo>();

  AddDeviceByQrScreen({super.key});

  @override
  State<StatefulWidget> createState() => AddDeviceByQrState();

  static Future<DeviceInfo?> openScreen(BuildContext context) async {
    Widget screen = BlocProvider(create: (ctx) => AddDeviceByQrBloc(), child: AddDeviceByQrScreen());

    return pushScreen<DeviceInfo?>(context, screen: screen, screenName: (AddDeviceByQrScreen).toString());
  }
}

class AddDeviceByQrState extends State<AddDeviceByQrScreen> {
  bool isCameraGranted = true;

  @override
  Widget build(BuildContext context) {
    return CustomScreen(
      appbarText: "Добавление по QR",
      child: BlocConsumer<AddDeviceByQrBloc, QrState>(listener: (context, state) {
        if (state is QrSuccess) Navigator.of(context).pop(state.deviceInfo);
      }, builder: (context, state) {
        AddDeviceByQrBloc bloc = context.read();

        return Column(
          children: [
            const CustomText("Для подключения вам нужно отсканировать данный QR с другого устройства"),
            QrImageView(
              foregroundColor: Theme.of(context).brightness == Brightness.light ? black : white,
              data: widget.deviceInfo.toJsonString(),
              size: 250,
            ),
            const VerticalSizedBox(),
            if (isMobile) ...[
              const CustomText("ИЛИ", fontSize: 25),
              const VerticalSizedBox(),
              const CustomText("Отсканируйте QR с помощью данной камеры"),
              const VerticalSizedBox(),
              SizedBox(
                  width: 250,
                  height: 250,
                  child: QRView(
                    key: widget.qrKey,
                    onQRViewCreated: bloc.onQRViewCreated,
                    onPermissionSet: (controller, granted) => _onPermissionSet(controller, granted, bloc),
                  )),
              if (!isCameraGranted) ...[
                const Row(
                  children: [
                    Icon(Icons.warning, color: errorColor),
                    HorizontalSizedBox(),
                    Expanded(
                      child: CustomText(
                        "Для сканирования QR требуется дать доступ к камере. Перейдите в настройки приложения и выдайте это разрешение",
                        color: errorColor,
                      ),
                    ),
                  ],
                ),
                const VerticalSizedBox(),
                CustomButton(
                    onPressed: () => AppSettings.openAppSettings(type: AppSettingsType.settings), text: "Открыть настройки"),
              ],
            ]
          ],
        );
      }),
    );
  }

  void _onPermissionSet(QRViewController controller, bool granted, AddDeviceByQrBloc bloc) {
    setState(() {
      isCameraGranted = granted;
    });
  }
}
