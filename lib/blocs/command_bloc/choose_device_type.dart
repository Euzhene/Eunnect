
import 'package:eunnect/models/device_info/device_type.dart';


class ChooseDeviceType {
  final DeviceType type;
  final bool isAdded;

  ChooseDeviceType({required this.type, required this.isAdded});

  ChooseDeviceType copyWith({bool? isAdded}) => ChooseDeviceType(type: type, isAdded: isAdded ?? this.isAdded);
}