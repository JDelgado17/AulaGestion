import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
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
  final _attendees = TextEditingController(text: '25');
  final _activity = TextEditingController(text: 'Clase');
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _start = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 10, minute: 0);
  final Set<String> _required = {'Videobeam'};
  final Set<String> _optional = {'Televisor'};
  bool _loading = false;

  static const resources = ['Videobeam', 'Televisor', 'Computador', 'Parlantes', 'Aire acondicionado', 'Tablero acrílico', 'Microscopio'];

  @override
  void dispose() {
    _attendees.dispose();
    _activity.dispose();
    super.dispose();
  }

  Future<void> _searchRooms() async {
    if (!_formKey.currentState!.validate()) return;
    final startsAt = DateTime(_date.year, _date.month, _date.day, _start.hour, _start.minute);
    final endsAt = DateTime(_date.year, _date.month, _date.day, _end.hour, _end.minute);
    if (!endsAt.isAfter(startsAt)) {
      showMessage(context, 'La hora final debe ser posterior a la hora inicial.', error: true);
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
      'activity_type': _activity.text.trim(),
      'required_resources': _required.toList(),
      'optional_resources': _optional.toList(),
    };
    setState(() => _loading = true);
    try {
      final result = await widget.repository.recommendations(criteria);
      if (mounted) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => RecommendationResultsScreen(repository: widget.repository, criteria: criteria, result: result)));
      }
    } catch (error) {
      if (mounted) showMessage(context, formatApiError(error), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Buscar aula')),
        body: PageBody(
          child: Form(
            key: _formKey,
            child: ListView(children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.navy, AppColors.blue]), borderRadius: BorderRadius.circular(22)),
                child: const Row(children: [
                  Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 34),
                  SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Recomendación inteligente', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)), SizedBox(height: 4), Text('La decisión se explica con reglas verificables de capacidad, horario e inventario.', style: TextStyle(color: Colors.white70))])),
                ]),
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: '1. Fecha y franja', subtitle: 'Elige cuándo necesitas el espacio'),
              const SizedBox(height: 12),
              _pickerTile(Icons.calendar_today_outlined, 'Fecha', DateFormat('EEEE, d MMMM y', 'es').format(_date), _pickDate),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _pickerTile(Icons.schedule_rounded, 'Inicio', _start.format(context), () => _pickTime(true))),
                const SizedBox(width: 10),
                Expanded(child: _pickerTile(Icons.schedule_rounded, 'Final', _end.format(context), () => _pickTime(false))),
              ]),
              const SizedBox(height: 24),
              const SectionHeader(title: '2. Actividad', subtitle: 'Indica el grupo y el propósito académico'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextFormField(controller: _attendees, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Estudiantes', prefixIcon: Icon(Icons.groups_2_outlined)), validator: (value) { final number = int.tryParse(value ?? ''); return number == null || number < 1 ? 'Cantidad inválida' : null; })),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: TextFormField(controller: _activity, decoration: const InputDecoration(labelText: 'Tipo de actividad', prefixIcon: Icon(Icons.school_outlined)), validator: (value) => (value?.trim().isEmpty ?? true) ? 'Campo obligatorio' : null)),
              ]),
              const SizedBox(height: 24),
              const SectionHeader(title: '3. Recursos', subtitle: 'Los obligatorios filtran; los opcionales mejoran la puntuación'),
              const SizedBox(height: 14),
              Text('Obligatorios', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: resources.map((resource) => FilterChip(selected: _required.contains(resource), label: Text(resource), avatar: _required.contains(resource) ? const Icon(Icons.check_rounded, size: 18) : null, onSelected: (selected) => setState(() { if (selected) { _required.add(resource); _optional.remove(resource); } else { _required.remove(resource); } }))).toList()),
              const SizedBox(height: 18),
              Text('Opcionales', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: resources.map((resource) => FilterChip(selected: _optional.contains(resource), label: Text(resource), onSelected: _required.contains(resource) ? null : (selected) => setState(() { selected ? _optional.add(resource) : _optional.remove(resource); }))).toList()),
              const SizedBox(height: 28),
              FilledButton.icon(onPressed: _loading ? null : _searchRooms, icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.search_rounded), label: Text(_loading ? 'Analizando aulas…' : 'Buscar mejores aulas')),
            ]),
          ),
        ),
      );

  Widget _pickerTile(IconData icon, String label, String value, VoidCallback onTap) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [Icon(icon, color: AppColors.blue), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)), const SizedBox(height: 2), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))])), const Icon(Icons.expand_more_rounded)])),
        ),
      );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(bool start) async {
    final picked = await showTimePicker(context: context, initialTime: start ? _start : _end);
    if (picked != null) setState(() => start ? _start = picked : _end = picked);
  }
}

class RecommendationResultsScreen extends StatelessWidget {
  const RecommendationResultsScreen({required this.repository, required this.criteria, required this.result, super.key});

  final SchoolRepository repository;
  final Map<String, dynamic> criteria;
  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final exact = _parse(result['recommendations']);
    final alternatives = _parse(result['alternatives']);
    final items = exact.isNotEmpty ? exact : alternatives;
    final alternativeTimes = (result['alternative_times'] as List? ?? []).whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Aulas recomendadas')),
      body: PageBody(
        child: ListView(children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: (exact.isNotEmpty ? AppColors.success : AppColors.warning).withValues(alpha: .09), borderRadius: BorderRadius.circular(18)),
            child: Row(children: [
              Icon(exact.isNotEmpty ? Icons.check_circle_outline_rounded : Icons.lightbulb_outline_rounded, color: exact.isNotEmpty ? AppColors.success : AppColors.warning),
              const SizedBox(width: 12),
              Expanded(child: Text(exact.isNotEmpty ? '${exact.length} aula(s) cumplen todos tus criterios.' : 'No hay coincidencia exacta. Estas son las opciones más cercanas.', style: const TextStyle(fontWeight: FontWeight.w700))),
            ]),
          ),
          const SizedBox(height: 20),
          if (items.isEmpty)
            const StateMessage(icon: Icons.search_off_rounded, title: 'No hay aulas disponibles', message: 'Modifica la fecha, el horario, la cantidad de estudiantes o los recursos.')
          else
            ...items.asMap().entries.map((entry) => Padding(padding: const EdgeInsets.only(bottom: 14), child: _RecommendationCard(index: entry.key, recommendation: entry.value, canReserve: entry.value.isExactMatch, onReserve: () => _reserve(context, entry.value)))),
          if (alternativeTimes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const SectionHeader(title: 'Horarios alternativos', subtitle: 'Franjas verificadas con coincidencias exactas'),
            const SizedBox(height: 12),
            ...alternativeTimes.map((slot) {
              final start = DateTime.parse(slot['starts_at'].toString()).toLocal();
              final end = DateTime.parse(slot['ends_at'].toString()).toLocal();
              return Card(child: ListTile(leading: const CircleAvatar(backgroundColor: AppColors.sky, child: Icon(Icons.schedule_rounded, color: AppColors.blue)), title: Text(DateFormat('EEEE d MMMM', 'es').format(start), style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${DateFormat('h:mm a').format(start)} – ${DateFormat('h:mm a').format(end)}'), trailing: Text('${slot['available_rooms']} aulas')));
            }),
          ],
        ]),
      ),
    );
  }

  List<RoomRecommendation> _parse(dynamic value) => (value as List? ?? []).whereType<Map>().map((item) => RoomRecommendation.fromJson(Map<String, dynamic>.from(item))).toList();

  Future<void> _reserve(BuildContext context, RoomRecommendation recommendation) async {
    final purpose = await showDialog<String>(context: context, builder: (_) => const _PurposeDialog());
    if (purpose == null || !context.mounted) return;
    try {
      final reservation = await repository.createReservation({...criteria, 'classroom_id': recommendation.classroom.id, 'purpose': purpose});
      if (!context.mounted) return;
      await showDialog<void>(context: context, builder: (_) => AlertDialog(icon: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 52), title: const Text('¡Reserva confirmada!'), content: Text('${recommendation.classroom.code} quedó reservada. Código de reserva: #${reservation.id}.'), actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido'))]));
      if (context.mounted) Navigator.pop(context);
    } catch (error) {
      if (context.mounted) showMessage(context, formatApiError(error), error: true);
    }
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.index, required this.recommendation, required this.canReserve, required this.onReserve});
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
            CircleAvatar(backgroundColor: index == 0 ? AppColors.blue : AppColors.sky, foregroundColor: index == 0 ? Colors.white : AppColors.blue, child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.w900))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${room.code} · ${room.name}', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 5), Text('${room.location} · ${room.capacity} personas', style: const TextStyle(color: AppColors.muted))])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: AppColors.success.withValues(alpha: .1), borderRadius: BorderRadius.circular(12)), child: Text('${recommendation.matchPercent}%', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w900))),
          ]),
          const SizedBox(height: 16),
          ...recommendation.reasons.map((reason) => Padding(padding: const EdgeInsets.only(bottom: 7), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_rounded, color: AppColors.success, size: 18), const SizedBox(width: 8), Expanded(child: Text(reason))]))),
          if (recommendation.missingResources.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text('Faltan: ${recommendation.missingResources.join(', ')}', style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700))),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: canReserve ? onReserve : null, icon: const Icon(Icons.event_available_rounded), label: Text(canReserve ? 'Reservar esta aula' : 'Alternativa no exacta'))),
        ]),
      ),
    );
  }
}

class _PurposeDialog extends StatefulWidget {
  const _PurposeDialog();
  @override
  State<_PurposeDialog> createState() => _PurposeDialogState();
}

class _PurposeDialogState extends State<_PurposeDialog> {
  final _controller = TextEditingController();
  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Confirmar reserva'),
        content: TextField(controller: _controller, autofocus: true, maxLength: 255, maxLines: 3, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Motivo de la reserva', hintText: 'Ej. Taller de ciencias', alignLabelWithHint: true)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: _controller.text.trim().length < 5 ? null : () => Navigator.pop(context, _controller.text.trim()), child: const Text('Confirmar'))],
      );
}
