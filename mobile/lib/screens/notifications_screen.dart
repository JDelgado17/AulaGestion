import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_session.dart';
import '../core/app_theme.dart';
import '../repositories/school_repository.dart';
import '../widgets/common_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen(
      {required this.repository, this.reloadHandle, super.key});

  final SchoolRepository repository;
  final ReloadHandle? reloadHandle;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>>? _items;
  Object? _error;
  int? _markingId;

  bool get _hasUnread =>
      _items?.any((item) => item['read_at'] == null) ?? false;

  @override
  void initState() {
    super.initState();
    widget.reloadHandle?.reload = _load;
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await widget.repository.notifications();
      if (mounted) {
        setState(() {
          _items = items;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _markAll() async {
    try {
      await widget.repository.markAllNotificationsRead();
      await _load();
      if (mounted) {
        showMessage(context, 'Todas quedaron marcadas como leídas.');
      }
    } catch (error) {
      if (mounted) showMessage(context, formatApiError(error), error: true);
    }
  }

  Future<void> _markRead(int id) async {
    setState(() => _markingId = id);
    try {
      await widget.repository.markNotificationRead(id);
      await _load();
    } catch (error) {
      if (mounted) showMessage(context, formatApiError(error), error: true);
    } finally {
      if (mounted) setState(() => _markingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _items == null) {
      return StateMessage(
          icon: Icons.cloud_off_rounded,
          title: 'Sin conexión',
          message: formatApiError(_error!),
          onAction: _load);
    }
    final attention =
        _items?.where((item) => _alertState(item) == 'active').toList() ??
            const [];
    final history =
        _items?.where((item) => _alertState(item) != 'active').toList() ??
            const [];
    final role = AppScope.of(context).user!.role;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          SectionHeader(
            title: 'Alertas',
            subtitle: switch (role) {
              'inventory' => 'Novedades del inventario a tu cargo',
              'admin' => 'Tus reservas y los avisos del sistema',
              _ => 'Cambios y recordatorios de tus reservas',
            },
            action: LoadingButton(
                kind: LoadingButtonKind.text,
                label: 'Marcar como leídas',
                icon: Icons.done_all_rounded,
                onPressed: _hasUnread ? _markAll : null),
          ),
          const SizedBox(height: 18),
          if (_items == null)
            const SizedBox(
                height: 260, child: Center(child: CircularProgressIndicator()))
          else if (_items!.isEmpty)
            const StateMessage(
                icon: Icons.notifications_none_rounded,
                title: 'Todo al día',
                message:
                    'Cuando algo cambie en tus reservas, te avisamos aquí.')
          else ...[
            if (attention.isNotEmpty) ...[
              _groupTitle('Requieren tu atención'),
              ...attention.map(_itemCard),
              const SizedBox(height: 10),
              _groupTitle('Historial'),
            ],
            ...history.map(_itemCard),
          ],
        ],
      ),
    );
  }

  Widget _groupTitle(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium));

  Widget _itemCard(Map<String, dynamic> item) {
    final id = item['id'] as int;
    final unread = item['read_at'] == null;
    final activeAlert = _alertState(item) == 'active';
    final color = activeAlert
        ? AppColors.danger
        : unread
            ? AppColors.blue
            : AppColors.muted;
    final created =
        DateTime.tryParse(item['created_at']?.toString() ?? '')?.toLocal();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: unread && _markingId == null ? () => _markRead(id) : null,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (!context.hasLargeText) ...[
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(14)),
                  child: _markingId == id
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(_icon(item['type']?.toString()), color: color),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(item['title']?.toString() ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(item['message']?.toString() ?? '',
                        style: const TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 8),
                    Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _statePill(item, unread),
                          if (created != null)
                            Text(
                                DateFormat('d MMM · h:mm a', 'es')
                                    .format(created),
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.muted)),
                          if (_markingId == id && context.hasLargeText)
                            const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                        ]),
                  ])),
            ]),
          ),
        ),
      ),
    );
  }

  String? _alertState(Map<String, dynamic> item) {
    final metadata = item['metadata'];
    return metadata is Map ? metadata['alert_state']?.toString() : null;
  }

  Widget _statePill(Map<String, dynamic> item, bool unread) =>
      switch (_alertState(item)) {
        'active' =>
          const StatusPill(status: 'out_of_service', label: 'Alerta activa'),
        'resolved' => const StatusPill(status: 'available', label: 'Resuelta'),
        _ => unread
            ? const StatusPill(status: 'completed', label: 'Nuevo')
            : const StatusPill(status: 'cancelled', label: 'Leído'),
      };

  IconData _icon(String? type) => switch (type) {
        'reservation_confirmed' => Icons.event_available_rounded,
        'reservation_cancelled' => Icons.event_busy_rounded,
        'classroom_unavailable' => Icons.warning_amber_rounded,
        'classroom_restored' => Icons.meeting_room_outlined,
        'reservation_reminder' => Icons.alarm_rounded,
        'inventory_alert' => Icons.inventory_2_outlined,
        _ => Icons.info_outline_rounded,
      };
}
