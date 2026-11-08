import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../core/catalogs.dart';
import '../models/domain_models.dart';
import '../repositories/school_repository.dart';
import '../widgets/common_widgets.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({required this.repository, super.key});
  final SchoolRepository repository;
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _search = TextEditingController();
  List<AppUser>? _users;
  Object? _error;
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
      final users = await widget.repository.users(search: _search.text);
      if (mounted) {
        setState(() {
          _users = users;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const AppBarTitle('Usuarios y roles')),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _edit(),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Nuevo usuario')),
        body: PageBody(
            child: Column(children: [
          TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) {
                setState(() => _users = null);
                _load();
              },
              decoration: const InputDecoration(
                  labelText: 'Buscar usuario',
                  hintText: 'Nombre o correo',
                  prefixIcon: Icon(Icons.search_rounded))),
          const SizedBox(height: 18),
          Expanded(child: _content()),
        ])),
      );

  Widget _content() {
    if (_error != null && _users == null) {
      return StateMessage(
          icon: Icons.cloud_off_rounded,
          title: 'No pudimos cargar los usuarios',
          message: formatApiError(_error!),
          onAction: _load);
    }
    if (_users == null) return const Center(child: CircularProgressIndicator());
    if (_users!.isEmpty) {
      return const StateMessage(
          icon: Icons.person_search_rounded,
          title: 'Sin resultados',
          message: 'No hay usuarios que coincidan con la búsqueda.');
    }
    return RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 90),
            itemCount: _users!.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final user = _users![index];
              return Card(
                  child: Padding(
                      padding: const EdgeInsets.all(17),
                      child: Row(children: [
                        if (!context.hasLargeText) ...[
                          CircleAvatar(
                              backgroundColor: user.isActive
                                  ? AppColors.sky
                                  : const Color(0xFFEEF1F4),
                              child: Text(_initials(user.name),
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: user.isActive
                                          ? AppColors.blue
                                          : AppColors.muted))),
                          const SizedBox(width: 13),
                        ],
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(user.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Text(user.email,
                                  style:
                                      const TextStyle(color: AppColors.muted)),
                              const SizedBox(height: 8),
                              Wrap(spacing: 8, runSpacing: 6, children: [
                                StatusPill(
                                    status: user.isActive
                                        ? 'available'
                                        : 'cancelled',
                                    label:
                                        user.isActive ? 'Activo' : 'Inactivo'),
                                StatusPill(
                                    status: 'completed', label: user.roleLabel)
                              ])
                            ])),
                        PopupMenuButton<String>(
                            onSelected: (action) =>
                                action == 'edit' ? _edit(user) : _disable(user),
                            itemBuilder: (_) => [
                                  const PopupMenuItem(
                                      value: 'edit',
                                      child: ListTile(
                                          leading: Icon(Icons.edit_outlined),
                                          title: Text('Editar'),
                                          contentPadding: EdgeInsets.zero)),
                                  if (user.isActive)
                                    const PopupMenuItem(
                                        value: 'disable',
                                        child: ListTile(
                                            leading: Icon(Icons.block_rounded,
                                                color: AppColors.danger),
                                            title: Text('Deshabilitar'),
                                            contentPadding: EdgeInsets.zero))
                                ]),
                      ])));
            }));
  }

  String _initials(String value) => value
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  Future<void> _edit([AppUser? user]) async {
    final saved = await showDialog<bool>(
        context: context,
        builder: (_) => _UserForm(
            user: user,
            onSave: (data) async {
              await widget.repository.saveUser(data, id: user?.id);
              await _load();
            }));
    if (saved == true && mounted) {
      showMessage(
          context,
          user == null
              ? 'Usuario creado correctamente.'
              : 'Usuario actualizado.');
    }
  }

  Future<void> _disable(AppUser user) async {
    final done = await showDialog<bool>(
        context: context,
        builder: (_) => AsyncFormDialog(
            title: 'Deshabilitar usuario',
            content: Text(
                '${user.name} perderá el acceso y sus tokens serán revocados.'),
            submitLabel: 'Deshabilitar',
            onSubmit: () async {
              await widget.repository.disableUser(user.id);
              await _load();
              return true;
            }));
    if (done == true && mounted) {
      showMessage(context, 'Usuario deshabilitado.');
    }
  }
}

class _UserForm extends StatefulWidget {
  const _UserForm({required this.onSave, this.user});
  final AppUser? user;
  final Future<void> Function(Map<String, dynamic> data) onSave;
  @override
  State<_UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<_UserForm> {
  final _key = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user?.name);
  late final _email = TextEditingController(text: widget.user?.email);
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  late String _role = widget.user?.role ?? 'professor';
  late bool _active = widget.user?.isActive ?? true;

  @override
  Widget build(BuildContext context) => AsyncFormDialog(
        title: widget.user == null ? 'Registrar usuario' : 'Editar usuario',
        width: 500,
        submitLabel: 'Guardar',
        onSubmit: _save,
        content: Form(
            key: _key,
            child: Column(children: [
              TextFormField(
                  controller: _name,
                  decoration: InputDecoration(
                      labelText: 'Nombre completo',
                      hintText: 'Ej.: Ana María López',
                      hintMaxLines: 2,
                      prefixIcon: _icon(Icons.person_outline_rounded)),
                  validator: _required),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                      labelText: 'Correo institucional',
                      hintText: 'Ej.: ana@colegio.edu.co',
                      hintMaxLines: 2,
                      helperText: 'Con este correo iniciará sesión.',
                      prefixIcon: _icon(Icons.alternate_email_rounded)),
                  validator: (value) => (value?.contains('@') ?? false)
                      ? null
                      : 'Correo inválido'),
              const SizedBox(height: 12),
              AppDropdown<String>(
                  initialValue: _role,
                  decoration: InputDecoration(
                      labelText: 'Rol',
                      helperText: Catalogs.roleDescriptions[_role],
                      prefixIcon: _icon(Icons.admin_panel_settings_outlined)),
                  items: const [
                    DropdownMenuItem(
                        value: 'admin', child: Text('Administrador')),
                    DropdownMenuItem(
                        value: 'professor', child: Text('Profesor')),
                    DropdownMenuItem(
                        value: 'inventory',
                        child: Text('Encargado de inventario'))
                  ],
                  onChanged: (value) => setState(() => _role = value!)),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(
                      labelText: widget.user == null
                          ? 'Contraseña temporal'
                          : 'Nueva contraseña',
                      helperText: widget.user == null
                          ? 'Mínimo 8 caracteres. Compártela con el usuario.'
                          : 'Déjala vacía para no cambiarla.',
                      prefixIcon: _icon(Icons.lock_outline_rounded)),
                  validator: (value) {
                    if (widget.user == null && (value?.length ?? 0) < 8) {
                      return 'Mínimo 8 caracteres';
                    }
                    if ((value?.isNotEmpty ?? false) && value!.length < 8) {
                      return 'Mínimo 8 caracteres';
                    }
                    return null;
                  }),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _confirmation,
                  obscureText: true,
                  decoration: InputDecoration(
                      labelText: 'Confirmar contraseña',
                      prefixIcon: _icon(Icons.lock_reset_rounded)),
                  validator: (value) => _password.text == value
                      ? null
                      : 'Las contraseñas no coinciden'),
              const SizedBox(height: 8),
              SwitchListTile(
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                  title: const Text('Usuario activo'),
                  subtitle:
                      const Text('Puede iniciar sesión y usar sus módulos'),
                  contentPadding: EdgeInsets.zero),
            ])),
      );

  Widget? _icon(IconData icon) => context.hasLargeText ? null : Icon(icon);

  String? _required(String? value) =>
      (value?.trim().isEmpty ?? true) ? 'Campo obligatorio' : null;
  Future<bool> _save() async {
    if (!_key.currentState!.validate()) return false;
    final data = <String, dynamic>{
      'name': _name.text.trim(),
      'email': _email.text.trim().toLowerCase(),
      'role': _role,
      'is_active': _active
    };
    if (_password.text.isNotEmpty) {
      data['password'] = _password.text;
      data['password_confirmation'] = _confirmation.text;
    }
    await widget.onSave(data);
    return true;
  }
}

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({required this.repository, super.key});
  final SchoolRepository repository;
  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  List<Classroom>? _rooms;
  List<Map<String, dynamic>>? _schedules;
  List<Map<String, dynamic>>? _blocks;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final values = await Future.wait([
        widget.repository.classrooms(),
        widget.repository.schedules(),
        widget.repository.blocks()
      ]);
      if (mounted) {
        setState(() {
          _rooms = values[0] as List<Classroom>;
          _schedules = values[1] as List<Map<String, dynamic>>;
          _blocks = values[2] as List<Map<String, dynamic>>;
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
            title: const AppBarTitle('Horarios y bloqueos'),
            bottom: TabBar(
                controller: _tabs,
                tabs: const [Tab(text: 'Horarios'), Tab(text: 'Bloqueos')])),
        body: _error != null && _rooms == null
            ? StateMessage(
                icon: Icons.cloud_off_rounded,
                title: 'No pudimos cargar la configuración',
                message: formatApiError(_error!),
                onAction: _load)
            : TabBarView(
                controller: _tabs, children: [_scheduleTab(), _blocksTab()]),
      );

  Widget _scheduleTab() => PageBody(
          child: Column(children: [
        Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
                onPressed: _rooms == null ? null : _addSchedule,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Agregar horario'))),
        const SizedBox(height: 14),
        Expanded(
            child: _schedules == null
                ? const Center(child: CircularProgressIndicator())
                : _schedules!.isEmpty
                    ? const StateMessage(
                        icon: Icons.schedule_rounded,
                        title: 'Sin horarios',
                        message: 'Agrega la jornada disponible para cada aula.')
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                            itemCount: _schedules!.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, index) {
                              final item = _schedules![index];
                              return Card(
                                  child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 18, vertical: 8),
                                      leading: const CircleAvatar(
                                          backgroundColor: AppColors.sky,
                                          child: Icon(Icons.schedule_rounded,
                                              color: AppColors.blue)),
                                      title: Text(
                                          '${item['classroom']?['code'] ?? ''} · ${_weekday(item['weekday'])}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800)),
                                      subtitle: Text(
                                          '${_shortTime(item['start_time'])} – ${_shortTime(item['end_time'])}'),
                                      trailing: LoadingIconButton(
                                          tooltip: 'Eliminar',
                                          onPressed: () => _deleteSchedule(
                                              item['id'] as int),
                                          icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              color: AppColors.danger))));
                            }))),
      ]));

  Widget _blocksTab() => PageBody(
          child: Column(children: [
        Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
                onPressed: _rooms == null ? null : _addBlock,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Crear bloqueo'))),
        const SizedBox(height: 14),
        Expanded(
            child: _blocks == null
                ? const Center(child: CircularProgressIndicator())
                : _blocks!.isEmpty
                    ? const StateMessage(
                        icon: Icons.event_available_outlined,
                        title: 'Sin bloqueos',
                        message:
                            'No hay mantenimientos ni eventos bloqueando aulas.')
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                            itemCount: _blocks!.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, index) {
                              final item = _blocks![index];
                              final start =
                                  DateTime.parse(item['starts_at'].toString())
                                      .toLocal();
                              final end =
                                  DateTime.parse(item['ends_at'].toString())
                                      .toLocal();
                              return Card(
                                  child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 18, vertical: 8),
                                      leading: CircleAvatar(
                                          backgroundColor: AppColors.warning
                                              .withValues(alpha: .1),
                                          child: const Icon(Icons.block_rounded,
                                              color: AppColors.warning)),
                                      title: Text('${item['classroom']?['code'] ?? ''} · ${item['reason']}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800)),
                                      subtitle: Text(
                                          '${DateFormat('d MMM y', 'es').format(start)} · ${DateFormat('h:mm a').format(start)} – ${DateFormat('h:mm a').format(end)}'),
                                      trailing: LoadingIconButton(
                                          tooltip: 'Eliminar',
                                          onPressed: () =>
                                              _deleteBlock(item['id'] as int),
                                          icon: const Icon(Icons.delete_outline_rounded,
                                              color: AppColors.danger))));
                            }))),
      ]));

  String _weekday(dynamic value) =>
      const {
        1: 'Lunes',
        2: 'Martes',
        3: 'Miércoles',
        4: 'Jueves',
        5: 'Viernes',
        6: 'Sábado',
        7: 'Domingo'
      }[int.tryParse(value.toString())] ??
      '';
  String _shortTime(dynamic value) =>
      value.toString().split(':').take(2).join(':');

  Future<void> _addSchedule() async {
    final saved = await showDialog<bool>(
        context: context,
        builder: (_) => _ScheduleForm(
            rooms: _rooms!,
            onSave: (data) async {
              await widget.repository.createSchedule(data);
              await _load();
            }));
    if (saved == true && mounted) {
      showMessage(context, 'Horario configurado.');
    }
  }

  Future<void> _deleteSchedule(int id) async {
    try {
      await widget.repository.deleteSchedule(id);
      await _load();
      if (mounted) showMessage(context, 'Horario eliminado.');
    } catch (error) {
      if (mounted) showMessage(context, formatApiError(error), error: true);
    }
  }

  Future<void> _addBlock() async {
    final saved = await showDialog<bool>(
        context: context,
        builder: (_) => _BlockForm(
            rooms: _rooms!,
            onSave: (data) async {
              await widget.repository.createBlock(data);
              await _load();
            }));
    if (saved == true && mounted) {
      showMessage(context, 'Bloqueo registrado.');
    }
  }

  Future<void> _deleteBlock(int id) async {
    try {
      await widget.repository.deleteBlock(id);
      await _load();
      if (mounted) showMessage(context, 'Bloqueo eliminado.');
    } catch (error) {
      if (mounted) showMessage(context, formatApiError(error), error: true);
    }
  }
}

class _ScheduleForm extends StatefulWidget {
  const _ScheduleForm({required this.rooms, required this.onSave});
  final List<Classroom> rooms;
  final Future<void> Function(Map<String, dynamic> data) onSave;
  @override
  State<_ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends State<_ScheduleForm> {
  late int _roomId = widget.rooms.first.id;
  int _weekday = 1;
  TimeOfDay _start = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 19, minute: 0);
  @override
  Widget build(BuildContext context) => AsyncFormDialog(
      title: 'Agregar horario',
      width: 480,
      submitLabel: 'Guardar',
      onSubmit: _save,
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Define en qué días y horas se puede reservar el aula.',
              style: TextStyle(color: AppColors.muted)),
        ),
        const SizedBox(height: 14),
        AppDropdown<int>(
            initialValue: _roomId,
            decoration: const InputDecoration(labelText: 'Aula'),
            items: widget.rooms
                .map((room) => DropdownMenuItem(
                    value: room.id, child: Text('${room.code} · ${room.name}')))
                .toList(),
            onChanged: (value) => setState(() => _roomId = value!)),
        const SizedBox(height: 12),
        AppDropdown<int>(
            initialValue: _weekday,
            decoration: const InputDecoration(labelText: 'Día'),
            items: List.generate(
                7,
                (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text(const [
                      'Lunes',
                      'Martes',
                      'Miércoles',
                      'Jueves',
                      'Viernes',
                      'Sábado',
                      'Domingo'
                    ][i]))),
            onChanged: (value) => setState(() => _weekday = value!)),
        const SizedBox(height: 12),
        AdaptiveRow(children: [
          OutlinedButton.icon(
              onPressed: () => _pick(true),
              icon: const Icon(Icons.schedule_rounded),
              label: Text('Inicio ${_start.format(context)}')),
          OutlinedButton.icon(
              onPressed: () => _pick(false),
              icon: const Icon(Icons.schedule_rounded),
              label: Text('Final ${_end.format(context)}')),
        ]),
      ]));

  Future<bool> _save() async {
    final startMinutes = _start.hour * 60 + _start.minute;
    final endMinutes = _end.hour * 60 + _end.minute;
    if (endMinutes <= startMinutes) {
      throw const FormMessage('La hora final debe ser posterior.');
    }
    await widget.onSave({
      'classroom_id': _roomId,
      'weekday': _weekday,
      'start_time': _format(_start),
      'end_time': _format(_end),
      'is_active': true
    });
    return true;
  }

  Future<void> _pick(bool start) async {
    final value = await showTimePicker(
        context: context, initialTime: start ? _start : _end);
    if (value != null) setState(() => start ? _start = value : _end = value);
  }

  String _format(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _BlockForm extends StatefulWidget {
  const _BlockForm({required this.rooms, required this.onSave});
  final List<Classroom> rooms;
  final Future<void> Function(Map<String, dynamic> data) onSave;
  @override
  State<_BlockForm> createState() => _BlockFormState();
}

class _BlockFormState extends State<_BlockForm> {
  late int _roomId = widget.rooms.first.id;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _start = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 14, minute: 0);
  final _reason = TextEditingController();
  @override
  Widget build(BuildContext context) => AsyncFormDialog(
      title: 'Crear bloqueo',
      width: 480,
      submitLabel: 'Crear bloqueo',
      onSubmit: _save,
      content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
                'En ese horario nadie podrá reservar el aula. Quienes ya la tengan reservada recibirán una alerta.',
                style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 14),
            AppDropdown<int>(
                initialValue: _roomId,
                decoration: const InputDecoration(labelText: 'Aula'),
                items: widget.rooms
                    .map((room) => DropdownMenuItem(
                        value: room.id,
                        child: Text('${room.code} · ${room.name}')))
                    .toList(),
                onChanged: (value) => setState(() => _roomId = value!)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(DateFormat('d MMMM y', 'es').format(_date))),
            const SizedBox(height: 12),
            AdaptiveRow(children: [
              OutlinedButton(
                  onPressed: () => _pickTime(true),
                  child: Text('Inicio ${_start.format(context)}')),
              OutlinedButton(
                  onPressed: () => _pickTime(false),
                  child: Text('Final ${_end.format(context)}')),
            ]),
            const SizedBox(height: 12),
            TextField(
                controller: _reason,
                maxLength: 255,
                decoration: const InputDecoration(
                    labelText: 'Motivo del bloqueo',
                    helperText: 'Ej.: mantenimiento o evento')),
          ]));
  Future<void> _pickDate() async {
    final value = await showDatePicker(
        context: context,
        initialDate: _date,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)));
    if (value != null) setState(() => _date = value);
  }

  Future<void> _pickTime(bool start) async {
    final value = await showTimePicker(
        context: context, initialTime: start ? _start : _end);
    if (value != null) setState(() => start ? _start = value : _end = value);
  }

  Future<bool> _save() async {
    final startsAt = DateTime(
        _date.year, _date.month, _date.day, _start.hour, _start.minute);
    final endsAt =
        DateTime(_date.year, _date.month, _date.day, _end.hour, _end.minute);
    if (_reason.text.trim().isEmpty || !endsAt.isAfter(startsAt)) {
      throw const FormMessage('Completa un motivo y una franja válida.');
    }
    await widget.onSave({
      'classroom_id': _roomId,
      'starts_at': startsAt.toIso8601String(),
      'ends_at': endsAt.toIso8601String(),
      'reason': _reason.text.trim()
    });
    return true;
  }
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({required this.repository, super.key});
  final SchoolRepository repository;
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, dynamic>? _data;
  Object? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.repository.reports();
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

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const AppBarTitle('Reportes institucionales')),
      body: PageBody(child: _content()));

  Widget _content() {
    if (_error != null && _data == null) {
      return StateMessage(
          icon: Icons.cloud_off_rounded,
          title: 'No pudimos generar el reporte',
          message: formatApiError(_error!),
          onAction: _load);
    }
    if (_data == null) return const Center(child: CircularProgressIndicator());
    final indicators = Map<String, dynamic>.from(_data!['indicators'] as Map);
    final top = (_data!['top_classrooms'] as List? ?? [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final inventory = (_data!['inventory_by_status'] as List? ?? [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final maxReservations = top.fold<int>(1, (max, item) {
      final value = int.tryParse(item['reservations_count'].toString()) ?? 0;
      return value > max ? value : max;
    });
    return RefreshIndicator(
        onRefresh: _load,
        child: ListView(children: [
          const SectionHeader(
              title: 'Indicadores del mes',
              subtitle: 'Uso de espacios y estado de los recursos'),
          const SizedBox(height: 14),
          StatGrid(children: [
            StatCard(
                label: 'Usuarios activos',
                value: '${indicators['active_users']}',
                icon: Icons.groups_2_outlined,
                color: AppColors.blue),
            StatCard(
                label: 'Aulas activas',
                value: '${indicators['active_classrooms']}',
                icon: Icons.meeting_room_outlined,
                color: AppColors.success),
            StatCard(
                label: 'Reservas confirmadas',
                value: '${indicators['confirmed_reservations']}',
                icon: Icons.event_available_outlined,
                color: AppColors.teal),
            StatCard(
                label: 'Alertas de inventario',
                value: '${indicators['inventory_alerts']}',
                icon: Icons.warning_amber_rounded,
                color: AppColors.warning),
          ]),
          const SizedBox(height: 26),
          const SectionHeader(
              title: 'Aulas con mayor uso',
              subtitle: 'Cantidad de reservas confirmadas'),
          const SizedBox(height: 12),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: top.isEmpty
                      ? const Text('No hay reservas en el periodo.',
                          style: TextStyle(color: AppColors.muted))
                      : Column(
                          children: top.map((item) {
                          final room = item['classroom'] as Map?;
                          final value = int.tryParse(
                                  item['reservations_count'].toString()) ??
                              0;
                          return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '${room?['code'] ?? ''} · ${room?['name'] ?? ''}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700)),
                                    Text('$value reservas',
                                        style: const TextStyle(
                                            color: AppColors.muted)),
                                    const SizedBox(height: 7),
                                    ClipRRect(
                                        borderRadius: BorderRadius.circular(99),
                                        child: LinearProgressIndicator(
                                            value: value / maxReservations,
                                            minHeight: 9,
                                            backgroundColor: AppColors.sky,
                                            color: AppColors.blue))
                                  ]));
                        }).toList()))),
          const SizedBox(height: 26),
          const SectionHeader(title: 'Estado del inventario'),
          const SizedBox(height: 12),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: inventory
                          .map((item) => StatusPill(
                              status: item['status'].toString(),
                              label:
                                  '${_status(item['status'].toString())}: ${item['units']} unidades'))
                          .toList()))),
          const SizedBox(height: 30),
        ]));
  }

  String _status(String value) =>
      const {
        'available': 'Disponibles',
        'loaned': 'En préstamo',
        'maintenance': 'Mantenimiento',
        'damaged': 'Averiados',
        'out_of_service': 'Fuera de servicio'
      }[value] ??
      value;
}
