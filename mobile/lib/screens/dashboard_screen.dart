import 'package:flutter/material.dart';

import '../core/app_session.dart';
import '../core/app_theme.dart';
import '../repositories/school_repository.dart';
import '../widgets/common_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({required this.repository, required this.onOpenModules, super.key});

  final SchoolRepository repository;
  final VoidCallback onOpenModules;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final data = await widget.repository.dashboard();
      if (mounted) setState(() => _data = data);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AppScope.of(context).user!;
    if (_error != null && _data == null) {
      return StateMessage(icon: Icons.cloud_off_rounded, title: 'No pudimos cargar el panel', message: formatApiError(_error!), onAction: _load);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.navy, AppColors.blue, AppColors.teal], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(26),
              boxShadow: const [BoxShadow(color: Color(0x2612365A), blurRadius: 26, offset: Offset(0, 12))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(99)),
                child: Text(user.roleLabel.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: .8)),
              ),
              const SizedBox(height: 18),
              Text('Hola, ${user.name.split(' ').first}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(_welcome(user.role), style: TextStyle(color: Colors.white.withValues(alpha: .84), height: 1.4)),
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.blue),
                onPressed: widget.onOpenModules,
                icon: const Icon(Icons.grid_view_rounded),
                label: const Text('Ir a los módulos'),
              ),
            ]),
          ),
          const SizedBox(height: 26),
          const SectionHeader(title: 'Resumen de hoy', subtitle: 'Información actualizada desde el servidor'),
          const SizedBox(height: 14),
          if (_data == null)
            const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()))
          else
            LayoutBuilder(builder: (context, constraints) {
              final width = (constraints.maxWidth - 12) / 2;
              final cards = _cards(_data!);
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: cards.map((card) => SizedBox(width: constraints.maxWidth >= 760 ? (constraints.maxWidth - 36) / 4 : width, height: 166, child: card)).toList(),
              );
            }),
          const SizedBox(height: 26),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.verified_user_outlined, color: AppColors.teal),
                const SizedBox(width: 14),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Información confiable', style: TextStyle(fontWeight: FontWeight.w800)),
                  SizedBox(height: 5),
                  Text('Cada reserva se valida nuevamente al confirmar para evitar cruces y asegurar los recursos.', style: TextStyle(color: AppColors.muted)),
                ])),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _cards(Map<String, dynamic> data) => [
        StatCard(label: 'Aulas disponibles', value: '${data['classrooms_available'] ?? 0}', icon: Icons.meeting_room_outlined, color: AppColors.success),
        StatCard(label: 'Reservas próximas', value: '${data['upcoming_reservations'] ?? 0}', icon: Icons.event_available_rounded, color: AppColors.blue),
        StatCard(label: 'Alertas de inventario', value: '${data['inventory_alerts'] ?? 0}', icon: Icons.inventory_2_outlined, color: AppColors.warning),
        StatCard(label: 'Notificaciones nuevas', value: '${data['unread_notifications'] ?? 0}', icon: Icons.notifications_none_rounded, color: AppColors.teal),
      ];

  String _welcome(String role) => switch (role) {
        'admin' => 'Supervisa usuarios, espacios, horarios y reportes desde un solo lugar.',
        'inventory' => 'Mantén actualizados los recursos y registra cada novedad con trazabilidad.',
        _ => 'Encuentra el aula adecuada y reserva con disponibilidad verificada.',
      };
}

