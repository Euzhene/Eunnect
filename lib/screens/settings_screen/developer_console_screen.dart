import 'package:eunnect/blocs/developer_console_bloc/developer_console_bloc.dart';
import 'package:eunnect/constants.dart';
import 'package:eunnect/widgets/custom_sized_box.dart';
import 'package:eunnect/widgets/custom_text.dart';
import 'package:f_logs/f_logs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeveloperConsoleScreen extends StatelessWidget {
  const DeveloperConsoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    DeveloperConsoleBloc bloc = context.read();
    return BlocBuilder<DeveloperConsoleBloc, DeveloperConsoleState>(builder: (context, state) {
      return Scaffold(
        appBar: AppBar(title: const Text("Консоль разработчика")),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                  child: (state is LoadingConsoleState)
                      ? const Center(child: CircularProgressIndicator())
                      : _ConsoleWidget(bloc: bloc)),
              const VerticalSizedBox(),
              _TextFieldWidget(bloc: bloc),
            ],
          ),
        ),
      );
    });
  }
}

class _ConsoleWidget extends StatelessWidget {
  final DeveloperConsoleBloc bloc;

  const _ConsoleWidget({required this.bloc});

  @override
  Widget build(BuildContext context) {
    List<Log> logs = bloc.logs;
    if (logs.isEmpty) return Center(child: CustomText("Консоль пуста"));
    return Stack(
      children: [
        ListView.separated(
          controller: bloc.logsScrollController,
          shrinkWrap: true,
          itemCount: logs.length,
          separatorBuilder: (ctx, index) => const Divider(
            indent: horizontalPadding,
            endIndent: horizontalPadding,
          ),
          itemBuilder: (ctx, index) {
            Log log = logs[index];
            LogLevel logLevel = log.logLevel ?? LogLevel.OFF;
            Color? color = Colors.black;

            if (logLevel == LogLevel.ERROR || logLevel == LogLevel.FATAL || logLevel == LogLevel.SEVERE)
              color = Colors.red;
            else if (logLevel == LogLevel.TRACE) color = Colors.black54;
            return RichText(
                text: TextSpan(style: TextStyle(color: color, fontSize: 18), children: [
              TextSpan(text: "${logLevel.name} | "),
              TextSpan(text: "${log.text} | "),
              TextSpan(text: "${log.timestamp}"),
              if (log.stacktrace != "null") TextSpan(text: " | ${log.stacktrace}"),
            ]));
          },
        ),
        if (bloc.haveNewLogs)
          Positioned(
            right: horizontalPadding,
            bottom: 0,
            child: FloatingActionButton(onPressed: bloc.onMoveToBottom, child: const Icon(Icons.arrow_downward_rounded)),
          )
      ],
    );
  }
}

class _TextFieldWidget extends StatelessWidget {
  const _TextFieldWidget({required this.bloc});

  final DeveloperConsoleBloc bloc;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: bloc.textController,
      onFieldSubmitted: (val) => bloc.onExecuteCommand(),
      onChanged: (val) => bloc.onChangedText(),
      decoration: InputDecoration(
        hintText: "Здесь можно писать команды",
        prefixIcon: IconButton(
            tooltip: "Список команд",
            onPressed: () => onShowBottomSheet(context: context, bloc: bloc),
            icon: const Icon(Icons.question_mark)),
        suffixIcon: IconButton(
            tooltip: "Выполнить", onPressed: !bloc.isTextValid ? null : bloc.onExecuteCommand, icon: const Icon(Icons.send)),
      ),
    );
  }

  void onShowBottomSheet({required BuildContext context, required DeveloperConsoleBloc bloc}) {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: verticalPadding, horizontal: horizontalPadding),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(alignment: Alignment.center, child: CustomText("Доступные команды", fontSize: 24)),
                const VerticalSizedBox(),
                ...bloc.commands.map((e) => CustomText("• ${e.command} - ${e.description}", fontSize: 20, textAlign: TextAlign.start,)).toList(),
              ],
            ),
          );
        });
  }
}
