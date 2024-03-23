import 'dart:io';

import 'package:eunnect/blocs/main_bloc/main_bloc.dart';
import 'package:eunnect/blocs/scan_bloc/scan_bloc.dart';
import 'package:eunnect/helpers/get_it_helper.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../constants.dart';
import '../../helpers/ssl_helper.dart';
import '../../models/device_info/device_info.dart';
import '../../models/socket/custom_server_socket.dart';
import '../../models/socket/socket_message.dart';

part 'add_device_by_ip_state.dart';

class AddDeviceByIpBloc extends Cubit<IpState> {
  final ScanBloc _scanBloc = GetItHelper.i<ScanBloc>();
  final MainBloc _mainBloc = GetItHelper.i<MainBloc>();

  AddDeviceByIpBloc() : super(IpState());

  Future<void> onAddDeviceByIp(String ip) async {
    try {
      FLog.trace(text: "getting info of a device by ip...");
      emit(AwaitPairingDeviceState(null));
      SecureSocket socket = await SecureSocket.connect(InternetAddress(ip, type: InternetAddressType.IPv4), port,
          timeout: const Duration(seconds: 2), onBadCertificate: (X509Certificate certificate) {
        return SslHelper.handleSelfSignedCertificate(certificate: certificate, pairedDevicesId: [], deviceIdCheck: false);
      });

      socket.add(ClientMessage(call: deviceInfoCall, data: "", deviceId: GetItHelper.i<DeviceInfo>().id).toUInt8List());
      await socket.close();

      final bytes = await socket.single;
      ServerMessage socketMessage = ServerMessage.fromUInt8List(bytes);
      if (socketMessage.isErrorStatus) {
        FLog.error(text: socketMessage.getError!);
        _mainBloc.emitDefaultError(socketMessage.getError!);
        return;
      }
      DeviceInfo pairingDeviceInfo = DeviceInfo.fromJsonString(socketMessage.data!);
      emit(AwaitPairingDeviceState(pairingDeviceInfo));
      await _scanBloc.onPairRequested(pairingDeviceInfo);
    } catch (e, st) {
      FLog.error(text: e.toString(), stacktrace: st);
      _mainBloc.emitDefaultError(e.toString());
    }
    emit(IpState());
  }
}
