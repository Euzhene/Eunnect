import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/device_info/device_type.dart';

class DeviceIcon extends StatelessWidget {
  final DeviceType deviceType;
  final bool highLight;

  const DeviceIcon({
    super.key,
    required this.deviceType,
    this.highLight = false,
  });

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    switch (deviceType) {
      case DeviceType.windows:
        iconData = FontAwesomeIcons.windows;
        break;
      case DeviceType.linux:
        iconData = FontAwesomeIcons.linux;
        break;
      case DeviceType.phone:
        iconData = Icons.phone_android;
        break;
      case DeviceType.tablet:
        iconData = Icons.tablet_mac_sharp;
        break;
      default:
        iconData = Icons.question_mark;
        break;
    }

    return Icon(iconData, color: highLight ? Colors.green : null);
  }
}
