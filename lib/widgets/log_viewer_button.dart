import 'package:flutter/material.dart';
import 'package:planificator/widgets/log_viewer.dart';

class LogViewerButton extends StatefulWidget {
  const LogViewerButton({super.key});

  @override
  State<LogViewerButton> createState() => _LogViewerButtonState();
}

class _LogViewerButtonState extends State<LogViewerButton> {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.9,
            child: const LogViewerDialog(),
          ),
        );
      },
      icon: const Icon(Icons.bug_report),
      label: const Text('Logs'),
      backgroundColor: Colors.deepPurple,
      tooltip: 'Afficher les logs en temps réel',
    );
  }
}
