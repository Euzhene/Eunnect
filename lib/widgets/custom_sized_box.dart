import 'package:eunnect/constants.dart';
import 'package:flutter/cupertino.dart';

class VerticalSizedBox extends SizedBox {
  const VerticalSizedBox([double? height]) : super(height: height ?? verticalPadding);
}

class HorizontalSizedBox extends SizedBox {
  const HorizontalSizedBox([double? width]) : super(width: width ?? horizontalPadding);
}
