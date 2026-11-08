import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../core/catalogs.dart';
import '../models/domain_models.dart';
import '../repositories/school_repository.dart';
import '../widgets/common_widgets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({required this.repository, super.key});

  final SchoolRepository repository;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _attendees = TextEditingController();
  String _activity = Catalogs.activities.first;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _start = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 10, minute: 0);
  final Set<String> _required = {};
  final Set<String> _optional = {};

  @override
  void dispose() {
    _attendees.dispose();
    super.dispose();
  }

  Future<void> _searchRooms() async {
    if (!_formKey.currentState!.validate()) return;
    final startsAt = DateTime(
        _date.year, _date.month, _date.day, _start.hour, _start.minute);
    final endsAt =
        DateTime(_date.year, _date.month, _date.day, _end.hour, _end.minute);
    if (!endsAt.isAfter(startsAt)) {
      showMessage(
          context, 'La hora final debe ser posterior a la hora inicial.',
          error: true);
      return;
    }
    if (startsAt.isBefore(DateTime.now())) {
      showMessage(context, 'Selecciona una fecha y hora futuras.', error: true);
      return;
    }

    final criteria = <String, dynamic>{
      'starts_at': startsAt.toIso8601String(),
      'ends_at': endsAt.toIso8601String(),
      'attendees': int.parse(_attendees.text),
      'activity_type': _activity,
      'required_resources': _required.toList(),
      'optional_resources': _optional.toList(),
    };
    try {
      final result = await widget.repository.recommendations(criteria);
      if (mounted) {
        unawaited(Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => RecommendationResultsScreen(
                    repository: widget.repository,
                    criteria: criteria,
                    result: result))));
      }
    } catch (error) {
      if (mounted) showMessage(context, formatApiError(error), error: true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const AppBarTitle('Buscar aula')),
        body: PageBody(
          child: Form(
            key: _formKey,
            child: ListView(children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.navy, AppColors.blue]),
                    borderRadius: BorderRadius.circular(22)),
                child: const Row(children: [
                  Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 34),
                  SizedBox(width: 16),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('Encuentra tu aula ideal',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800)),
                        SizedBox(height: 4),
                        Text(
                            'Dinos qué necesitas y te mostramos las aulas libres que mejor se ajustan, y por qué.',
                            style: TextStyle(color: Colors.white70))
                      ])),
                ]),
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                  title: '1. ¿Cuándo?',
                  subtitle: 'Fecha y horario en que necesitas el aula'),
              const SizedBox(height: 12),
              _pickerTile(Icons.calendar_today_outlined, 'Fecha',
                  DateFormat('EEEE, d MMMM y', 'es').format(_date), _pickDate),
              const SizedBox(height: 10),
              AdaptiveRow(children: [
                _pickerTile(Icons.schedule_rounded, 'Inicio',
                    _start.format(context), () => _pickTime(true)),
                _pickerTile(Icons.schedule_rounded, 'Final',
                    _end.format(context), () => _pickTime(false)),
              ]),
              const SizedBox(height: 24),
              const SectionHeader(
                  title: '2. ¿Para qué?',
                  subtitle: 'Con esto priorizamos las aulas más adecuadas'),
              const SizedBox(height: 12),
              AdaptiveRow(flex: const [
                1,
                2
              ], children: [
                TextFormField(
                    controller: _attendees,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Asistentes',
                        hintText: 'Ej.: 25',
                        helperText: 'Cuántas personas estarán en el aula.',
                        prefixIcon: Icon(Icons.groups_2_outlined)),
                    validator: (value) {
                      final number = int.tryParse(value ?? '');
                      return number == null || number < 1
                          ? 'Escribe cuántas personas asistirán'
                          : null;
                    }),
                AppDropdown<String>(
                    initialValue: _activity,
                    decoration: const InputDecoration(
                        labelText: 'Actividad',
                        prefixIcon: Icon(Icons.school_outlined)),
                    items: Catalogs.activities
                        .map((activity) => DropdownMenuItem(
                            value: activity, child: Text(activity)))
                        .toList(),
                    onChanged: (value) => setState(() => _activity = value!)),
              ]),
              const SizedBox(height: 24),
              const SectionHeader(
                  title: '3. ¿Qué necesitas en el aula?',
                  subtitle: 'Si no necesitas nada en especial, déjalo vacío'),
              const SizedBox(height: 14),
              Text('Indispensable',
                  style: Theme.of(context).textTheme.titleMedium),
              const Text('Solo verás aulas que lo tengan.',
                  style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 8),
              Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: Catalogs.searchableResources
                      .map((resource) => FilterChip(
                          selected: _required.contains(resource),
                          label: Text(resource),
                          avatar: _required.contains(resource)
                              ? const Icon(Icons.check_rounded, size: 18)
                              : null,
                          onSelected: (selected) => setState(() {
                                if (selected) {
                                  _required.add(resource);
                                  _optional.remove(resource);
                                } else {
                                  _required.remove(resource);
                                }
                              })))
                      .toList()),
              const SizedBox(height: 18),
              Text('Sería bueno tener',
                  style: Theme.of(context).textTheme.titleMedium),
              const Text('Las aulas que lo tengan aparecen primero.',
                  style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 8),
              Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: Catalogs.searchableResources
                      .map((resource) => FilterChip(
                          selected: _optional.contains(resource),
                          label: Text(resource),
                          onSelected: _required.contains(resource)
                              ? null
                              : (selected) => setState(() {
                                    selected
                                        ? _optional.add(resource)
                                        : _optional.remove(resource);
                                  })))
                      .toList()),
              const SizedBox(height: 28),
              LoadingButton(
                  label: 'Buscar aulas',
                  loadingLabel: 'Analizando aulas…',
                  icon: Icons.search_rounded,
                  onPressed: _searchRooms),
            ]),
          ),
        ),
      );

  Widget _pickerTile(
          IconData icon, String label, String value, VoidCallback onTap) =>
      Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Icon(icon, color: AppColors.blue),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(label,
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(value,
                          style: const TextStyle(fontWeight: FontWeight.w700))
                    ])),
                const Icon(Icons.expand_more_rounded)
              ])),
        ),
      );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
        context: context,
        initialDate: _date,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)));
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(bool start) async {
    final picked = await showTimePicker(
        context: context, initialTime: start ? _start : _end);
    if (picked != null) setState(() => start ? _start = picked : _end = picked);
  }
}

class RecommendationResultsScreen extends StatelessWidget {
  const RecommendationResultsScreen(
      {required this.repository,
      required this.criteria,
      required this.result,
      super.key});

  final SchoolRepository repository;
  final Map<String, dynamic> criteria;
  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final exact = _parse(result['recommendations']);
    final alternatives = _parse(result['alternatives']);
    final items = exact.isNotEmpty ? exact : alternatives;
    final alternativeTimes = (result['alternative_times'] as List? ?? [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const AppBarTitle('Aulas recomendadas')),
      body: PageBody(
        child: ListView(children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color:
                    (exact.isNotEmpty ? AppColors.success : AppColors.warning)
                        .withValues(alpha: .09),
                borderRadius: BorderRadius.circular(18)),
            child: Row(children: [
              Icon(
                  exact.isNotEmpty
                      ? Icons.check_circle_outline_rounded
                      : Icons.lightbulb_outline_rounded,
                  color:
                      exact.isNotEmpty ? AppColors.success : AppColors.warning),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(
                      exact.isNotEmpty
                          ? '${exact.length} aula(s) cumplen todos tus criterios.'
                          : 'No hay coincidencia exacta. Estas son las opciones más cercanas.',
                      style: const TextStyle(fontWeight: FontWeight.w700))),
            ]),
          ),
          const SizedBox(height: 20),
          if (items.isEmpty)
            const StateMessage(
                icon: Icons.search_off_rounded,
                title: 'No hay aulas disponibles',
                message:
                    'Prueba con otra fecha u horario, menos asistentes o menos recursos.')
          else
            ...items.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _RecommendationCard(
                    index: entry.key,
                    recommendation: entry.value,
                    canReserve: entry.value.isExactMatch,
                    onReserve: () => _reserve(context, entry.value)))),
          if (alternativeTimes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const SectionHeader(
                title: 'Otros horarios con aulas libres',
                subtitle: 'Cumplen todo lo que marcaste como indispensable'),
            const SizedBox(height: 12),
            ...alternativeTimes.map((slot) {
              final start =
                  DateTime.parse(slot['starts_at'].toString()).toLocal();
              final end = DateTime.parse(slot['ends_at'].toString()).toLocal();
              return Card(
                  child: ListTile(
                      leading: const CircleAvatar(
                          backgroundColor: AppColors.sky,
                          child: Icon(Icons.schedule_rounded,
                              color: AppColors.blue)),
                      title: Text(DateFormat('EEEE d MMMM', 'es').format(start),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                          '${DateFormat('h:mm a').format(start)} – ${DateFormat('h:mm a').format(end)} · ${slot['available_rooms']} aulas')));
            }),
          ],
        ]),
      ),
    );
  }

  List<RoomRecommendation> _parse(dynamic value) => (value as List? ?? [])
      .whereType<Map>()
      .map((item) =>
          RoomRecommendation.fromJson(Map<String, dynamic>.from(item)))
      .toList();

  Future<void> _reserve(
      BuildContext context, RoomRecommendation recommendation) async {
    Reservation? reservation;
    await showDialog<bool>(
        context: context,
        builder: (_) => _PurposeDialog(onConfirm: (purpose) async {
              reservation = await repository.createReservation({
                ...criteria,
                'classroom_id': recommendation.classroom.id,
                'purpose': purpose
              });
            }));
    if (reservation == null || !context.mounted) return;
    await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
                icon: const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 52),
                title: const Text('¡Reserva confirmada!'),
                content: Text(
                    '${recommendation.classroom.code} quedó reservada. Código de reserva: #${reservation!.id}.'),
                actions: [
                  FilledButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Entendido'))
                ]));
    if (context.mounted) Navigator.pop(context);
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard(
      {required this.index,
      required this.recommendation,
      required this.canReserve,
      required this.onReserve});
  final int index;
  final RoomRecommendation recommendation;
  final bool canReserve;
  final VoidCallback onReserve;

  @override
  Widget build(BuildContext context) {
    final room = recommendation.classroom;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
                backgroundColor: index == 0 ? AppColors.blue : AppColors.sky,
                foregroundColor: index == 0 ? Colors.white : AppColors.blue,
                child: Text('${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w900))),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('${room.code} · ${room.name}',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 5),
                  Text('${room.location} · ${room.capacity} personas',
                      style: const TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 8),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(12)),
                      child: Text('${recommendation.matchPercent}%',
                          style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w900))),
                ])),
          ]),
          const SizedBox(height: 16),
          ...recommendation.reasons.map((reason) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.check_rounded,
                    color: AppColors.success, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(reason))
              ]))),
          if (recommendation.missingResources.isNotEmpty)
            Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                    'Faltan: ${recommendation.missingResources.join(', ')}',
                    style: const TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w700))),
          const SizedBox(height: 16),
          SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                  onPressed: canReserve ? onReserve : null,
                  icon: const Icon(Icons.event_available_rounded),
                  label: Text(canReserve
                      ? 'Reservar esta aula'
                      : 'No tiene todo lo indispensable'))),
        ]),
      ),
    );
  }
}

class _PurposeDialog extends StatefulWidget {
  const _PurposeDialog({required this.onConfirm});
  final Future<void> Function(String purpose) onConfirm;
  @override
  State<_PurposeDialog> createState() => _PurposeDialogState();
}

class _PurposeDialogState extends State<_PurposeDialog> {
  final _controller = TextEditingController();
  @override
  Widget build(BuildContext context) => AsyncFormDialog(
        title: 'Confirmar reserva',
        submitLabel: 'Confirmar',
        onSubmit: _controller.text.trim().length < 5
            ? null
            : () async {
                await widget.onConfirm(_controller.text.trim());
                return true;
              },
        content: TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 255,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
                labelText: 'Motivo de la reserva',
                hintText: 'Ej. Taller de ciencias',
                alignLabelWithHint: true)),
      );
}
