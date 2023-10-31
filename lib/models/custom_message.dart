import 'dart:convert';

import 'package:flutter/foundation.dart';

class IsolateMessage {
  final ErrorMessage? errorMessage;
  final bool done;
  final dynamic data;

  IsolateMessage({this.errorMessage, this.done = false, this.data});
}

const _shortErrorField = "short_error";

class ErrorMessage {
  final String shortError;
  final Object? error;
  final StackTrace? stackTrace;

  ErrorMessage({required this.shortError, this.error, this.stackTrace});

  String toJsonString() {
    Map<String, dynamic> json = {_shortErrorField: shortError};
    return jsonEncode(json);
  }

  factory ErrorMessage.fromJsonString(String jsonString) {
    Map<String, dynamic> json = jsonDecode(jsonString);
    return ErrorMessage(shortError: json[_shortErrorField]);
  }
}

const _callField = "call";
const _errorMessageField = "error";
const _dataField = "data";
const _senderIdField = "device_id";

class SocketMessage {
  final String call;
  final String? error;
  final String? data;
  final String? deviceId;

  SocketMessage({required this.call, this.data, this.error,this.deviceId});

  String toJsonString() {
    Map<String, dynamic> json = {
      _callField: call,
      _dataField: data,
      _errorMessageField: error,
      _senderIdField: deviceId,
    };
    return jsonEncode(json);
  }

  List<int> toUInt8List() => utf8.encode(toJsonString());

  factory SocketMessage.fromJsonString(String jsonString) {
    Map<String, dynamic> json = jsonDecode(jsonString);

    return SocketMessage(
        call: json[_callField], error: json[_errorMessageField], data: json[_dataField], deviceId: json[_senderIdField]);
  }

  factory SocketMessage.fromUInt8List(Uint8List data) => SocketMessage.fromJsonString(utf8.decode(data));
}

const _bytesField = "bytes";
const _filenameField = "filename";
class FileMessage {
  final List<int> bytes;
  final String filename;

  FileMessage({required this.bytes, required this.filename});

  FileMessage copyWith({List<int>? bytes}) => FileMessage(bytes: bytes ?? this.bytes,  filename: filename);

  String toJsonString() => jsonEncode({
        _bytesField: bytes.toString(),
        _filenameField: filename,
      });

  List<int> toUInt8List() => utf8.encode(toJsonString());

  factory FileMessage.fromJsonString(String jsonString) {
    Map<String, dynamic> json = jsonDecode(jsonString);

    return FileMessage(
      bytes: jsonDecode(json[_bytesField]).cast<int>().toList(),
      filename: json[_filenameField],
   //   extension: json[_extensionField],
    );
  }
}
