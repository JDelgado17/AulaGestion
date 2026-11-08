import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';

extension TextScaleContext on BuildContext {
  double get textScale => MediaQuery.textScalerOf(this).scale(1);

  /// Letra aumentada desde los ajustes del celular: se quita lo decorativo
  /// para dejarle el ancho al texto.
  bool get hasLargeText => textScale >= 1.3;
}

/// Permite que la barra superior recargue una página que sigue montada.
class ReloadHandle {
  Future<void> Function()? reload;

  Future<void> run() async => reload?.call();
}

/// Título de barra superior: se reduce para caber en vez de cortarse con "…".
class AppBarTitle extends StatelessWidget {
  const AppBarTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(text));
}

/// Fila que se apila en vertical cuando el ancho no alcanza para sus textos.
class AdaptiveRow extends StatelessWidget {
  const AdaptiveRow(
      {required this.children,
      this.flex,
      this.spacing = 10,
      this.breakpoint = 600,
      super.key});

  final List<Widget> children;
  final List<int>? flex;
  final double spacing;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    final stacked =
        MediaQuery.sizeOf(context).width / context.textScale < breakpoint;
    final gap = SizedBox(width: spacing, height: spacing);
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) items.add(gap);
      items.add(stacked
          ? children[i]
          : Expanded(flex: flex?[i] ?? 1, child: children[i]));
    }
    return stacked
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: items)
        : Row(crossAxisAlignment: CrossAxisAlignment.start, children: items);
  }
}

/// Lista desplegable cuyas opciones largas ocupan varias líneas sin cortarse.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown(
      {required this.items,
      required this.onChanged,
      this.initialValue,
      this.decoration = const InputDecoration(),
      this.validator,
      this.selectedItemBuilder,
      super.key});

  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final T? initialValue;
  final InputDecoration decoration;
  final FormFieldValidator<T>? validator;
  final DropdownButtonBuilder? selectedItemBuilder;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
      initialValue: initialValue,
      decoration: decoration,
      validator: validator,
      selectedItemBuilder: selectedItemBuilder,
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      isDense: false,
      itemHeight: null);
}

enum LoadingButtonKind { filled, tonal, outlined, text }

/// Botón para acciones que esperan al servidor: mientras corre muestra el
/// indicador de carga y queda deshabilitado, lo que también evita doble envío.
class LoadingButton extends StatefulWidget {
  const LoadingButton(
      {required this.label,
      required this.onPressed,
      this.loadingLabel,
      this.icon,
      this.kind = LoadingButtonKind.filled,
      this.style,
      super.key});

  final String label;
  final String? loadingLabel;
  final IconData? icon;
  final LoadingButtonKind kind;
  final ButtonStyle? style;
  final FutureOr<void> Function()? onPressed;

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton> {
  bool _busy = false;

  Future<void> _run() async {
    setState(() => _busy = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onPressed = widget.onPressed == null || _busy ? null : _run;
    final label =
        Text(_busy ? widget.loadingLabel ?? widget.label : widget.label);
    final icon = _busy
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2))
        : widget.icon == null
            ? null
            : Icon(widget.icon);
    final style = widget.style;
    if (icon == null) {
      return switch (widget.kind) {
        LoadingButtonKind.filled =>
          FilledButton(onPressed: onPressed, style: style, child: label),
        LoadingButtonKind.tonal =>
          FilledButton.tonal(onPressed: onPressed, style: style, child: label),
        LoadingButtonKind.outlined =>
          OutlinedButton(onPressed: onPressed, style: style, child: label),
        LoadingButtonKind.text =>
          TextButton(onPressed: onPressed, style: style, child: label),
      };
    }
    return switch (widget.kind) {
      LoadingButtonKind.filled => FilledButton.icon(
          onPressed: onPressed, style: style, icon: icon, label: label),
      LoadingButtonKind.tonal => FilledButton.tonalIcon(
          onPressed: onPressed, style: style, icon: icon, label: label),
      LoadingButtonKind.outlined => OutlinedButton.icon(
          onPressed: onPressed, style: style, icon: icon, label: label),
      LoadingButtonKind.text => TextButton.icon(
          onPressed: onPressed, style: style, icon: icon, label: label),
    };
  }
}

class LoadingIconButton extends StatefulWidget {
  const LoadingIconButton(
      {required this.icon, required this.onPressed, this.tooltip, super.key});

  final Widget icon;
  final String? tooltip;
  final FutureOr<void> Function()? onPressed;

  @override
  State<LoadingIconButton> createState() => _LoadingIconButtonState();
}

class _LoadingIconButtonState extends State<LoadingIconButton> {
  bool _busy = false;

  Future<void> _run() async {
    setState(() => _busy = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
      tooltip: widget.tooltip,
      onPressed: widget.onPressed == null || _busy ? null : _run,
      icon: _busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2))
          : widget.icon);
}

/// Error de validación que un formulario muestra dentro de su diálogo.
class FormMessage implements Exception {
  const FormMessage(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Diálogo que permanece abierto mientras se guarda: muestra la carga en el
/// botón, se cierra devolviendo `true` si salió bien y muestra el error adentro
/// si falló, para no perder lo escrito. [onSubmit] devuelve `false` cuando la
/// validación del formulario no pasó.
class AsyncFormDialog extends StatefulWidget {
  const AsyncFormDialog(
      {required this.title,
      required this.content,
      required this.submitLabel,
      required this.onSubmit,
      this.cancelLabel = 'Cancelar',
      this.width = 520,
      super.key});

  final String title;
  final Widget content;
  final String submitLabel;
  final String cancelLabel;
  final double width;
  final Future<bool> Function()? onSubmit;

  @override
  State<AsyncFormDialog> createState() => _AsyncFormDialogState();
}

class _AsyncFormDialogState extends State<AsyncFormDialog> {
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final done = await widget.onSubmit!();
      if (done && mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = formatApiError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_busy,
        child: AlertDialog(
          title: Text(widget.title),
          content: SizedBox(
            width: widget.width,
            child: SingleChildScrollView(
              // Deja espacio a la etiqueta flotante del primer campo.
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    widget.content,
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      ErrorBanner(_error!),
                    ],
                  ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: _busy ? null : () => Navigator.pop(context),
                child: Text(widget.cancelLabel)),
            LoadingButton(
                label: widget.submitLabel,
                onPressed: widget.onSubmit == null ? null : _submit),
          ],
        ),
      );
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message,
      {this.color = AppColors.danger,
      this.icon = Icons.error_outline_rounded,
      super.key});

  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(12)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: TextStyle(color: color))),
        ]),
      );
}

/// Cuadrícula de indicadores: las tarjetas de cada fila igualan su altura según
/// el contenido, en lugar de una altura fija que se desborda con letra grande.
class StatGrid extends StatelessWidget {
  const StatGrid({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth / context.textScale;
        final columns = width >= 760
            ? 4
            : width >= 250
                ? 2
                : 1;
        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += columns) {
          final cells = <Widget>[];
          for (var j = i; j < i + columns; j++) {
            if (j > i) cells.add(const SizedBox(width: 12));
            cells.add(Expanded(
                child: j < children.length ? children[j] : const SizedBox()));
          }
          if (i > 0) rows.add(const SizedBox(height: 12));
          rows.add(IntrinsicHeight(
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: cells)));
        }
        return Column(children: rows);
      });
}

class PageBody extends StatelessWidget {
  const PageBody(
      {required this.child,
      this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 28),
      super.key});

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
          gradient: const LinearGradient(
              colors: [AppColors.blue, AppColors.teal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(size * .3),
          boxShadow: const [
            BoxShadow(
                color: Color(0x241466B8), blurRadius: 18, offset: Offset(0, 8))
          ],
        ),
        child: Icon(Icons.meeting_room_rounded,
            color: Colors.white, size: size * .55),
      );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(
      {required this.title, this.subtitle, this.action, super.key});

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          runSpacing: 6,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!,
                      style: const TextStyle(color: AppColors.muted)),
                ],
              ],
            ),
            if (action != null) action!,
          ],
        ),
      );
}

class StatCard extends StatelessWidget {
  const StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      super.key});

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
                decoration: BoxDecoration(
                    color: color.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(13)),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 14),
              const Spacer(),
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            ],
          ),
        ),
      );
}

class ModuleCard extends StatelessWidget {
  const ModuleCard(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.color,
      required this.onTap,
      super.key});

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
                if (!context.hasLargeText) ...[
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(15)),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 5),
                      Text(subtitle,
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 13)),
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
  const StateMessage(
      {required this.icon,
      required this.title,
      required this.message,
      this.actionLabel,
      this.onAction,
      super.key});

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final FutureOr<void> Function()? onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                    color: AppColors.sky, shape: BoxShape.circle),
                child: Icon(icon, color: AppColors.blue, size: 34),
              ),
              const SizedBox(height: 18),
              Text(title,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(message,
                  style: const TextStyle(color: AppColors.muted),
                  textAlign: TextAlign.center),
              if (onAction != null) ...[
                const SizedBox(height: 18),
                LoadingButton(
                    kind: LoadingButtonKind.tonal,
                    label: actionLabel ?? 'Reintentar',
                    loadingLabel: 'Cargando…',
                    onPressed: onAction),
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
      'disabled' => (AppColors.danger, 'Deshabilitada'),
      _ => (AppColors.muted, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(999)),
      child: Text(label ?? defaultLabel,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

void showMessage(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      Icon(
          error
              ? Icons.error_outline_rounded
              : Icons.check_circle_outline_rounded,
          color: Colors.white),
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
