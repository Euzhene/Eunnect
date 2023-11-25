import 'dart:convert';
import 'dart:typed_data';

import 'package:eunnect/models/socket/socket_message_status.dart';


const _callField = "call";
const _statusMessageField = "status";
const _dataField = "data";
const _senderIdField = "device_id";

class ClientMessage extends SocketMessage {
  ClientMessage({
    required this.call,
    required this.data,
    required this.deviceId,
  });

  final String deviceId;
  final String call;
  @override covariant String data;

  @override
  Map<String, dynamic> get _json => {
    _callField: call,
    _dataField: data,
    _senderIdField: deviceId,
  };

  factory ClientMessage.fromJsonString(String jsonString) {
    Map<String, dynamic> json = jsonDecode(jsonString);

    return ClientMessage(call: json[_callField], data: json[_dataField], deviceId: json[_senderIdField]);
  }

  factory ClientMessage.fromUInt8List(Uint8List data) => ClientMessage.fromJsonString(utf8.decode(data));
}

class ServerMessage extends SocketMessage {
  ServerMessage({required this.status, super.data});

  final int status;

  bool get isErrorStatus => status < 200;

  String? get getError => isErrorStatus ? SocketMessageStatus.statuses[status] : null;

  @override
  Map<String, dynamic> get _json => {
    if (data != null) _dataField: data,
    _statusMessageField: status,
  };

  factory ServerMessage.fromJsonString(String jsonString) {
    Map<String, dynamic> json = jsonDecode(jsonString);

    return ServerMessage(data: json[_dataField], status:json[_statusMessageField]);
  }

  factory ServerMessage.fromUInt8List(Uint8List data) => ServerMessage.fromJsonString(utf8.decode(data));
}

abstract class SocketMessage {
  final String? data;

  SocketMessage({this.data});

  Map<String, dynamic> get _json;

  String toJsonString() => jsonEncode(_json);

  List<int> toUInt8List() => utf8.encode(toJsonString());
}