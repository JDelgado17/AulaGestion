import 'package:flutter/material.dart';

import '../core/app_config.dart';
import '../repositories/school_repository.dart';
import '../widgets/common_widgets.dart';
import 'dashboard_screen.dart';
import 'modules_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({required this.repository, super.key});

  final SchoolRepository repository;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(repository: widget.repository, onOpenModules: () => setState(() => _index = 1)),
      ModulesScreen(repository: widget.repository),
      NotificationsScreen(repository: widget.repository),
      const ProfileScreen(),
    ];
    const destinations = [
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Inicio'),
      NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view_rounded), label: 'Módulos'),
      NavigationDestination(icon: Icon(Icons.notifications_none_rounded), selectedIcon: Icon(Icons.notifications_rounded), label: 'Avisos'),
      NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Perfil'),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      return Scaffold(
        appBar: AppBar(
          title: const Row(children: [AppLogo(size: 38), SizedBox(width: 12), Text(AppConfig.appName)]),
          actions: [
            IconButton(tooltip: 'Actualizar', onPressed: () => setState(() {}), icon: const Icon(Icons.refresh_rounded)),
            const SizedBox(width: 8),
          ],
        ),
        body: Row(children: [
          if (wide)
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              labelType: NavigationRailLabelType.all,
              groupAlignment: -.7,
              destinations: destinations.map((item) => NavigationRailDestination(icon: item.icon, selectedIcon: item.selectedIcon, label: Text(item.label))).toList(),
            ),
          Expanded(child: IndexedStack(index: _index, children: pages)),
        ]),
        bottomNavigationBar: wide ? null : NavigationBar(selectedIndex: _index, onDestinationSelected: (value) => setState(() => _index = value), destinations: destinations),
      );
    });
  }
}
