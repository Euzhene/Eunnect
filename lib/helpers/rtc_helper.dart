import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:eunnect/helpers/ssl_helper.dart';
import 'package:eunnect/models/device_info/device_info.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../constants.dart';

class RtcHelper {
  final SslHelper sslHelper;

  Function(RTCVideoRenderer)? onVideoRendererUpdated;
  MediaStream? _localStream;
  RTCVideoRenderer? _localRendered;

  late bool isClient;

  final Map<String, dynamic> mediaConstraints = {
    'audio': false,
    'video': true,
  };

  final Map<String, dynamic> configuration = {
    'iceTransportPolicy': 'all',
    'bundlePolicy': 'max-bundle',
    'rtcpMuxPolicy': 'require',
    'continualGatheringPolicy': 'gather-continually',
    'iceCandidatePoolSize': 0,
  };

  RtcHelper(this.sslHelper);

  Future<void> initForClient({required DeviceInfo pairedDeviceInfo}) async {
    isClient = true;
    await _createClientPeerConnection(pairedDeviceInfo);
  }

  Future<void> initForServer(DeviceInfo myDeviceInfo) async {
    isClient = false;
    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _localRendered = RTCVideoRenderer();
    await _localRendered!.initialize();
    await _localRendered!.setSrcObject(stream: _localStream);
    await _createServerPeerConnection(myDeviceInfo);
  }

  Future<void> _createClientPeerConnection(DeviceInfo pairedDeviceInfo) async {
    RTCPeerConnection peerConnection = await createPeerConnection(configuration);

    SecureSocket client =
        await SecureSocket.connect(pairedDeviceInfo.ipAddress, cameraPort, onBadCertificate: (X509Certificate certificate) {
      return SslHelper.handleSelfSignedCertificate(certificate: certificate, pairedDevicesId: [pairedDeviceInfo.id]);
    });

    client.listen((event) async {
      Map<String, dynamic> data = jsonDecode(utf8.decode(event));
      String type = data['type'];

      if (type == 'answer') {
        // Handle answer
        final RTCSessionDescription answer = RTCSessionDescription(data['sdp'], data['type']);
        peerConnection.setRemoteDescription(answer);
      }
    });
    peerConnection.onIceCandidate = (RTCIceCandidate candidate) async {
      print("onIceCandidate ${candidate.candidate}");
      client =
          await SecureSocket.connect(pairedDeviceInfo.ipAddress, cameraPort, onBadCertificate: (X509Certificate certificate) {
        return SslHelper.handleSelfSignedCertificate(certificate: certificate, pairedDevicesId: [pairedDeviceInfo.id]);
      });
      client.add(jsonEncode({
        'type': 'candidate',
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      }).codeUnits);

      client.close();
    };

    peerConnection.createOffer().then((offer) async {
      peerConnection.setLocalDescription(offer);
      String? sdp = (await peerConnection.getLocalDescription())!.sdp;
      client.add(jsonEncode({
        'type': 'offer',
        'sdp': sdp,
      }).codeUnits);
      client.close();
    });

    peerConnection.onAddTrack = (MediaStream stream, MediaStreamTrack track) async {
      print('Added remote stream: ${stream.getTracks().length}');
      RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
      remoteRenderer.initialize().then((_) {
        remoteRenderer.srcObject = stream;
        onVideoRendererUpdated?.call(remoteRenderer);
      });
    };
  }

  Future<void> _createServerPeerConnection(DeviceInfo myDeviceInfo) async {
    RTCPeerConnection peerConnection = await createPeerConnection(configuration);
    _localStream!.getTracks().forEach((track) => peerConnection.addTrack(track, _localStream!));
    SecurityContext context = await sslHelper.getServerSecurityContext();
    SecureServerSocket server = await SecureServerSocket.bind(myDeviceInfo.ipAddress, cameraPort, context);
    server.listen((socket) async {
      BytesBuilder bytesBuilder = BytesBuilder();
      await for (Uint8List bytes in socket) {
        bytesBuilder.add(bytes);
      }

      String d = utf8.decode(bytesBuilder.takeBytes());
      final Map<String, dynamic> data = jsonDecode(d);
      String type = data['type'];

      if (type == 'offer') {
        // Handle offer
        final RTCSessionDescription offer = RTCSessionDescription(data['sdp'], data['type']);
        peerConnection.setRemoteDescription(offer);
        peerConnection.createAnswer().then((answer) async {
          peerConnection.setLocalDescription(answer);
          socket.add(jsonEncode({
            'type': 'answer',
            'sdp': (await peerConnection.getLocalDescription())!.sdp,
          }).codeUnits);
          socket.close();
        });
      } else if (type == 'candidate') {
        // Handle ICE candidate
        final RTCIceCandidate candidate = RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']);
        peerConnection.addCandidate(candidate);
        socket.close();
      }
    });
  }

// @override
// Widget build(BuildContext context) {
// return MaterialApp(
// home: Scaffold(
// appBar: AppBar(
// title: Text('Video Streaming'),
// ),
// body: Center(
// child: Column(
// children: [
// if (_localRendered != null)Expanded(child: RTCVideoView(_localRendered!, mirror: true)),
// if (_remoteRendered != null) Expanded(child: RTCVideoView(_remoteRendered!,placeholderBuilder: (context){
// return CircularProgressIndicator();
// },)),
// ],
// ),
// ),
// ),
// );
// }
}
