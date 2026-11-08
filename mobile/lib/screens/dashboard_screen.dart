import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_session.dart';
import '../core/app_theme.dart';
import '../models/domain_models.dart';
import '../repositories/school_repository.dart';
import '../widgets/common_widgets.dart';
import 'inventory_screen.dart';
import 'reservations_screen.dart';
import 'search_flow.dart';

/// Inicio según el rol: el profesor ve primero su próxima reserva; el resumen
/// numérico queda para quienes administran.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen(
      {required this.repository,
      required this.onOpenModules,
      required this.onOpenAlerts,
      this.reloadHandle,
      super.key});

  final SchoolRepository repository;
  final VoidCallback onOpenModules;
  final VoidCallback onOpenAlerts;
  final ReloadHandle? reloadHandle;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  Object? _error;

  @override
  void initState() {
    super.initState();
    widget.reloadHandle?.reload = _load;
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.repository.dashboard();
      if (mounted) {
        setState(() {
          _data = data;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  void _open(Widget screen) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => screen))
      .then((_) => _load());

  List<Reservation> get _reservations =>
      (_data?['next_reservations'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Reservation.fromJson(Map<String, dynamic>.from(item)))
          .toList();

  @override
  Widget build(BuildContext context) {
    final user = AppScope.of(context).user!;
    if (_error != null && _data == null) {
      return StateMessage(
          icon: Icons.cloud_off_rounded,
          title: 'No pudimos cargar el inicio',
          message: formatApiError(_error!),
          onAction: _load);
    }
    final activeAlerts = (_data?['active_alerts'] as num?)?.toInt() ?? 0;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('Hola, ${user.name.split(' ').first}',
                style: Theme.of(context).textTheme.headlineMedium),
          ),
          const SizedBox(height: 4),
          Text(_welcome(user.role),
              style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 18),
          if (activeAlerts > 0) ...[
            _alertsBanner(activeAlerts),
            const SizedBox(height: 16),
          ],
          if (_data == null)
            const SizedBox(
                height: 220, child: Center(child: CircularProgressIndicator()))
          else
            ...switch (user.role) {
              'admin' => _adminHome(),
              'inventory' => _inventoryHome(),
              _ => _professorHome(),
            },
        ],
      ),
    );
  }

  Widget _alertsBanner(int count) => Material(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onOpenAlerts,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(
                      count == 1
                          ? 'Una reserva tuya tiene un problema. Toca para ver.'
                          : '$count reservas tuyas tienen problemas. Toca para ver.',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700))),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ]),
          ),
        ),
      );

  List<Widget> _professorHome() {
    final reservations = _reservations;
    return [
      if (reservations.isEmpty)
        _noReservations()
      else ...[
        const SectionHeader(title: 'Tu próxima reserva'),
        const SizedBox(height: 10),
        _nextReservation(reservations.first),
      ],
      const SizedBox(height: 16),
      _reserveButton(),
      if (reservations.length > 1) ...[
        const SizedBox(height: 26),
        const SectionHeader(title: 'Después'),
        const SizedBox(height: 10),
        ...reservations.skip(1).map(_laterReservation),
      ],
      if (reservations.isNotEmpty) ...[
        const SizedBox(height: 4),
        Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
                onPressed: () =>
                    _open(ReservationsScreen(repository: widget.repository)),
                icon: const Icon(Icons.calendar_month_outlined),
                label: const Text('Ver todas mis reservas'))),
      ],
    ];
  }

  Widget _reserveButton() => FilledButton.icon(
      onPressed: () => _open(SearchScreen(repository: widget.repository)),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Reservar un aula'));

  Widget _noReservations() => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                  color: AppColors.sky, shape: BoxShape.circle),
              child: const Icon(Icons.event_available_rounded,
                  color: AppColors.blue, size: 32),
            ),
            const SizedBox(height: 14),
            Text('No tienes reservas próximas',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            const Text(
                'Cuéntanos qué necesitas y te mostramos las aulas libres que mejor se ajustan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted)),
          ]),
        ),
      );

  Widget _nextReservation(Reservation item) {
    final room = item.classroom;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppColors.navy, AppColors.blue, AppColors.teal],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(99)),
          child: Text(_whenLabel(item),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .6)),
        ),
        const SizedBox(height: 12),
        Text('${room?.code ?? 'Aula'} · ${room?.name ?? ''}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        _heroLine(Icons.calendar_today_outlined,
            DateFormat('EEEE, d MMMM', 'es').format(item.startsAt)),
        _heroLine(Icons.schedule_rounded, _timeRange(item)),
        if ((room?.location ?? '').isNotEmpty)
          _heroLine(Icons.location_on_outlined, room!.location),
        _heroLine(Icons.notes_rounded, item.purpose),
        if (item.availabilityIssue != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.danger, size: 20),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(
                      'Ya no puedes usarla: ${item.availabilityIssue}. Cancélala o busca otra aula.',
                      style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600))),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _heroLine(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 9),
        Expanded(
            child: Text(text,
                style: TextStyle(color: Colors.white.withValues(alpha: .92)))),
      ]));

  Widget _laterReservation(Reservation item) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(
                  item.availabilityIssue == null
                      ? Icons.event_rounded
                      : Icons.warning_amber_rounded,
                  color: item.availabilityIssue == null
                      ? AppColors.blue
                      : AppColors.danger),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        '${item.classroom?.code ?? 'Aula'} · ${item.classroom?.name ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(
                        '${DateFormat('EEE d MMM', 'es').format(item.startsAt)} · ${_timeRange(item)}',
                        style: const TextStyle(color: AppColors.muted)),
                  ])),
            ]),
          ),
        ),
      );

  List<Widget> _inventoryHome() {
    final data = _data!;
    final toReview = (data['inventory_alerts'] as num?)?.toInt() ?? 0;
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                toReview == 0
                    ? 'Todo el inventario está en buen estado'
                    : toReview == 1
                        ? 'Hay 1 elemento por revisar'
                        : 'Hay $toReview elementos por revisar',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text('Dañados, en mantenimiento o fuera de servicio.',
                style: TextStyle(color: AppColors.muted)),
          ]),
        ),
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
          onPressed: () =>
              _open(InventoryScreen(repository: widget.repository)),
          icon: const Icon(Icons.inventory_2_outlined),
          label: const Text('Ver inventario')),
      const SizedBox(height: 10),
      OutlinedButton.icon(
          onPressed: () =>
              _open(InventoryEventsScreen(repository: widget.repository)),
          icon: const Icon(Icons.history_rounded),
          label: const Text('Ver novedades registradas')),
    ];
  }

  List<Widget> _adminHome() {
    final data = _data!;
    final reservations = _reservations;
    return [
      if (reservations.isNotEmpty) ...[
        const SectionHeader(title: 'Tu próxima reserva'),
        const SizedBox(height: 10),
        _nextReservation(reservations.first),
        const SizedBox(height: 24),
      ],
      const SectionHeader(
          title: 'Resumen de la institución',
          subtitle: 'Cómo están hoy las aulas y las reservas'),
      const SizedBox(height: 14),
      StatGrid(children: [
        StatCard(
            label: 'Aulas disponibles',
            value: '${data['classrooms_available'] ?? 0}',
            icon: Icons.meeting_room_outlined,
            color: AppColors.success),
        StatCard(
            label: 'Reservas próximas',
            value: '${data['upcoming_reservations'] ?? 0}',
            icon: Icons.event_available_rounded,
            color: AppColors.blue),
        StatCard(
            label: 'Elementos por revisar',
            value: '${data['inventory_alerts'] ?? 0}',
            icon: Icons.inventory_2_outlined,
            color: AppColors.warning),
        StatCard(
            label: 'Aulas con novedad',
            value: '${data['classrooms_attention'] ?? 0}',
            icon: Icons.report_gmailerrorred_rounded,
            color: AppColors.danger),
      ]),
      const SizedBox(height: 18),
      FilledButton.tonalIcon(
          onPressed: widget.onOpenModules,
          icon: const Icon(Icons.grid_view_rounded),
          label: const Text('Ir a los módulos')),
    ];
  }

  String _timeRange(Reservation item) =>
      '${DateFormat('h:mm a').format(item.startsAt)} – ${DateFormat('h:mm a').format(item.endsAt)}';

  String _whenLabel(Reservation item) {
    final now = DateTime.now();
    if (item.startsAt.isBefore(now)) return 'EN CURSO';
    final days = DateUtils.dateOnly(item.startsAt)
        .difference(DateUtils.dateOnly(now))
        .inDays;
    return switch (days) {
      0 => 'HOY',
      1 => 'MAÑANA',
      _ => 'EN $days DÍAS',
    };
  }

  String _welcome(String role) => switch (role) {
        'admin' => 'Así va la institución hoy.',
        'inventory' => 'Mantén al día los recursos de cada aula.',
        _ => 'Aquí tienes lo que viene en tus reservas.',
      };
}
