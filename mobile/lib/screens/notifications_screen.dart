import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../repositories/school_repository.dart';
import '../widgets/common_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({required this.repository, super.key});

  final SchoolRepository repository;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>>? _items;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await widget.repository.notifications();
      if (mounted) setState(() { _items = items; _error = null; });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _markAll() async {
    try {
      await widget.repository.markAllNotificationsRead();
      await _load();
      if (mounted) showMessage(context, 'Todas las notificaciones quedaron como leídas.');
    } catch (error) {
      if (mounted) showMessage(context, formatApiError(error), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _items == null) return StateMessage(icon: Icons.cloud_off_rounded, title: 'Sin conexión', message: formatApiError(_error!), onAction: _load);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          SectionHeader(
            title: 'Notificaciones',
            subtitle: 'Confirmaciones, cambios y alertas relevantes',
            action: TextButton.icon(onPressed: _items?.isNotEmpty == true ? _markAll : null, icon: const Icon(Icons.done_all_rounded), label: const Text('Leer todas')),
          ),
          const SizedBox(height: 18),
          if (_items == null)
            const SizedBox(height: 260, child: Center(child: CircularProgressIndicator()))
          else if (_items!.isEmpty)
            const StateMessage(icon: Icons.notifications_none_rounded, title: 'Todo al día', message: 'No tienes notificaciones pendientes.')
          else
            ..._items!.map((item) {
              final unread = item['read_at'] == null;
              final created = DateTime.tryParse(item['created_at']?.toString() ?? '')?.toLocal();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: unread ? () async { await widget.repository.markNotificationRead(item['id'] as int); await _load(); } : null,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(color: (unread ? AppColors.blue : AppColors.muted).withValues(alpha: .1), borderRadius: BorderRadius.circular(14)),
                          child: Icon(_icon(item['type']?.toString()), color: unread ? AppColors.blue : AppColors.muted),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [Expanded(child: Text(item['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w800))), if (unread) const CircleAvatar(radius: 4, backgroundColor: AppColors.blue)]),
                          const SizedBox(height: 6),
                          Text(item['message']?.toString() ?? '', style: const TextStyle(color: AppColors.muted)),
                          if (created != null) ...[const SizedBox(height: 8), Text(DateFormat('d MMM · h:mm a', 'es').format(created), style: const TextStyle(fontSize: 12, color: AppColors.muted))],
                        ])),
                      ]),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  IconData _icon(String? type) => switch (type) {
        'reservation_confirmed' => Icons.event_available_rounded,
        'reservation_cancelled' => Icons.event_busy_rounded,
        'inventory_alert' => Icons.inventory_2_outlined,
        _ => Icons.info_outline_rounded,
      };
}

