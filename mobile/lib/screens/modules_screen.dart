import 'package:flutter/material.dart';

import '../core/app_session.dart';
import '../core/app_theme.dart';
import '../repositories/school_repository.dart';
import '../widgets/common_widgets.dart';
import 'admin_screens.dart';
import 'classrooms_screen.dart';
import 'inventory_screen.dart';
import 'reservations_screen.dart';
import 'search_flow.dart';

class ModulesScreen extends StatelessWidget {
  const ModulesScreen({required this.repository, super.key});

  final SchoolRepository repository;

  @override
  Widget build(BuildContext context) {
    final role = AppScope.of(context).user!.role;
    final modules = _modules(context, role);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Text('Módulos', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
            'Funciones habilitadas para ${AppScope.of(context).user!.roleLabel.toLowerCase()}.',
            style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 22),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth >= 860 ? 2 : 1;
          final itemWidth = columns == 2
              ? (constraints.maxWidth - 14) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: 14,
            runSpacing: 14,
            children: modules
                .map((item) => SizedBox(width: itemWidth, child: item))
                .toList(),
          );
        }),
      ],
    );
  }

  List<Widget> _modules(BuildContext context, String role) {
    void open(Widget screen) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    final common = <Widget>[
      ModuleCard(
          title: 'Consultar aulas',
          subtitle: 'Capacidad, ubicación, estado y recursos.',
          icon: Icons.meeting_room_outlined,
          color: AppColors.blue,
          onTap: () => open(ClassroomsScreen(repository: repository))),
      ModuleCard(
          title: 'Reservas',
          subtitle: role == 'admin'
              ? 'Consulta todas las reservas institucionales.'
              : 'Consulta tu historial y cancela reservas.',
          icon: Icons.calendar_month_outlined,
          color: AppColors.teal,
          onTap: () => open(ReservationsScreen(repository: repository))),
    ];

    if (role == 'professor') {
      return [
        ModuleCard(
            title: 'Buscar y reservar',
            subtitle: 'Obtén recomendaciones explicables según tu actividad.',
            icon: Icons.auto_awesome_outlined,
            color: AppColors.success,
            onTap: () => open(SearchScreen(repository: repository))),
        ...common,
      ];
    }
    if (role == 'inventory') {
      return [
        ModuleCard(
            title: 'Gestión de inventario',
            subtitle: 'Registra recursos, cantidades y estados.',
            icon: Icons.inventory_2_outlined,
            color: AppColors.success,
            onTap: () => open(InventoryScreen(repository: repository))),
        ModuleCard(
            title: 'Novedades e historial',
            subtitle: 'Reporta daños, faltantes, mantenimiento o recuperación.',
            icon: Icons.history_rounded,
            color: AppColors.warning,
            onTap: () => open(InventoryEventsScreen(repository: repository))),
        ModuleCard(
            title: 'Reporte de inventario',
            subtitle: 'Consulta alertas y unidades agrupadas por estado.',
            icon: Icons.analytics_outlined,
            color: AppColors.navy,
            onTap: () => open(ReportsScreen(repository: repository))),
        ...common,
      ];
    }
    return [
      ModuleCard(
          title: 'Usuarios y roles',
          subtitle: 'Registra, actualiza y deshabilita cuentas.',
          icon: Icons.manage_accounts_outlined,
          color: AppColors.blue,
          onTap: () => open(UsersScreen(repository: repository))),
      ModuleCard(
          title: 'Administrar aulas',
          subtitle: 'Crea espacios y actualiza capacidad, tipo y estado.',
          icon: Icons.apartment_rounded,
          color: AppColors.success,
          onTap: () => open(
              ClassroomsScreen(repository: repository, managementMode: true))),
      ModuleCard(
          title: 'Horarios y bloqueos',
          subtitle: 'Configura jornadas, mantenimientos y eventos.',
          icon: Icons.schedule_rounded,
          color: AppColors.warning,
          onTap: () => open(SchedulesScreen(repository: repository))),
      ModuleCard(
          title: 'Inventario',
          subtitle: 'Supervisa recursos y novedades de todas las aulas.',
          icon: Icons.inventory_2_outlined,
          color: AppColors.teal,
          onTap: () => open(InventoryScreen(repository: repository))),
      ModuleCard(
          title: 'Reportes',
          subtitle: 'Indicadores de uso, reservas y estado del inventario.',
          icon: Icons.analytics_outlined,
          color: AppColors.navy,
          onTap: () => open(ReportsScreen(repository: repository))),
      ModuleCard(
          title: 'Recomendador',
          subtitle: 'Prueba el flujo principal de búsqueda y reserva.',
          icon: Icons.auto_awesome_outlined,
          color: AppColors.blue,
          onTap: () => open(SearchScreen(repository: repository))),
      ...common,
    ];
  }
}
