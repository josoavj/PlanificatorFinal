import 'package:flutter/material.dart';
import 'package:planificator/services/logging_service.dart';

class LogViewerDialog extends StatefulWidget {
  final bool isDialog;

  const LogViewerDialog({super.key, this.isDialog = true});

  @override
  State<LogViewerDialog> createState() => _LogViewerDialogState();
}

class _LogViewerDialogState extends State<LogViewerDialog> {
  final ScrollController _scrollController = ScrollController();
  late Stream<LogEntry> _logStream;
  LogLevel _filterLevel = LogLevel.debug;
  String _filterSource = '';
  String _searchQuery = '';
  final TextEditingController _filterCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _logStream = log.logStream;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _filterCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  String _getLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🐛';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.critical:
        return '🔴';
    }
  }

  Color _getMessageColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.white70;
      case LogLevel.warning:
        return Colors.amber[300] ?? Colors.amber;
      case LogLevel.error:
      case LogLevel.critical:
        return Colors.red[300] ?? Colors.red;
    }
  }

  Color _getLogBackgroundColor(LogLevel level) {
    switch (level) {
      case LogLevel.error:
      case LogLevel.critical:
        return Colors.red.withOpacity(0.05);
      case LogLevel.warning:
        return Colors.amber.withOpacity(0.05);
      case LogLevel.debug:
        return (Colors.grey[900] ?? Colors.grey[850])!;
      case LogLevel.info:
        return (Colors.grey[850] ?? Colors.grey[800])!;
    }
  }

  Widget _buildLevelBadge(LogLevel level) {
    final color = _getLevelColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        level.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Effacer tous les logs en mémoire?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              log.clear();
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
  }

  void _exportLogs() {
    log.exportLogs(minLevel: _filterLevel);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${log.allLogs.length} logs copiés'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _exportToFile() async {
    try {
      final logsDir = await log.getLogsDirectory();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📁 Logs: $logsDir'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  List<LogEntry> _getFilteredLogs() {
    var results = log.allLogs.where((entry) {
      final levelMatch = entry.level.index >= _filterLevel.index;
      final sourceMatch =
          _filterSource.isEmpty ||
          (entry.source?.toLowerCase().contains(_filterSource.toLowerCase()) ??
              false);
      final searchMatch =
          _searchQuery.isEmpty ||
          entry.message.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (entry.source?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);
      return levelMatch && sourceMatch && searchMatch;
    }).toList();

    return results;
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
                    message: 'Exporter logs',
                    child: IconButton(
                      icon: const Icon(Icons.download, size: 18),
                      onPressed: _exportToFile,
                      color: Colors.white70,
                    ),
                  ),
                  Tooltip(
                    message: 'Copier (presse-papiers)',
                    child: IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: _exportLogs,
                      color: Colors.white70,
                    ),
                  ),
                  Tooltip(
                    message: 'Résumé',
                    child: IconButton(
                      icon: const Icon(Icons.info, size: 18),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(log.getSummary()),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
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
              // Filtres et recherche
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
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _filterCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Source...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        setState(() => _filterSource = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Recherche...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        setState(() => _searchQuery = val);
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
                    margin: const EdgeInsets.symmetric(
                      vertical: 2,
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getLogBackgroundColor(entry.level),
                      border: Border(
                        left: BorderSide(
                          color: _getLevelColor(entry.level),
                          width: 3,
                        ),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tête: Numéro, Temps, Niveau
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Numéro et Temps
                            Expanded(
                              child: Row(
                                children: [
                                  // Numéro du log
                                  Container(
                                    width: 30,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.grey[800] ?? Colors.grey[700],
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Temps
                                  Text(
                                    entry.formattedTime,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Niveau avec icône
                            _buildLevelBadge(entry.level),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Source et Message dans Row pour compacité
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icône selon le niveau
                            SizedBox(
                              width: 24,
                              child: Text(
                                _getLevelIcon(entry.level),
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Source et Message
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Source
                                  if (entry.source?.isNotEmpty ?? false)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        entry.source ?? '',
                                        style: const TextStyle(
                                          color: Colors.lightBlue,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                  if (entry.source != null)
                                    const SizedBox(height: 4),
                                  // Message
                                  Text(
                                    entry.message,
                                    style: TextStyle(
                                      color: _getMessageColor(entry.level),
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                      height: 1.4,
                                    ),
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // StackTrace si présent (affiché sous avec indentation)
                        if (entry.stackTrace != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, left: 30),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                (entry.stackTrace?.toString() ??
                                        '(empty trace)')
                                    .split('\n')
                                    .first,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
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
      return Dialog(
        backgroundColor: Colors.grey[950] ?? Colors.black,
        child: content,
      );
    } else {
      return Scaffold(
        backgroundColor: Colors.grey[950],
        appBar: AppBar(
          title: const Text('Log Viewer'),
          backgroundColor: Colors.grey[900] ?? Colors.grey[800],
        ),
        body: content,
      );
    }
  }
}
