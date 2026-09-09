import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class PageBody extends StatelessWidget {
  const PageBody({required this.child, this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 28), super.key});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Padding(padding: padding, child: child),
          ),
        ),
      );
}

class AppLogo extends StatelessWidget {
  const AppLogo({this.size = 54, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.blue, AppColors.teal], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(size * .3),
          boxShadow: const [BoxShadow(color: Color(0x241466B8), blurRadius: 18, offset: Offset(0, 8))],
        ),
        child: Icon(Icons.meeting_room_rounded, color: Colors.white, size: size * .55),
      );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.subtitle, this.action, super.key});

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: const TextStyle(color: AppColors.muted)),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      );
}

class StatCard extends StatelessWidget {
  const StatCard({required this.label, required this.value, required this.icon, required this.color, super.key});

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(13)),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(label, maxLines: 2, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            ],
          ),
        ),
      );
}

class ModuleCard extends StatelessWidget {
  const ModuleCard({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap, super.key});

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(15)),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 5),
                      Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
          ),
        ),
      );
}

class StateMessage extends StatelessWidget {
  const StateMessage({required this.icon, required this.title, required this.message, this.actionLabel, this.onAction, super.key});

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(color: AppColors.sky, shape: BoxShape.circle),
                child: Icon(icon, color: AppColors.blue, size: 34),
              ),
              const SizedBox(height: 18),
              Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(message, style: const TextStyle(color: AppColors.muted), textAlign: TextAlign.center),
              if (onAction != null) ...[
                const SizedBox(height: 18),
                FilledButton.tonal(onPressed: onAction, child: Text(actionLabel ?? 'Reintentar')),
              ],
            ],
          ),
        ),
      );
}

class StatusPill extends StatelessWidget {
  const StatusPill({required this.status, this.label, super.key});

  final String status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final (color, defaultLabel) = switch (status) {
      'available' => (AppColors.success, 'Disponible'),
      'confirmed' => (AppColors.success, 'Confirmada'),
      'completed' => (AppColors.blue, 'Finalizada'),
      'maintenance' => (AppColors.warning, 'Mantenimiento'),
      'loaned' => (AppColors.warning, 'En préstamo'),
      'cancelled' => (AppColors.muted, 'Cancelada'),
      'damaged' => (AppColors.danger, 'Averiado'),
      'out_of_service' => (AppColors.danger, 'Fuera de servicio'),
      _ => (AppColors.muted, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(999)),
      child: Text(label ?? defaultLabel, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

void showMessage(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      Icon(error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: Colors.white),
      const SizedBox(width: 12),
      Expanded(child: Text(message)),
    ]),
    backgroundColor: error ? AppColors.danger : AppColors.success,
  ));
}

String formatApiError(Object error) {
  final text = error.toString();
  return text.startsWith('ApiException: ') ? text.substring(14) : text;
}
