import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_session.dart';
import '../core/app_theme.dart';
import '../models/domain_models.dart';
import '../repositories/school_repository.dart';
import '../widgets/common_widgets.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({required this.repository, super.key});
  final SchoolRepository repository;

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  List<Reservation>? _reservations;
  Object? _error;
  String _status = 'all';
  bool _calendarView = false;
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await widget.repository
          .reservations(status: _status == 'all' ? null : _status);
      if (mounted) {
        setState(() {
          _reservations = items;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  List<Reservation> get _visible {
    final items = _reservations ?? [];
    if (!_calendarView) return items;
    return items
        .where((item) => DateUtils.isSameDay(item.startsAt, _selectedDay))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = AppScope.of(context).user!.role == 'admin';
    return Scaffold(
      appBar: AppBar(
          title: AppBarTitle(
              isAdmin ? 'Reservas institucionales' : 'Mis reservas'),
          actions: [
            IconButton(
                tooltip: _calendarView ? 'Ver lista' : 'Ver calendario',
                onPressed: () => setState(() => _calendarView = !_calendarView),
                icon: Icon(_calendarView
                    ? Icons.view_agenda_outlined
                    : Icons.calendar_month_outlined))
          ]),
      body: PageBody(
        child: Column(children: [
          if (_calendarView) ...[_weekSelector(), const SizedBox(height: 14)],
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              for (final filter in const {
                'all': 'Todas',
                'confirmed': 'Confirmadas',
                'cancelled': 'Canceladas',
                'completed': 'Finalizadas',
              }.entries)
                ChoiceChip(
                  label: Text(filter.value),
                  selected: _status == filter.key,
                  showCheckmark: false,
                  onSelected: (_) {
                    setState(() {
                      _status = filter.key;
                      _reservations = null;
                    });
                    _load();
                  },
                ),
            ]),
          ),
          const SizedBox(height: 18),
          Expanded(child: _content(isAdmin)),
        ]),
      ),
    );
  }

  Widget _weekSelector() {
    final start =
        _selectedDay.subtract(Duration(days: _selectedDay.weekday - 1));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Row(children: [
            IconButton(
                onPressed: () => setState(() => _selectedDay =
                    _selectedDay.subtract(const Duration(days: 7))),
                icon: const Icon(Icons.chevron_left_rounded)),
            Expanded(
                child: Text(DateFormat('MMMM y', 'es').format(_selectedDay),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w800))),
            IconButton(
                onPressed: () => setState(() =>
                    _selectedDay = _selectedDay.add(const Duration(days: 7))),
                icon: const Icon(Icons.chevron_right_rounded))
          ]),
          const SizedBox(height: 6),
          Row(
              children: List.generate(7, (index) {
            final day = start.add(Duration(days: index));
            final selected = DateUtils.isSameDay(day, _selectedDay);
            final hasReservation = (_reservations ?? []).any((item) =>
                DateUtils.isSameDay(item.startsAt, day) &&
                item.status == 'confirmed');
            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _selectedDay = day),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                      color: selected ? AppColors.blue : Colors.transparent,
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                          DateFormat('E', 'es')
                              .format(day)
                              .substring(0, 1)
                              .toUpperCase(),
                          style: TextStyle(
                              fontSize: 11,
                              color:
                                  selected ? Colors.white70 : AppColors.muted)),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('${day.day}',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: selected ? Colors.white : AppColors.text)),
                    ),
                    const SizedBox(height: 5),
                    CircleAvatar(
                        radius: 3,
                        backgroundColor: hasReservation
                            ? (selected ? Colors.white : AppColors.teal)
                            : Colors.transparent)
                  ]),
                ),
              ),
            );
          })),
        ]),
      ),
    );
  }

  Widget _content(bool isAdmin) {
    if (_error != null && _reservations == null) {
      return StateMessage(
          icon: Icons.cloud_off_rounded,
          title: 'No pudimos cargar las reservas',
          message: formatApiError(_error!),
          onAction: _load);
    }
    if (_reservations == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_visible.isEmpty) {
      return StateMessage(
          icon: Icons.event_busy_outlined,
          title: _calendarView ? 'Sin reservas este día' : 'No hay reservas',
          message: _calendarView
              ? 'Selecciona otro día del calendario.'
              : 'Las reservas aparecerán aquí cuando sean creadas.');
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _visible.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            _reservationCard(_visible[index], isAdmin),
      ),
    );
  }

  Widget _reservationCard(Reservation item, bool isAdmin) {
    final date = DateFormat('EEEE, d MMMM y', 'es').format(item.startsAt);
    final time =
        '${DateFormat('h:mm a').format(item.startsAt)} – ${DateFormat('h:mm a').format(item.endsAt)}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              '${item.classroom?.code ?? 'Aula'} · ${item.classroom?.name ?? ''}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          item.availabilityIssue == null
              ? StatusPill(status: item.status)
              : const StatusPill(
                  status: 'out_of_service', label: 'Aula no disponible'),
          const SizedBox(height: 12),
          if (item.availabilityIssue != null) ...[
            ErrorBanner(
                'Esta reserva ya no se puede usar: ${item.availabilityIssue}. Cancélala o busca otra aula.',
                icon: Icons.warning_amber_rounded),
            const SizedBox(height: 12),
          ],
          _line(Icons.calendar_today_outlined, date),
          _line(Icons.schedule_rounded, time),
          _line(Icons.groups_2_outlined,
              '${item.attendees} asistentes · ${item.activityType}'),
          _line(Icons.notes_rounded, item.purpose),
          if (isAdmin && item.user != null)
            _line(Icons.person_outline_rounded, item.user!.name),
          if (item.status == 'cancelled' && item.cancellationReason != null)
            _line(Icons.info_outline_rounded, item.cancellationReason!),
          if (item.status == 'confirmed' &&
              item.startsAt.isAfter(DateTime.now())) ...[
            const Divider(height: 28),
            Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                    onPressed: () => _cancel(item),
                    icon: const Icon(Icons.event_busy_outlined),
                    label: const Text('Cancelar reserva'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.danger))),
          ],
        ]),
      ),
    );
  }

  Widget _line(IconData icon, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: AppColors.muted),
        const SizedBox(width: 9),
        Expanded(
            child: Text(value, style: const TextStyle(color: AppColors.muted)))
      ]));

  Future<void> _cancel(Reservation item) async {
    final controller = TextEditingController();
    final cancelled = await showDialog<bool>(
        context: context,
        builder: (_) => AsyncFormDialog(
            title: 'Cancelar reserva',
            cancelLabel: 'Volver',
            submitLabel: 'Confirmar cancelación',
            content: TextField(
                controller: controller,
                autofocus: true,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Motivo de cancelación',
                    hintText: 'Escribe al menos 5 caracteres',
                    alignLabelWithHint: true)),
            onSubmit: () async {
              final reason = controller.text.trim();
              if (reason.length < 5) {
                throw const FormMessage(
                    'Escribe un motivo de al menos 5 caracteres.');
              }
              await widget.repository.cancelReservation(item.id, reason);
              await _load();
              return true;
            }));
    controller.dispose();
    if (cancelled == true && mounted) {
      showMessage(context, 'Reserva cancelada. El horario quedó libre.');
    }
  }
}
