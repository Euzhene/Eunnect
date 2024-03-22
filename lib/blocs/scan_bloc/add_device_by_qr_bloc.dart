import 'package:eunnect/models/device_info/device_info.dart';
import 'package:f_logs/f_logs.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

part 'add_device_by_qr_state.dart';

class AddDeviceByQrBloc extends Cubit<QrState> {
  AddDeviceByQrBloc() : super(QrState());

  void onQRViewCreated(QRViewController controller) {
    controller.scannedDataStream.listen((Barcode scanData) async {
      String? data = scanData.code;
      if (data == null) return;
      try {
        await controller.stopCamera();

        DeviceInfo deviceInfo = DeviceInfo.fromJsonString(data);
        emit(QrSuccess(deviceInfo));
      } catch (e, st) {
        FLog.error(text: e.toString(), stacktrace: st);
        await controller.resumeCamera();
      }
    });
  }
}
