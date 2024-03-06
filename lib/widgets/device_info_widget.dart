import 'package:eunnect/models/device_info/device_info.dart';
import 'package:eunnect/widgets/custom_text.dart';
import 'package:flutter/material.dart';

import 'device_icon.dart';

class DeviceInfoWidget extends StatelessWidget {
  final DeviceInfo deviceInfo;
  final Widget? suffixIcon;
  final bool highlightDevice;
  final String additionalText;
  final VoidCallback? onTap;

  const DeviceInfoWidget({
    super.key,
    required this.deviceInfo,
    this.suffixIcon,
    this.highlightDevice = false,
    this.additionalText = "",
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: DeviceIcon(deviceType: deviceInfo.type, highLight: highlightDevice),
      title: CustomText(
        "${deviceInfo.name} $additionalText",
        fontSize: 20,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: suffixIcon,
    );
  }
}
