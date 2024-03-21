import 'dart:convert';

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


const _filenameField = "name";
const _fileSizeField = "size";
const _idField = "id";

class FileMessage {
  final List<int> bytes;
  final String filename;
  final int fileSize;
  final String? id;

  FileMessage({this.bytes = const [], required this.filename, required this.fileSize, this.id});

  FileMessage copyWith({List<int>? bytes, String? id}) => FileMessage(bytes: bytes ?? this.bytes, filename: filename, fileSize: fileSize, id: id ?? this.id);

  String toJsonString() => jsonEncode({_filenameField: filename, _fileSizeField: fileSize, _idField : id});

  List<int> toUInt8List() => utf8.encode(toJsonString());

  factory FileMessage.fromJsonString(String jsonString) {
    Map<String, dynamic> json = jsonDecode(jsonString);

    return FileMessage(
      bytes: [],
      filename: json[_filenameField],
      fileSize: json[_fileSizeField],
      id: json[_idField],
    );
  }
}
