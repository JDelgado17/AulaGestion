import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/app_config.dart';
import '../core/app_theme.dart';
import '../repositories/school_repository.dart';
import '../widgets/common_widgets.dart';
import 'dashboard_screen.dart';
import 'modules_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'reservations_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({required this.repository, super.key});

  final SchoolRepository repository;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  static const _alertsInterval = Duration(seconds: 30);

  final _dashboard = ReloadHandle();
  final _notifications = ReloadHandle();
  final _activeAlerts = ValueNotifier<List<Map<String, dynamic>>>(const []);
  Timer? _alertsTimer;
  Timer? _changesDebounce;
  int _index = 0;
  int _unread = 0;
  bool _checkingAlerts = false;
  bool _alertsDialogOpen = false;
  bool _inForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.repository.client.changes.addListener(_onDataChanged);
    // En segundo plano no se consulta: un aviso se perdería sin que nadie lo vea.
    _alertsTimer = Timer.periodic(_alertsInterval, (_) {
      if (_inForeground) _checkAlerts();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAlerts());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.repository.client.changes.removeListener(_onDataChanged);
    _alertsTimer?.cancel();
    _changesDebounce?.cancel();
    _activeAlerts.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _inForeground = false;
    }
    if (state == AppLifecycleState.resumed) {
      _inForeground = true;
      _reloadAll();
    }
  }

  /// Algo se guardó en cualquier pantalla: el inicio y las alertas se actualizan
  /// sin que el usuario tenga que deslizar para recargar.
  void _onDataChanged() {
    _changesDebounce?.cancel();
    _changesDebounce =
        Timer(const Duration(milliseconds: 250), () => _reloadAll());
  }

  Future<Object?> _reloadAll() async {
    await Future.wait([_dashboard.run(), _notifications.run()]);
    return _checkAlerts();
  }

  void _select(int index) {
    setState(() => _index = index);
    if (index == 0) unawaited(_dashboard.run());
    if (index == 2) unawaited(_notifications.run());
  }

  /// Actualiza el contador y hace saltar las alertas de aulas no disponibles.
  /// Devuelve el error si falló; la consulta periódica lo ignora y vuelve a
  /// intentar en el siguiente ciclo.
  Future<Object?> _checkAlerts() async {
    if (_checkingAlerts) return null;
    _checkingAlerts = true;
    try {
      final result = await widget.repository.pendingAlerts();
      if (!mounted) return null;
      final unread = (result['unread_count'] as num?)?.toInt() ?? 0;
      final alerts = _records(result['alerts']);
      final notices = _records(result['notices']);
      final alertsChanged = !setEquals(_ids(alerts), _ids(_activeAlerts.value));
      // Una alerta resuelta puede dejar igual el contador: también se compara
      // qué alertas hay, para que el inicio y el historial no queden atrasados.
      if (unread != _unread || alertsChanged || notices.isNotEmpty) {
        setState(() => _unread = unread);
        unawaited(_notifications.run());
        unawaited(_dashboard.run());
      }
      _activeAlerts.value = alerts;
      if (alerts.isNotEmpty && !_alertsDialogOpen) {
        unawaited(_showAlerts());
      }
      _announce(notices);
      return null;
    } catch (error) {
      return error;
    } finally {
      _checkingAlerts = false;
    }
  }

  List<Map<String, dynamic>> _records(Object? value) => (value as List? ?? [])
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();

  Set<Object?> _ids(List<Map<String, dynamic>> items) =>
      items.map((item) => item['id']).toSet();

  void _announce(List<Map<String, dynamic>> notices) {
    if (notices.isEmpty) return;
    final single = notices.length == 1 ? notices.first : null;
    final isReminder = single?['type'] == 'reservation_reminder';
    showNotice(context,
        title: single?['title']?.toString() ?? 'Novedades en tus reservas',
        message: single?['message']?.toString() ??
            'Tienes ${notices.length} avisos nuevos.',
        icon: isReminder
            ? Icons.alarm_rounded
            : Icons.check_circle_outline_rounded,
        color: isReminder ? AppColors.blue : AppColors.success,
        onView: _openAlerts);
  }

  void _openAlerts() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    _select(2);
  }

  Future<void> _showAlerts() async {
    _alertsDialogOpen = true;
    final openReservations = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _RoomAlertsDialog(
            alerts: _activeAlerts, repository: widget.repository));
    _alertsDialogOpen = false;
    if (!mounted) return;
    if (openReservations == true) {
      unawaited(Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ReservationsScreen(repository: widget.repository))));
    }
    await _checkAlerts();
  }

  Future<void> _refresh() async {
    final error = await _reloadAll();
    if (!mounted) return;
    if (error == null) {
      showMessage(context, 'Información actualizada.');
    } else {
      // Con código de estado el servidor sí respondió: no es falta de conexión.
      showMessage(
          context,
          error is ApiException && error.statusCode != null
              ? 'El servidor no pudo responder. Intenta de nuevo en un momento.'
              : 'No hay conexión con el servidor. Revisa tu internet.',
          error: true);
    }
  }

  Widget _alertsIcon(IconData icon) => Badge(
      isLabelVisible: _unread > 0,
      label: Text(_unread > 99 ? '99+' : '$_unread'),
      child: Icon(icon));

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
          repository: widget.repository,
          reloadHandle: _dashboard,
          onOpenModules: () => _select(1),
          onOpenAlerts: () => _select(2)),
      ModulesScreen(repository: widget.repository),
      NotificationsScreen(
          repository: widget.repository, reloadHandle: _notifications),
      const ProfileScreen(),
    ];
    final destinations = [
      const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Inicio'),
      const NavigationDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view_rounded),
          label: 'Módulos'),
      NavigationDestination(
          icon: _alertsIcon(Icons.notifications_none_rounded),
          selectedIcon: _alertsIcon(Icons.notifications_rounded),
          label: 'Alertas'),
      const NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Perfil'),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      // En Flutter Web la vista puede medir ~1x1 px durante un instante
      // (al abrir/cerrar DevTools o cambiar el modo responsive). Con ese
      // tamaño la AppBar no cabe y lanza "RenderFlex overflowed".
      // Mientras la ventana no tenga un tamaño real, no se dibuja nada.
      if (constraints.maxWidth < 120 || constraints.maxHeight < 120) {
        return const SizedBox.shrink();
      }
      final wide = constraints.maxWidth >= 900;
      return Scaffold(
        appBar: AppBar(
          title: const Row(children: [
            AppLogo(size: 38),
            SizedBox(width: 12),
            Flexible(child: AppBarTitle(AppConfig.appName)),
          ]),
          actions: [
            LoadingIconButton(
                tooltip: 'Actualizar',
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded)),
            const SizedBox(width: 8),
          ],
        ),
        body: Row(children: [
          if (wide)
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              groupAlignment: -.7,
              destinations: destinations
                  .map((item) => NavigationRailDestination(
                      icon: item.icon,
                      selectedIcon: item.selectedIcon,
                      label: Text(item.label)))
                  .toList(),
            ),
          Expanded(child: IndexedStack(index: _index, children: pages)),
        ]),
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: _select,
                destinations: destinations),
      );
    });
  }
}

/// Alerta que salta sobre cualquier pantalla. Se confirma para marcarla como
/// leída, y se cierra sola si el problema desaparece mientras está abierta: una
/// alerta que ya no es cierta no debe seguir en pantalla.
class _RoomAlertsDialog extends StatefulWidget {
  const _RoomAlertsDialog({required this.alerts, required this.repository});

  final ValueListenable<List<Map<String, dynamic>>> alerts;
  final SchoolRepository repository;

  @override
  State<_RoomAlertsDialog> createState() => _RoomAlertsDialogState();
}

class _RoomAlertsDialogState extends State<_RoomAlertsDialog> {
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.alerts.addListener(_closeIfResolved);
  }

  @override
  void dispose() {
    widget.alerts.removeListener(_closeIfResolved);
    super.dispose();
  }

  void _closeIfResolved() {
    // Si ya se está cerrando, cerrar otra vez sacaría la pantalla de abajo.
    final isOpen = ModalRoute.of(context)?.isCurrent ?? false;
    if (widget.alerts.value.isEmpty && isOpen && !_busy) {
      Navigator.pop(context, false);
    }
  }

  Future<void> _acknowledge(bool openReservations) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Future.wait(widget.alerts.value.map((alert) =>
          widget.repository.markNotificationRead(alert['id'] as int)));
      if (mounted) Navigator.pop(context, openReservations);
    } catch (error) {
      if (mounted) setState(() => _error = formatApiError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        child: ValueListenableBuilder(
          valueListenable: widget.alerts,
          builder: (context, alerts, _) => AlertDialog(
            icon: const Icon(Icons.warning_amber_rounded,
                color: AppColors.danger, size: 44),
            title: Text(
                alerts.length == 1
                    ? 'Aula no disponible'
                    : '${alerts.length} aulas no disponibles',
                textAlign: TextAlign.center),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final alert in alerts)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(alert['message']?.toString() ?? '')),
                      if (_error != null) ErrorBanner(_error!),
                    ]),
              ),
            ),
            actions: [
              LoadingButton(
                  kind: LoadingButtonKind.text,
                  label: 'Ver mis reservas',
                  onPressed: () => _acknowledge(true)),
              LoadingButton(
                  label: 'Entendido', onPressed: () => _acknowledge(false)),
            ],
          ),
        ),
      );
}
