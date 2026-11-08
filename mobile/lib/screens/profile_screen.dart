import 'package:flutter/material.dart';

import '../core/app_config.dart';
import '../core/app_session.dart';
import '../core/app_theme.dart';
import '../widgets/common_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context);
    final user = session.user!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Text('Mi perfil', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.sky,
                child: Text(_initials(user.name),
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.blue)),
              ),
              const SizedBox(height: 16),
              Text(user.name,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(user.email, style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 12),
              StatusPill(status: 'available', label: user.roleLabel),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(children: [
            const ListTile(
                leading: Icon(Icons.school_outlined, color: AppColors.blue),
                title: Text('Institución'),
                subtitle: Text(AppConfig.institutionName)),
            const Divider(height: 1, indent: 72),
            const ListTile(
                leading:
                    Icon(Icons.support_agent_rounded, color: AppColors.teal),
                title: Text('Soporte'),
                subtitle: Text(AppConfig.supportEmail)),
          ]),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed:
              session.isSubmitting ? null : () => _confirmLogout(context),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Cerrar sesión'),
        ),
        const SizedBox(height: 14),
        const Text('AulaGestión · versión ${AppConfig.appVersion}',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 12)),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final session = AppScope.of(context);
    await showDialog<bool>(
      context: context,
      builder: (_) => AsyncFormDialog(
        title: 'Cerrar sesión',
        content:
            const Text('¿Deseas salir de AulaGestión en este dispositivo?'),
        submitLabel: 'Cerrar sesión',
        onSubmit: () async {
          await session.logout();
          return true;
        },
      ),
    );
  }

  String _initials(String name) => name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();
}
