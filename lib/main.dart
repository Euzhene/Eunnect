import 'package:eunnect/constants.dart';
import 'package:eunnect/device_scan_bloc.dart';
import 'package:eunnect/routes.dart';
import 'package:eunnect/screens/scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

String ip = "0.0.0.0";
int port = 10242;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Logger.root.level = Level.FINE; //set to finest for detailed log
  Logger.root.onRecord.listen((record) {
    print('${DateFormat.Hms().format(record.time)}: ${record.level.name}: ${record.loggerName}: ${record.message} ${record
        .error} ${record.stackTrace}');
  });

  runApp(const Eunnect());
}

class Eunnect extends StatelessWidget {
  const Eunnect({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MaKuKu',
      theme: ThemeData(
        scaffoldBackgroundColor: scaffoldBackgroundColor,
        useMaterial3: true,
      ),
      onGenerateRoute: onGenerateRoute,
      initialRoute: scanRoute,
    );
  }
}

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});
//
//   final String title;
//
//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }
//
// class _MyHomePageState extends State<MyHomePage> {
//   // String? _message;
//   bool _loading = false;
//
//   @override
//   void initState() {
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     DeviceScanBloc bloc = context.read<DeviceScanBloc>();
//
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         title: Text(widget.title),
//       ),
//       body: BlocConsumer<DeviceScanBloc, DeviceScanState>(
//         listener: (context, state) {},
//         builder: (context, state) => Center(
//           child: Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: <Widget>[
//                 ...state.devicesNvl
//                     .map((e) => Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [const SizedBox(height: 8), Text(e)],
//                         ))
//                     .toList(),
//                 TextButton(
//                     onPressed: _loading
//                         ? null
//                         : () async {
//                             setState(() {
//                               _loading = true;
//                             });
//                             await bloc.onScanDevicesRequested();
//                             setState(() {
//                               _loading = false;
//                             });
//                           },
//                     child: const Text("Поиск устройств")),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
