import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/catalogs.dart';
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
      final rooms = await widget.repository.classrooms(
          search: _search.text,
          status: _status,
          includeDisabled: widget.managementMode);
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

  /// Vacía la lista para que se vea el indicador de carga al filtrar o buscar.
  void _reload() {
    setState(() => _rooms = null);
    _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: AppBarTitle(
                widget.managementMode ? 'Administrar aulas' : 'Aulas'),
            actions: [
              PopupMenuButton<String?>(
                tooltip: 'Filtrar por estado',
                icon: const Icon(Icons.filter_list_rounded),
                initialValue: _status,
                onSelected: (value) {
                  _status = value;
                  _reload();
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
              ),
            ]),
        floatingActionButton: widget.managementMode
            ? FloatingActionButton.extended(
                onPressed: () => _edit(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nueva aula'))
            : null,
        body: PageBody(
          child: Column(children: [
            TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _reload(),
              decoration: InputDecoration(
                  labelText: 'Buscar aula',
                  hintText:
                      context.hasLargeText ? null : 'Código, nombre o lugar',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpiar búsqueda',
                          onPressed: () {
                            _search.clear();
                            _reload();
                          },
                          icon: const Icon(Icons.close_rounded))),
            ),
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
              if (!context.hasLargeText) ...[
                Container(
                  width: 54,
                  height: 54,
                  padding: const EdgeInsets.all(6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: AppColors.sky,
                      borderRadius: BorderRadius.circular(16)),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(room.code.split('-').first,
                        style: const TextStyle(
                            color: AppColors.blue,
                            fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('${room.code} · ${room.name}',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    _roomStatus(room),
                    const SizedBox(height: 8),
                    Wrap(spacing: 14, runSpacing: 6, children: [
                      _meta(Icons.location_on_outlined, room.location),
                      _meta(
                          Icons.groups_2_outlined, '${room.capacity} personas'),
                      _meta(Icons.category_outlined, room.type),
                    ]),
                    if (widget.managementMode) ...[
                      const SizedBox(height: 14),
                      Wrap(children: [
                        TextButton.icon(
                            onPressed: () => _edit(room),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Editar')),
                        if (room.isActive)
                          TextButton.icon(
                              onPressed: () => _disable(room),
                              icon: const Icon(Icons.block_rounded),
                              label: const Text('Deshabilitar'),
                              style: TextButton.styleFrom(
                                  foregroundColor: AppColors.danger))
                        else
                          LoadingButton(
                              kind: LoadingButtonKind.text,
                              label: 'Habilitar',
                              loadingLabel: 'Habilitando…',
                              icon: Icons.check_circle_outline_rounded,
                              onPressed: () => _enable(room)),
                      ]),
                    ],
                  ])),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ]),
          ),
        ),
      );

  Widget _roomStatus(Classroom room) =>
      StatusPill(status: room.isActive ? room.status : 'disabled');

  Widget _meta(IconData icon, String text) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 17, color: AppColors.muted),
        const SizedBox(width: 5),
        Flexible(
            child: Text(text,
                style: const TextStyle(color: AppColors.muted, fontSize: 13)))
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
                  Text('${room.code} · ${room.name}',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: _roomStatus(room)),
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
                          subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${item.availableQuantity} de ${item.quantity} disponibles · ${item.category}'),
                                const SizedBox(height: 6),
                                StatusPill(status: item.status),
                              ]),
                        )),
                ]),
          );
        },
      ),
    );
  }

  Widget _detailTile(IconData icon, String label, String value) => Container(
        width: context.hasLargeText ? double.infinity : 210,
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
    final saved = await showDialog<bool>(
        context: context,
        builder: (_) => _ClassroomForm(
            room: room,
            onSave: (data) async {
              await widget.repository.saveClassroom(data, id: room?.id);
              await _load();
            }));
    if (saved == true && mounted) {
      showMessage(
          context,
          room == null
              ? 'Aula registrada correctamente.'
              : 'Aula actualizada correctamente.');
    }
  }

  Future<void> _enable(Classroom room) async {
    try {
      await widget.repository.saveClassroom({
        'code': room.code,
        'name': room.name,
        'location': room.location,
        'capacity': room.capacity,
        'type': room.type,
        'description': room.description,
        'status': room.status,
        'is_active': true,
      }, id: room.id);
      await _load();
      if (mounted) showMessage(context, 'Aula habilitada correctamente.');
    } catch (error) {
      if (mounted) showMessage(context, formatApiError(error), error: true);
    }
  }

  Future<void> _disable(Classroom room) async {
    final done = await showDialog<bool>(
        context: context,
        builder: (_) => AsyncFormDialog(
            title: 'Deshabilitar aula',
            content: Text(
                'El aula ${room.code} dejará de estar disponible, pero conservará su historial. Quienes la tengan reservada recibirán una alerta.'),
            submitLabel: 'Deshabilitar',
            onSubmit: () async {
              await widget.repository.disableClassroom(room.id);
              await _load();
              return true;
            }));
    if (done == true && mounted) {
      showMessage(context, 'Aula deshabilitada correctamente.');
    }
  }
}

class _ClassroomForm extends StatefulWidget {
  const _ClassroomForm({required this.onSave, this.room});
  final Classroom? room;
  final Future<void> Function(Map<String, dynamic> data) onSave;

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
  late String? _type = widget.room?.type;
  late final TextEditingController _description =
      TextEditingController(text: widget.room?.description);
  late String _status = widget.room?.status ?? 'available';

  @override
  Widget build(BuildContext context) => AsyncFormDialog(
        title: widget.room == null ? 'Registrar aula' : 'Editar aula',
        submitLabel: 'Guardar',
        onSubmit: _save,
        content: Form(
            key: _key,
            child: Column(children: [
              _field(_code, 'Código', Icons.tag_rounded,
                  hint: 'Ej.: A-101',
                  helper:
                      'Bloque o sede, un guion y el número del aula. Es único y así la identifican todos.',
                  capitalize: TextCapitalization.characters,
                  validator: _validateCode),
              const SizedBox(height: 12),
              _field(_name, 'Nombre', Icons.meeting_room_outlined,
                  hint: 'Ej.: Sala de Informática',
                  helper: 'Cómo la conocen en el colegio.'),
              const SizedBox(height: 12),
              _field(_location, 'Ubicación', Icons.location_on_outlined,
                  hint: 'Ej.: Bloque A, piso 2',
                  helper:
                      'Dónde queda, para que cualquiera pueda encontrarla.'),
              const SizedBox(height: 12),
              _field(_capacity, 'Capacidad', Icons.groups_2_outlined,
                  number: true,
                  hint: 'Ej.: 30',
                  helper:
                      'Máximo de personas que caben. No se recomendará para grupos más grandes.'),
              const SizedBox(height: 12),
              AppDropdown<String>(
                  initialValue: _type,
                  decoration: InputDecoration(
                      labelText: 'Tipo de aula',
                      hintText: 'Elige una opción',
                      helperText:
                          'Sirve para recomendarla según la actividad de cada reserva.',
                      prefixIcon: context.hasLargeText
                          ? null
                          : const Icon(Icons.category_outlined)),
                  validator: (value) =>
                      value == null ? 'Elige el tipo de aula' : null,
                  selectedItemBuilder: (_) =>
                      _typeOptions.map((type) => Text(type)).toList(),
                  items: _typeOptions
                      .map((type) => DropdownMenuItem(
                          value: type,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(type,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  if (Catalogs.classroomTypes[type] != null)
                                    Text(Catalogs.classroomTypes[type]!,
                                        style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 12)),
                                ]),
                          )))
                      .toList(),
                  onChanged: (value) => setState(() => _type = value)),
              const SizedBox(height: 12),
              AppDropdown<String>(
                  initialValue: _status,
                  decoration: InputDecoration(
                      labelText: 'Estado',
                      helperText:
                          'Solo las aulas disponibles se pueden reservar.',
                      prefixIcon: context.hasLargeText
                          ? null
                          : const Icon(Icons.info_outline_rounded)),
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
                      labelText: 'Descripción (opcional)',
                      hintText: 'Ej.: Tiene mesas móviles y buena ventilación',
                      hintMaxLines: 4,
                      alignLabelWithHint: true)),
              if (widget.room == null) ...[
                const SizedBox(height: 12),
                const ErrorBanner(
                    'Quedará disponible de lunes a sábado, de 7:00 a. m. a 7:00 p. m. Puedes cambiarlo en Horarios y bloqueos.',
                    color: AppColors.blue,
                    icon: Icons.schedule_rounded),
              ],
            ])),
      );

  /// Un aula con un tipo antiguo debe poder editarse sin perder su valor.
  List<String> get _typeOptions => [
        ...Catalogs.classroomTypes.keys,
        if (_type != null && !Catalogs.classroomTypes.containsKey(_type))
          _type!,
      ];

  String? _validateCode(String? value) {
    final code = value?.trim().toUpperCase() ?? '';
    if (code.isEmpty) return 'Campo obligatorio';
    return RegExp(r'^[A-Z0-9]+-[A-Z0-9]+$').hasMatch(code)
        ? null
        : 'Usa letras o números, un guion y el número. Ej.: A-101';
  }

  Widget _field(TextEditingController controller, String label, IconData icon,
          {bool number = false,
          String? hint,
          String? helper,
          TextCapitalization capitalize = TextCapitalization.sentences,
          FormFieldValidator<String>? validator}) =>
      TextFormField(
          controller: controller,
          keyboardType: number ? TextInputType.number : TextInputType.text,
          textCapitalization: capitalize,
          decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              hintMaxLines: 2,
              helperText: helper,
              prefixIcon: context.hasLargeText ? null : Icon(icon)),
          validator: validator ??
              (value) {
                if (value?.trim().isEmpty ?? true) return 'Campo obligatorio';
                if (number && (int.tryParse(value!) ?? 0) < 1) {
                  return 'Escribe un número mayor que 0';
                }
                return null;
              });

  Future<bool> _save() async {
    if (!_key.currentState!.validate()) return false;
    await widget.onSave({
      'code': _code.text.trim().toUpperCase(),
      'name': _name.text.trim(),
      'location': _location.text.trim(),
      'capacity': int.parse(_capacity.text),
      'type': _type,
      'description':
          _description.text.trim().isEmpty ? null : _description.text.trim(),
      'status': _status,
      'is_active': widget.room?.isActive ?? true,
    });
    return true;
  }
}
