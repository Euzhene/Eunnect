import 'package:eunnect/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CameraWidget extends StatefulWidget {
  final RTCVideoRenderer rtcVideoRenderer;

  const CameraWidget({
    super.key,
    required this.rtcVideoRenderer,
  });

  @override
  State<StatefulWidget> createState() => _CameraState();
}

class _CameraState extends State<CameraWidget> {
  Offset offset = Offset.zero;
  double scale = 1;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: offset.dy,
      left: offset.dx,
      child: GestureDetector(
        onScaleUpdate: (details) {
           setState(() {
             offset += details.focalPointDelta;
             if (details.scale != 1) scale = details.scale;
           });
        },
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: 300,
            height: 300,
            clipBehavior: Clip.hardEdge,
            padding: const EdgeInsets.all(horizontalPadding),
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: RTCVideoView(widget.rtcVideoRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain, mirror: true,),
          ),
        ),
      ),
    );
  }
}
