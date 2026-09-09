import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_session.dart';
import '../core/app_theme.dart';
import '../models/domain_models.dart';
import '../repositories/school_repository.dart';
import '../widgets/common_widgets.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({required this.repository, super.key});
  final SchoolRepository repository;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<InventoryItem>? _items;
  List<Classroom>? _rooms;
  int? _roomId;
  String? _status;
  Object? _error;

  bool get _canEdit =>
      ['admin', 'inventory'].contains(AppScope.of(context).user!.role);

  @override
  void initState() {
    super.initState();
    _loadBase();
  }

  Future<void> _loadBase() async {
    try {
      final values = await Future.wait([
        widget.repository.classrooms(),
        widget.repository.inventory(classroomId: _roomId, status: _status)
      ]);
      if (mounted) {
        setState(() {
          _rooms = values[0] as List<Classroom>;
          _items = values[1] as List<InventoryItem>;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _loadItems() async {
    setState(() => _items = null);
    try {
      final items = await widget.repository
          .inventory(classroomId: _roomId, status: _status);
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

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Inventario de aulas')),
        floatingActionButton: _canEdit
            ? FloatingActionButton.extended(
                onPressed: () => _edit(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nuevo elemento'))
            : null,
        body: PageBody(
          child: Column(children: [
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: _roomId,
                  decoration: const InputDecoration(
                      labelText: 'Filtrar por aula',
                      prefixIcon: Icon(Icons.meeting_room_outlined)),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Todas las aulas')),
                    ...?_rooms?.map((room) => DropdownMenuItem(
                        value: room.id,
                        child: Text('${room.code} · ${room.name}',
                            overflow: TextOverflow.ellipsis)))
                  ],
                  onChanged: (value) {
                    setState(() => _roomId = value);
                    _loadItems();
                  },
                ),
              ),
              const SizedBox(width: 10),
              PopupMenuButton<String?>(
                tooltip: 'Estado',
                onSelected: (value) {
                  setState(() => _status = value);
                  _loadItems();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: null, child: Text('Todos')),
                  PopupMenuItem(value: 'available', child: Text('Disponibles')),
                  PopupMenuItem(
                      value: 'maintenance', child: Text('Mantenimiento')),
                  PopupMenuItem(value: 'damaged', child: Text('Averiados')),
                  PopupMenuItem(
                      value: 'out_of_service', child: Text('Fuera de servicio'))
                ],
                child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFD7E1EC)),
                        borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.filter_list_rounded)),
              ),
            ]),
            const SizedBox(height: 18),
            Expanded(child: _content()),
          ]),
        ),
      );

  Widget _content() {
    if (_error != null && _items == null) {
      return StateMessage(
          icon: Icons.cloud_off_rounded,
          title: 'No pudimos cargar el inventario',
          message: formatApiError(_error!),
          onAction: _loadBase);
    }
    if (_items == null) return const Center(child: CircularProgressIndicator());
    if (_items!.isEmpty) {
      return const StateMessage(
          icon: Icons.inventory_2_outlined,
          title: 'Sin elementos',
          message: 'No hay inventario para los filtros seleccionados.');
    }
    return RefreshIndicator(
      onRefresh: _loadBase,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 90),
        itemCount: _items!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) => _itemCard(_items![index]),
      ),
    );
  }

  Widget _itemCard(InventoryItem item) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: AppColors.sky,
                      borderRadius: BorderRadius.circular(14)),
                  child: Icon(_icon(item.category), color: AppColors.blue)),
              const SizedBox(width: 13),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(item.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('${item.classroom?['code'] ?? ''} · ${item.category}',
                        style: const TextStyle(color: AppColors.muted))
                  ])),
              StatusPill(status: item.status),
            ]),
            const SizedBox(height: 16),
            ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                    value: item.quantity == 0
                        ? 0
                        : item.availableQuantity / item.quantity,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE8EEF5),
                    color: item.availableQuantity == 0
                        ? AppColors.danger
                        : AppColors.success)),
            const SizedBox(height: 7),
            Text('${item.availableQuantity} disponibles de ${item.quantity}',
                style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            if (_canEdit) ...[
              const Divider(height: 26),
              Wrap(spacing: 8, children: [
                TextButton.icon(
                    onPressed: () => _edit(item),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar')),
                FilledButton.tonalIcon(
                    onPressed: () => _report(item),
                    icon: const Icon(Icons.add_alert_outlined),
                    label: const Text('Registrar novedad')),
              ]),
            ],
          ]),
        ),
      );

  IconData _icon(String category) => category.toLowerCase().contains('tecn')
      ? Icons.devices_other_rounded
      : category.toLowerCase().contains('mobili')
          ? Icons.chair_alt_outlined
          : category.toLowerCase().contains('segur')
              ? Icons.health_and_safety_outlined
              : Icons.inventory_2_outlined;

  Future<void> _edit([InventoryItem? item]) async {
    if (_rooms == null) return;
    final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) =>
            _InventoryForm(item: item, rooms: _rooms!, initialRoomId: _roomId));
    if (result == null) return;
    try {
      await widget.repository.saveInventory(result, id: item?.id);
      await _loadItems();
      if (mounted) {
        showMessage(context,
            item == null ? 'Elemento registrado.' : 'Inventario actualizado.');
      }
    } catch (error) {
      if (mounted) showMessage(context, formatApiError(error), error: true);
    }
  }

  Future<void> _report(InventoryItem item) async {
    final result = await showDialog<Map<String, dynamic>>(
        context: context, builder: (_) => _EventForm(item: item));
    if (result == null) return;
    try {
      await widget.repository.addInventoryEvent(item.id, result);
      await _loadItems();
      if (mounted) showMessage(context, 'Novedad registrada con trazabilidad.');
    } catch (error) {
      if (mounted) showMessage(context, formatApiError(error), error: true);
    }
  }
}

class _InventoryForm extends StatefulWidget {
  const _InventoryForm({required this.rooms, this.item, this.initialRoomId});
  final List<Classroom> rooms;
  final InventoryItem? item;
  final int? initialRoomId;

  @override
  State<_InventoryForm> createState() => _InventoryFormState();
}

class _InventoryFormState extends State<_InventoryForm> {
  final _key = GlobalKey<FormState>();
  late int? _roomId = widget.item?.classroomId ??
      widget.initialRoomId ??
      (widget.rooms.isNotEmpty ? widget.rooms.first.id : null);
  late final _name = TextEditingController(text: widget.item?.name);
  late final _category = TextEditingController(text: widget.item?.category);
  late final _quantity =
      TextEditingController(text: widget.item?.quantity.toString() ?? '1');
  late final _available = TextEditingController(
      text: widget.item?.availableQuantity.toString() ?? '1');
  late final _description =
      TextEditingController(text: widget.item?.description);
  late String _status = widget.item?.status ?? 'available';

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.item == null ? 'Nuevo elemento' : 'Editar elemento'),
        content: SizedBox(
            width: 520,
            child: Form(
                key: _key,
                child: SingleChildScrollView(
                    child: Column(children: [
                  DropdownButtonFormField<int>(
                      initialValue: _roomId,
                      decoration: const InputDecoration(
                          labelText: 'Aula',
                          prefixIcon: Icon(Icons.meeting_room_outlined)),
                      items: widget.rooms
                          .map((room) => DropdownMenuItem(
                              value: room.id,
                              child: Text('${room.code} · ${room.name}')))
                          .toList(),
                      onChanged: (value) => setState(() => _roomId = value)),
                  const SizedBox(height: 12),
                  _field(_name, 'Nombre del elemento'),
                  const SizedBox(height: 12),
                  _field(_category, 'Categoría'),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child:
                            _field(_quantity, 'Cantidad total', number: true)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _field(_available, 'Disponibles', number: true))
                  ]),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(labelText: 'Estado'),
                      items: const [
                        DropdownMenuItem(
                            value: 'available', child: Text('Disponible')),
                        DropdownMenuItem(
                            value: 'loaned', child: Text('En préstamo')),
                        DropdownMenuItem(
                            value: 'maintenance', child: Text('Mantenimiento')),
                        DropdownMenuItem(
                            value: 'damaged', child: Text('Averiado')),
                        DropdownMenuItem(
                            value: 'out_of_service',
                            child: Text('Fuera de servicio'))
                      ],
                      onChanged: (value) => setState(() => _status = value!)),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: _description,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          labelText: 'Descripción', alignLabelWithHint: true)),
                ])))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(onPressed: _save, child: const Text('Guardar'))
        ],
      );

  Widget _field(TextEditingController controller, String label,
          {bool number = false}) =>
      TextFormField(
          controller: controller,
          keyboardType: number ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(labelText: label),
          validator: (value) {
            if (value?.trim().isEmpty ?? true) return 'Campo obligatorio';
            if (number && int.tryParse(value!) == null) {
              return 'Número inválido';
            }
            return null;
          });

  void _save() {
    if (!_key.currentState!.validate() || _roomId == null) return;
    final total = int.parse(_quantity.text);
    final available = int.parse(_available.text);
    if (available > total || total < 0 || available < 0) {
      showMessage(context, 'Las cantidades no son válidas.', error: true);
      return;
    }
    Navigator.pop(context, {
      'classroom_id': _roomId,
      'name': _name.text.trim(),
      'category': _category.text.trim(),
      'quantity': total,
      'available_quantity': available,
      'status': _status,
      'description':
          _description.text.trim().isEmpty ? null : _description.text.trim()
    });
  }
}

class _EventForm extends StatefulWidget {
  const _EventForm({required this.item});
  final InventoryItem item;
  @override
  State<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<_EventForm> {
  final _description = TextEditingController();
  final _delta = TextEditingController(text: '0');
  String _type = 'damage';
  String _status = 'damaged';

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Novedad · ${widget.item.name}'),
        content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
                child: Column(children: [
              DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration:
                      const InputDecoration(labelText: 'Tipo de novedad'),
                  items: const [
                    DropdownMenuItem(value: 'damage', child: Text('Daño')),
                    DropdownMenuItem(value: 'missing', child: Text('Faltante')),
                    DropdownMenuItem(
                        value: 'transfer', child: Text('Traslado')),
                    DropdownMenuItem(
                        value: 'maintenance', child: Text('Mantenimiento')),
                    DropdownMenuItem(
                        value: 'recovery', child: Text('Recuperación')),
                    DropdownMenuItem(value: 'adjustment', child: Text('Ajuste'))
                  ],
                  onChanged: (value) => setState(() => _type = value!)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Nuevo estado'),
                  items: const [
                    DropdownMenuItem(
                        value: 'available', child: Text('Disponible')),
                    DropdownMenuItem(
                        value: 'loaned', child: Text('En préstamo')),
                    DropdownMenuItem(
                        value: 'maintenance', child: Text('Mantenimiento')),
                    DropdownMenuItem(value: 'damaged', child: Text('Averiado')),
                    DropdownMenuItem(
                        value: 'out_of_service',
                        child: Text('Fuera de servicio'))
                  ],
                  onChanged: (value) => setState(() => _status = value!)),
              const SizedBox(height: 12),
              TextField(
                  controller: _delta,
                  keyboardType:
                      const TextInputType.numberWithOptions(signed: true),
                  decoration: const InputDecoration(
                      labelText: 'Cambio en disponibles',
                      helperText: 'Ej.: -1 por daño, +1 por recuperación')),
              const SizedBox(height: 12),
              TextField(
                  controller: _description,
                  maxLines: 4,
                  decoration: const InputDecoration(
                      labelText: 'Descripción de la novedad',
                      alignLabelWithHint: true)),
            ]))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () {
                if (_description.text.trim().length < 5 ||
                    int.tryParse(_delta.text) == null) {
                  showMessage(
                      context, 'Completa una descripción y un ajuste válido.',
                      error: true);
                  return;
                }
                Navigator.pop(context, {
                  'type': _type,
                  'new_status': _status,
                  'quantity_delta': int.parse(_delta.text),
                  'description': _description.text.trim(),
                  'occurred_at': DateTime.now().toIso8601String()
                });
              },
              child: const Text('Registrar'))
        ],
      );
}

class InventoryEventsScreen extends StatefulWidget {
  const InventoryEventsScreen({required this.repository, super.key});
  final SchoolRepository repository;
  @override
  State<InventoryEventsScreen> createState() => _InventoryEventsScreenState();
}

class _InventoryEventsScreenState extends State<InventoryEventsScreen> {
  List<Map<String, dynamic>>? _events;
  Object? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await widget.repository.inventoryEvents();
      if (mounted) {
        setState(() {
          _events = items;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Historial de novedades')),
        body: PageBody(child: _content()),
      );

  Widget _content() {
    if (_error != null && _events == null) {
      return StateMessage(
          icon: Icons.cloud_off_rounded,
          title: 'No pudimos cargar el historial',
          message: formatApiError(_error!),
          onAction: _load);
    }
    if (_events == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_events!.isEmpty) {
      return const StateMessage(
          icon: Icons.history_rounded,
          title: 'Sin novedades',
          message: 'Los cambios de inventario aparecerán aquí.');
    }
    return RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
            itemCount: _events!.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final event = _events![index];
              final date =
                  DateTime.tryParse(event['occurred_at']?.toString() ?? '')
                      ?.toLocal();
              return Card(
                  child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                          backgroundColor:
                              AppColors.warning.withValues(alpha: .1),
                          child: const Icon(Icons.history_rounded,
                              color: AppColors.warning)),
                      title: Text(
                          event['item']?['name']?.toString() ?? 'Elemento',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                              '${_eventLabel(event['type']?.toString())} · ${event['description'] ?? ''}\n${event['classroom']?['code'] ?? ''} · ${event['user']?['name'] ?? ''}${date == null ? '' : ' · ${DateFormat('d MMM, h:mm a', 'es').format(date)}'}')),
                      isThreeLine: true));
            }));
  }

  String _eventLabel(String? value) =>
      const {
        'damage': 'Daño',
        'missing': 'Faltante',
        'transfer': 'Traslado',
        'maintenance': 'Mantenimiento',
        'recovery': 'Recuperación',
        'adjustment': 'Ajuste'
      }[value] ??
      value ??
      'Novedad';
}
