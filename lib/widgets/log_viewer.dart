import 'package:flutter/material.dart';
import 'package:planificator/services/logging_service.dart';

class LogViewerDialog extends StatefulWidget {
  final bool isDialog;

  const LogViewerDialog({Key? key, this.isDialog = true}) : super(key: key);

  @override
  State<LogViewerDialog> createState() => _LogViewerDialogState();
}

class _LogViewerDialogState extends State<LogViewerDialog> {
  final ScrollController _scrollController = ScrollController();
  late Stream<LogEntry> _logStream;
  LogLevel _filterLevel = LogLevel.debug;
  String _filterSource = '';
  final TextEditingController _filterCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _logStream = log.logStream;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _filterCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearLogs() {
    log.clear();
    setState(() {});
  }

  void _exportLogs() {
    log.exportLogs(minLevel: _filterLevel);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logs exportés (${log.allLogs.length} entrées)')),
    );
  }

  List<LogEntry> _getFilteredLogs() {
    return log.allLogs.where((entry) {
      final levelMatch = entry.level.index >= _filterLevel.index;
      final sourceMatch =
          _filterSource.isEmpty ||
          (entry.source?.toLowerCase().contains(_filterSource.toLowerCase()) ??
              false);
      return levelMatch && sourceMatch;
    }).toList();
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.cyan;
      case LogLevel.info:
        return Colors.green;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.critical:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _getFilteredLogs();

    final content = Column(
      children: [
        // Header avec filtres
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            border: Border(bottom: BorderSide(color: Colors.grey[700]!)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'LOGS (${filteredLogs.length}/${log.allLogs.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const Spacer(),
                  Tooltip(
                    message: 'Exporter les logs',
                    child: IconButton(
                      icon: const Icon(Icons.download, size: 18),
                      onPressed: _exportLogs,
                      color: Colors.white70,
                    ),
                  ),
                  Tooltip(
                    message: 'Effacer tous les logs',
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: _clearLogs,
                      color: Colors.white70,
                    ),
                  ),
                  if (widget.isDialog)
                    Tooltip(
                      message: 'Fermer',
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => Navigator.pop(context),
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Filtres
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<LogLevel>(
                      value: _filterLevel,
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: Colors.grey[800],
                      items: LogLevel.values
                          .map(
                            (level) => DropdownMenuItem(
                              value: level,
                              child: Text(level.name.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (level) {
                        if (level != null) {
                          setState(() => _filterLevel = level);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _filterCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Filtrer par source...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() => _filterSource = val);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Liste des logs
        Expanded(
          child: StreamBuilder<LogEntry>(
            stream: _logStream,
            builder: (context, snapshot) {
              return ListView.builder(
                controller: _scrollController,
                itemCount: filteredLogs.length,
                itemBuilder: (context, index) {
                  final entry = filteredLogs[index];
                  _scrollToBottom();

                  return Container(
                    color: index % 2 == 0 ? Colors.grey[950] : Colors.grey[900],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Temps
                            Text(
                              entry.formattedTime,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Niveau
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getLevelColor(
                                  entry.level,
                                ).withOpacity(0.2),
                                border: Border.all(
                                  color: _getLevelColor(entry.level),
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                entry.levelName,
                                style: TextStyle(
                                  color: _getLevelColor(entry.level),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Source
                            if (entry.source != null)
                              Text(
                                '[${entry.source}]',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        // Message
                        Text(
                          entry.message,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // StackTrace si présent
                        if (entry.stackTrace != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              entry.stackTrace.toString().split('\n').first,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );

    if (widget.isDialog) {
      return Dialog(backgroundColor: Colors.grey[950], child: content);
    } else {
      return Scaffold(
        backgroundColor: Colors.grey[950],
        appBar: AppBar(
          title: const Text('Log Viewer'),
          backgroundColor: Colors.grey[900],
        ),
        body: content,
      );
    }
  }
}
