import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../repositories/index.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../utils/app_snackbars.dart';

class NotificationTimeDialog extends StatefulWidget {
  const NotificationTimeDialog({super.key});

  static void show(BuildContext context) {
    AppDialogs.showBlurDialog(
      context: context,
      builder: (ctx) => const NotificationTimeDialog(),
    );
  }

  @override
  State<NotificationTimeDialog> createState() => _NotificationTimeDialogState();
}

class _NotificationTimeDialogState extends State<NotificationTimeDialog> {
  late int hour;
  late int minute;

  @override
  void initState() {
    super.initState();
    final notifRepo = context.read<NotificationRepository>();
    hour = notifRepo.notificationHour;
    minute = notifRepo.notificationMinute;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configurer les notifications'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('À quelle heure voulez-vous être notifié des traitements du jour suivant ?', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimeColumn('Heure', hour, 23, (v) => setState(() => hour = v)),
                const SizedBox(width: 12),
                const Text(':', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                _buildTimeColumn('Minute', minute, 59, (v) => setState(() => minute = v)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(
          onPressed: () async {
            await context.read<NotificationRepository>().scheduleCustomNotification(title: 'Prochains Traitements', body: 'Rappel des traitements de demain', hour: hour, minute: minute);
            if (mounted) {
              AppSnackBars.showSuccess(context, 'Notification planifiée à ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
              Navigator.pop(context);
            }
          },
          child: const Text('Confirmer'),
        ),
      ],
    );
  }

  Widget _buildTimeColumn(String label, int value, int max, ValueChanged<int> onChanged) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 8),
        SizedBox(
          width: 70,
          child: TextField(
            textAlign: TextAlign.center, keyboardType: TextInputType.number,
            controller: TextEditingController(text: value.toString().padLeft(2, '0')),
            decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(vertical: 8), filled: true, fillColor: Colors.white),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            onChanged: (v) { final i = int.tryParse(v); if (i != null && i >= 0 && i <= max) onChanged(i); },
          ),
        ),
      ],
    );
  }
}
