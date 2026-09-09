import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/domain_models.dart';
import '../repositories/school_repository.dart';
import '../widgets/common_widgets.dart';

class ClassroomsScreen extends StatefulWidget {
  const ClassroomsScreen(
      {required this.repository, this.managementMode = false, super.key});

  final SchoolRepository repository;
  final bool managementMode;

  @override
  State<ClassroomsScreen> createState() => _ClassroomsScreenState();
}

class _ClassroomsScreenState extends State<ClassroomsScreen> {
  final _search = TextEditingController();
  List<Classroom>? _rooms;
  Object? _error;
  String? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final rooms = await widget.repository
          .classrooms(search: _search.text, status: _status);
      if (mounted) {
        setState(() {
          _rooms = rooms;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(widget.managementMode ? 'Administrar aulas' : 'Aulas')),
        floatingActionButton: widget.managementMode
            ? FloatingActionButton.extended(
                onPressed: () => _edit(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nueva aula'))
            : null,
        body: PageBody(
          child: Column(children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _load(),
                  decoration: InputDecoration(
                      hintText: 'Buscar por código, nombre o ubicación',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _search.clear();
                                _load();
                              },
                              icon: const Icon(Icons.close_rounded))),
                ),
              ),
              const SizedBox(width: 10),
              PopupMenuButton<String?>(
                tooltip: 'Filtrar por estado',
                initialValue: _status,
                onSelected: (value) {
                  setState(() => _status = value);
                  _load();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: null, child: Text('Todos los estados')),
                  PopupMenuItem(value: 'available', child: Text('Disponibles')),
                  PopupMenuItem(
                      value: 'maintenance', child: Text('En mantenimiento')),
                  PopupMenuItem(
                      value: 'out_of_service',
                      child: Text('Fuera de servicio')),
                ],
                child: Container(
                    height: 56,
                    width: 56,
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
    if (_error != null && _rooms == null) {
      return StateMessage(
          icon: Icons.cloud_off_rounded,
          title: 'No pudimos consultar las aulas',
          message: formatApiError(_error!),
          onAction: _load);
    }
    if (_rooms == null) return const Center(child: CircularProgressIndicator());
    if (_rooms!.isEmpty) {
      return const StateMessage(
          icon: Icons.meeting_room_outlined,
          title: 'No encontramos aulas',
          message: 'Prueba con otro término o filtro.');
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 90),
        itemCount: _rooms!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _roomCard(_rooms![index]),
      ),
    );
  }

  Widget _roomCard(Classroom room) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showDetails(room),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: AppColors.sky,
                    borderRadius: BorderRadius.circular(16)),
                child: Text(room.code.split('-').first,
                    style: const TextStyle(
                        color: AppColors.blue, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      Expanded(
                          child: Text('${room.code} · ${room.name}',
                              style: Theme.of(context).textTheme.titleMedium)),
                      const SizedBox(width: 8),
                      StatusPill(status: room.status)
                    ]),
                    const SizedBox(height: 8),
                    Wrap(spacing: 14, runSpacing: 6, children: [
                      _meta(Icons.location_on_outlined, room.location),
                      _meta(
                          Icons.groups_2_outlined, '${room.capacity} personas'),
                      _meta(Icons.category_outlined, room.type),
                    ]),
                    if (widget.managementMode) ...[
                      const SizedBox(height: 14),
                      Row(children: [
                        TextButton.icon(
                            onPressed: () => _edit(room),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Editar')),
                        TextButton.icon(
                            onPressed: () => _disable(room),
                            icon: const Icon(Icons.block_rounded),
                            label: const Text('Deshabilitar'),
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.danger)),
                      ]),
                    ],
                  ])),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ]),
          ),
        ),
      );

  Widget _meta(IconData icon, String text) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 17, color: AppColors.muted),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: AppColors.muted, fontSize: 13))
      ]);

  Future<void> _showDetails(Classroom partial) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => FutureBuilder<Classroom>(
        future: widget.repository.classroom(partial.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
                height: 300, child: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasError) {
            return SizedBox(
                height: 300,
                child: StateMessage(
                    icon: Icons.error_outline_rounded,
                    title: 'No se pudo cargar el aula',
                    message: formatApiError(snapshot.error!)));
          }
          final room = snapshot.data!;
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: .82,
            maxChildSize: .95,
            builder: (_, controller) => ListView(
                controller: controller,
                padding: const EdgeInsets.all(24),
                children: [
                  Align(
                      child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                              color: const Color(0xFFD5DFE8),
                              borderRadius: BorderRadius.circular(99)))),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(
                        child: Text('${room.code} · ${room.name}',
                            style: Theme.of(context).textTheme.headlineMedium)),
                    StatusPill(status: room.status)
                  ]),
                  const SizedBox(height: 10),
                  Text(room.description ?? 'Sin descripción registrada.',
                      style: const TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 22),
                  Wrap(spacing: 12, runSpacing: 12, children: [
                    _detailTile(
                        Icons.location_on_outlined, 'Ubicación', room.location),
                    _detailTile(Icons.groups_2_outlined, 'Capacidad',
                        '${room.capacity} personas'),
                    _detailTile(Icons.category_outlined, 'Tipo', room.type),
                  ]),
                  const SizedBox(height: 24),
                  const SectionHeader(
                      title: 'Inventario disponible',
                      subtitle: 'Recursos registrados en el aula'),
                  const SizedBox(height: 12),
                  if (room.inventory.isEmpty)
                    const Text('No hay elementos registrados.',
                        style: TextStyle(color: AppColors.muted))
                  else
                    ...room.inventory.map((item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                              backgroundColor: AppColors.sky,
                              child: Icon(_inventoryIcon(item.category),
                                  color: AppColors.blue)),
                          title: Text(item.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                              '${item.availableQuantity} de ${item.quantity} disponibles · ${item.category}'),
                          trailing: StatusPill(status: item.status),
                        )),
                ]),
          );
        },
      ),
    );
  }

  Widget _detailTile(IconData icon, String label, String value) => Container(
        width: 210,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(icon, color: AppColors.blue),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 12)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w700))
              ]))
        ]),
      );

  IconData _inventoryIcon(String category) =>
      category.toLowerCase().contains('tecn')
          ? Icons.devices_other_rounded
          : category.toLowerCase().contains('mobili')
              ? Icons.chair_alt_outlined
              : Icons.inventory_2_outlined;

  Future<void> _edit([Classroom? room]) async {
    final result = await showDialog<Map<String, dynamic>>(
        context: context, builder: (_) => _ClassroomForm(room: room));
    if (result == null) return;
    try {
      await widget.repository.saveClassroom(result, id: room?.id);
      await _load();
      if (mounted) {
        showMessage(
            context,
            room == null
                ? 'Aula registrada correctamente.'
                : 'Aula actualizada correctamente.');
      }
    } catch (error) {
      if (mounted) showMessage(context, formatApiError(error), error: true);
    }
  }

  Future<void> _disable(Classroom room) async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
                title: const Text('Deshabilitar aula'),
                content: Text(
                    'El aula ${room.code} dejará de estar disponible, pero conservará su historial.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Deshabilitar'))
                ]));
    if (ok != true) return;
    try {
      await widget.repository.disableClassroom(room.id);
      await _load();
      if (mounted) showMessage(context, 'Aula deshabilitada correctamente.');
    } catch (error) {
      if (mounted) showMessage(context, formatApiError(error), error: true);
    }
  }
}

class _ClassroomForm extends StatefulWidget {
  const _ClassroomForm({this.room});
  final Classroom? room;

  @override
  State<_ClassroomForm> createState() => _ClassroomFormState();
}

class _ClassroomFormState extends State<_ClassroomForm> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _code =
      TextEditingController(text: widget.room?.code);
  late final TextEditingController _name =
      TextEditingController(text: widget.room?.name);
  late final TextEditingController _location =
      TextEditingController(text: widget.room?.location);
  late final TextEditingController _capacity =
      TextEditingController(text: widget.room?.capacity.toString());
  late final TextEditingController _type =
      TextEditingController(text: widget.room?.type);
  late final TextEditingController _description =
      TextEditingController(text: widget.room?.description);
  late String _status = widget.room?.status ?? 'available';

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.room == null ? 'Registrar aula' : 'Editar aula'),
        content: SizedBox(
          width: 520,
          child: Form(
            key: _key,
            child: SingleChildScrollView(
                child: Column(children: [
              Row(children: [
                Expanded(child: _field(_code, 'Código', Icons.tag_rounded)),
                const SizedBox(width: 10),
                Expanded(
                    flex: 2,
                    child: _field(_name, 'Nombre', Icons.meeting_room_outlined))
              ]),
              const SizedBox(height: 12),
              _field(_location, 'Ubicación', Icons.location_on_outlined),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _field(
                        _capacity, 'Capacidad', Icons.groups_2_outlined,
                        number: true)),
                const SizedBox(width: 10),
                Expanded(
                    child:
                        _field(_type, 'Tipo de aula', Icons.category_outlined))
              ]),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                      labelText: 'Estado',
                      prefixIcon: Icon(Icons.info_outline_rounded)),
                  items: const [
                    DropdownMenuItem(
                        value: 'available', child: Text('Disponible')),
                    DropdownMenuItem(
                        value: 'maintenance', child: Text('Mantenimiento')),
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
            ])),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(onPressed: _save, child: const Text('Guardar')),
        ],
      );

  Widget _field(TextEditingController controller, String label, IconData icon,
          {bool number = false}) =>
      TextFormField(
          controller: controller,
          keyboardType: number ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
          validator: (value) {
            if (value?.trim().isEmpty ?? true) return 'Campo obligatorio';
            if (number && (int.tryParse(value!) ?? 0) < 1) {
              return 'Número inválido';
            }
            return null;
          });

  void _save() {
    if (!_key.currentState!.validate()) return;
    Navigator.pop(context, {
      'code': _code.text.trim().toUpperCase(),
      'name': _name.text.trim(),
      'location': _location.text.trim(),
      'capacity': int.parse(_capacity.text),
      'type': _type.text.trim(),
      'description':
          _description.text.trim().isEmpty ? null : _description.text.trim(),
      'status': _status,
      'is_active': true,
    });
  }
}
