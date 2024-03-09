import 'dart:convert';

const _idField = "id";
const _nameField = "name";
const _descriptionField = "description";
const _commandField = "command";

class SocketCommand {
  final String id;
  final String name;
  final String? description;
  final String command;

  SocketCommand({
    required this.id,
    required this.name,
    this.description,
    required this.command,
  });

  SocketCommand.fromJson(Map<String, dynamic> json)
      : id = json[_idField],
        name = json[_nameField],
        description = json[_descriptionField],
        command = json[_commandField];

  Map<String, dynamic> _toJson() => {
        _idField: id,
        _nameField: name,
        _descriptionField: description,
        _commandField: command,
      };

  String toJsonString() => jsonEncode(_toJson());

  factory SocketCommand.fromJsonString(String jsonString) {
    Map<String, dynamic> json = jsonDecode(jsonString);
    return SocketCommand.fromJson(json);
  }

  static List<SocketCommand> fromJsonList(String listJson) {
    Iterable list = jsonDecode(listJson);
    return List.from(list.map((e) => SocketCommand.fromJsonString(e)));
  }
}
