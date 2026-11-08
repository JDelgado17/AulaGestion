import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aula_gestion/core/api_client.dart';
import 'package:aula_gestion/core/app_config.dart';
import 'package:aula_gestion/core/app_session.dart';
import 'package:aula_gestion/core/app_theme.dart';
import 'package:aula_gestion/models/domain_models.dart';
import 'package:aula_gestion/repositories/auth_repository.dart';
import 'package:aula_gestion/repositories/school_repository.dart';
import 'package:aula_gestion/screens/admin_screens.dart';
import 'package:aula_gestion/screens/classrooms_screen.dart';
import 'package:aula_gestion/screens/inventory_screen.dart';
import 'package:aula_gestion/screens/main_shell.dart';
import 'package:aula_gestion/screens/reservations_screen.dart';
import 'package:aula_gestion/screens/search_flow.dart';
import 'package:aula_gestion/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';

const _room = {
  'id': 1,
  'code': 'LAB-201',
  'name': 'Laboratorio de ciencias naturales',
  'location': 'Bloque B, segundo piso, costado norte',
  'capacity': 40,
  'type': 'Laboratorio',
  'description': 'Aula con mesones y equipos de laboratorio.',
  'status': 'out_of_service',
  'is_active': true,
};

final _item = {
  'id': 1,
  'classroom_id': 1,
  'name': 'Videobeam de alta definición',
  'category': 'Tecnología',
  'quantity': 4,
  'available_quantity': 2,
  'status': 'out_of_service',
  'description': 'Equipo principal',
  'classroom': _room,
};

const _alert = {
  'id': 7,
  'title': 'Aula no disponible',
  'message':
      'Tu reserva de LAB-201 del 10/11/2026 de 08:00 a 10:00 se ve afectada: el aula fue deshabilitada. Cancélala o busca otra aula.',
  'type': 'classroom_unavailable',
  'read_at': null,
  'created_at': '2026-11-08T10:00:00-05:00',
  'metadata': {'alert_state': 'active', 'reservation_id': 3},
};

Map<String, dynamic> _paged(List<Object> data) => {'data': data};

Map<String, dynamic> _reservationJson() => {
      'id': 3,
      'starts_at':
          DateTime.now().add(const Duration(days: 2)).toIso8601String(),
      'ends_at': DateTime.now()
          .add(const Duration(days: 2, hours: 2))
          .toIso8601String(),
      'attendees': 25,
      'activity_type': 'Clase',
      'purpose': 'Práctica de laboratorio de grado once',
      'status': 'confirmed',
      'classroom': _room,
      'availability_issue': 'el aula fue deshabilitada',
    };

Object? _response(http.Request request, {required bool withAlerts}) {
  final path = request.url.path;
  if (path.endsWith('/notifications/alerts')) {
    return {
      'unread_count': withAlerts ? 1 : 0,
      'alerts': withAlerts ? [_alert] : [],
    };
  }
  if (path.endsWith('/notifications')) {
    return _paged([
      _alert,
      {
        ..._alert,
        'id': 8,
        'read_at': '2026-11-08T11:00:00-05:00',
        'metadata': {'alert_state': 'resolved'},
      },
      {
        'id': 9,
        'title': 'Reserva confirmada',
        'message': 'LAB-201 fue reservada.',
        'type': 'reservation_confirmed',
        'read_at': null,
        'created_at': '2026-11-08T09:00:00-05:00',
      },
    ]);
  }
  if (path.endsWith('/dashboard')) {
    return {
      'classrooms_available': 6,
      'upcoming_reservations': 12,
      'inventory_alerts': 3,
      'unread_notifications': 2,
      'classrooms_attention': 1,
      'active_alerts': 1,
      'next_reservations': [
        _reservationJson(),
        _reservationJson(),
        _reservationJson()
      ],
    };
  }
  if (path.endsWith('/classrooms/1')) {
    return {
      ..._room,
      'inventory_items': [_item],
    };
  }
  if (path.endsWith('/classrooms')) {
    return _paged([
      _room,
      {..._room, 'id': 2, 'code': 'A-2', 'is_active': false},
    ]);
  }
  if (path.endsWith('/inventory-events')) {
    return _paged([
      {
        'id': 1,
        'type': 'damage',
        'description': 'Se dañó la lámpara del equipo.',
        'occurred_at': '2026-11-08T09:00:00-05:00',
        'item': _item,
        'classroom': _room,
        'user': {'name': 'Encargado de inventario'},
      },
    ]);
  }
  if (path.endsWith('/inventory')) return _paged([_item]);
  if (path.endsWith('/reservations')) {
    return _paged([
      {
        'id': 3,
        'starts_at':
            DateTime.now().add(const Duration(days: 2)).toIso8601String(),
        'ends_at': DateTime.now()
            .add(const Duration(days: 2, hours: 2))
            .toIso8601String(),
        'attendees': 25,
        'activity_type': 'Clase de ciencias',
        'purpose': 'Práctica de laboratorio de grado once',
        'status': 'confirmed',
        'classroom': _room,
        'availability_issue': 'el aula fue deshabilitada',
        'user': {
          'id': 1,
          'name': 'Profesora Demo',
          'email': 'profesor@demo.edu.co',
          'role': 'professor',
          'is_active': true,
        },
      },
    ]);
  }
  if (path.endsWith('/users')) {
    return _paged([
      {
        'id': 1,
        'name': 'María Alejandra Vallejo Zamora',
        'email': 'maria.vallejo@institucion.edu.co',
        'role': 'inventory',
        'is_active': true,
      },
    ]);
  }
  if (path.endsWith('/schedules')) {
    return [
      {
        'id': 1,
        'weekday': 3,
        'start_time': '07:00:00',
        'end_time': '19:00:00',
        'classroom': _room,
      },
    ];
  }
  if (path.endsWith('/blocks')) {
    return [
      {
        'id': 1,
        'starts_at': '2026-11-10T08:00:00-05:00',
        'ends_at': '2026-11-10T10:00:00-05:00',
        'reason': 'Mantenimiento general de la sede',
        'classroom': _room,
      },
    ];
  }
  if (path.endsWith('/reports/summary')) {
    return {
      'indicators': {
        'active_users': 3,
        'active_classrooms': 6,
        'confirmed_reservations': 18,
        'inventory_alerts': 2,
      },
      'top_classrooms': [
        {'reservations_count': 12, 'classroom': _room},
      ],
      'inventory_by_status': [
        {'status': 'out_of_service', 'units': 3},
      ],
    };
  }
  if (path.endsWith('/recommendations/search')) {
    return {
      'recommendations': [
        {
          'classroom': _room,
          'match_percent': 95,
          'match_level': 'Alta',
          'is_exact_match': true,
          'reasons': ['Capacidad adecuada para el grupo indicado.'],
          'missing_resources': <String>[],
        },
      ],
      'alternatives': <Object>[],
      'alternative_times': [
        {
          'starts_at': '2026-11-10T08:00:00-05:00',
          'ends_at': '2026-11-10T10:00:00-05:00',
          'available_rooms': 3,
        },
      ],
    };
  }
  return <String, dynamic>{};
}

SchoolRepository _repository({
  bool withAlerts = false,
  Future<void> Function(http.Request request)? hook,
}) =>
    SchoolRepository(
      ApiClient(
        baseUrl: 'http://test/api',
        httpClient: MockClient((request) async {
          await hook?.call(request);
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'data': _response(request, withAlerts: withAlerts),
              }),
            ),
            200,
          );
        }),
      ),
    );

Widget _app(Widget home, {String role = 'admin'}) {
  final session = AppSession(
    AuthRepository(ApiClient(baseUrl: 'http://test/api')),
  )..user = AppUser(
      id: 1,
      name: 'Administradora Institucional',
      email: 'administradora@institucion.edu.co',
      role: role,
      isActive: true,
    );
  return AppScope(
    session: session,
    child: MaterialApp(
      theme: AppTheme.light,
      // Mismo tope de letra que la aplicación real.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: AppConfig.maxTextScale,
        child: child!,
      ),
      locale: const Locale('es', 'CO'),
      supportedLocales: const [Locale('es', 'CO')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    ),
  );
}

Future<void> _open(WidgetTester tester, Widget home) async {
  await tester.pumpWidget(_app(home));
  await tester.pumpAndSettle();
  _expectNoCutText(tester);
}

/// Falla si algún texto visible se cortó con "…", como el "Estu…" del buscador.
void _expectNoCutText(WidgetTester tester) {
  if (!_realFonts) return;
  final cut = tester.allRenderObjects
      .whereType<RenderParagraph>()
      .where((paragraph) => paragraph.didExceedMaxLines)
      .map((paragraph) => paragraph.text.toPlainText())
      .toList();
  expect(cut, isEmpty, reason: 'Textos cortados: $cut');
}

var _realFonts = false;

/// Carga la fuente real de Android para medir los textos como en el celular.
Future<void> _loadFonts() async {
  final fonts =
      '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts';
  if (!File('$fonts/roboto-regular.ttf').existsSync()) return;
  _realFonts = true;
  Future<ByteData> read(String name) async =>
      ByteData.sublistView(await File('$fonts/$name').readAsBytes());
  final roboto = FontLoader('Roboto');
  for (final weight in ['regular', 'medium', 'bold', 'black']) {
    roboto.addFont(read('roboto-$weight.ttf'));
  }
  await roboto.load();
  await (FontLoader('MaterialIcons')
        ..addFont(read('materialicons-regular.otf')))
      .load();
}

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

/// Abre un formulario con el botón indicado, verifica que se dibuje y lo cierra.
Future<void> _openDialog(WidgetTester tester, Finder button) async {
  await tester.ensureVisible(button.first);
  await tester.pumpAndSettle();
  await tester.tap(button.first);
  await tester.pumpAndSettle();
  expect(find.byType(AlertDialog), findsOneWidget);
  _expectNoCutText(tester);
  await tester.tap(find.text('Cancelar').last);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
    await _loadFonts();
  });

  // Cubre letra reducida, normal, grande y mayor al tope que permite la app.
  const scales = [0.85, 1.0, 1.3, 2.0];
  const widths = [320.0, 360.0, 411.0];

  for (final width in widths) {
    for (final scale in scales) {
      group('ancho $width, letra x$scale:', () {
        Future<void> configure(WidgetTester tester) async {
          tester.view.physicalSize = Size(width, 780);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearAllTestValues);
        }

        testWidgets('pantalla principal y sus pestañas', (tester) async {
          await configure(tester);
          await _open(tester, MainShell(repository: _repository()));
          for (final label in ['Módulos', 'Alertas', 'Perfil', 'Inicio']) {
            await tester.tap(find.text(label).last);
            await tester.pumpAndSettle();
            _expectNoCutText(tester);
          }
          await tester.pumpWidget(const SizedBox());
        });

        testWidgets('inicio del profesor y del encargado', (tester) async {
          await configure(tester);
          for (final role in ['professor', 'inventory']) {
            await tester.pumpWidget(
              _app(MainShell(repository: _repository()), role: role),
            );
            await tester.pumpAndSettle();
            _expectNoCutText(tester);
            await tester.pumpWidget(const SizedBox());
          }
        });

        testWidgets('aulas, detalle y formularios', (tester) async {
          await configure(tester);
          await _open(
            tester,
            ClassroomsScreen(repository: _repository(), managementMode: true),
          );
          await _openDialog(tester, find.text('Nueva aula'));
          await _openDialog(tester, find.text('Deshabilitar'));
          await tester.tap(find.textContaining('LAB-201').first);
          await tester.pumpAndSettle();
          _expectNoCutText(tester);
        });

        testWidgets('inventario y formularios', (tester) async {
          await configure(tester);
          await _open(tester, InventoryScreen(repository: _repository()));
          await _openDialog(tester, find.text('Nuevo elemento'));
          await _openDialog(tester, find.text('Registrar novedad'));
          await _open(
            tester,
            InventoryEventsScreen(repository: _repository()),
          );
        });

        testWidgets('reservas, calendario y cancelación', (tester) async {
          await configure(tester);
          await _open(tester, ReservationsScreen(repository: _repository()));
          await tester.tap(find.byIcon(Icons.calendar_month_outlined));
          await tester.pumpAndSettle();
          await tester.tap(find.byIcon(Icons.view_agenda_outlined));
          await tester.pumpAndSettle();
          final button = find.text('Cancelar reserva');
          await tester.ensureVisible(button);
          await tester.pumpAndSettle();
          await tester.tap(button);
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsOneWidget);
          _expectNoCutText(tester);
        });

        testWidgets('buscar aula y resultados', (tester) async {
          await configure(tester);
          await _open(tester, SearchScreen(repository: _repository()));
          final attendees = find.widgetWithText(TextFormField, 'Asistentes');
          await _scrollTo(tester, attendees);
          await tester.enterText(attendees, '25');
          await tester.pumpAndSettle();
          final button = find.text('Buscar aulas');
          await _scrollTo(tester, button);
          await tester.tap(button);
          await tester.pumpAndSettle();
          expect(find.text('Aulas recomendadas'), findsOneWidget);
          _expectNoCutText(tester);
          final reserve = find.text('Reservar esta aula');
          await _scrollTo(tester, reserve);
          await tester.tap(reserve);
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsOneWidget);
        });

        testWidgets('usuarios, horarios, bloqueos y reportes', (tester) async {
          await configure(tester);
          await _open(tester, UsersScreen(repository: _repository()));
          await _openDialog(tester, find.text('Nuevo usuario'));
          await _open(tester, SchedulesScreen(repository: _repository()));
          await _openDialog(tester, find.text('Agregar horario'));
          await tester.tap(find.text('Bloqueos'));
          await tester.pumpAndSettle();
          await _openDialog(tester, find.text('Crear bloqueo'));
          await _open(tester, ReportsScreen(repository: _repository()));
        });

        testWidgets('alerta emergente de aula no disponible', (tester) async {
          await configure(tester);
          await _open(
            tester,
            MainShell(repository: _repository(withAlerts: true)),
          );
          expect(find.text('Aula no disponible'), findsWidgets);
          await tester.pumpWidget(const SizedBox());
        });
      });
    }
  }

  group('estado de carga:', () {
    testWidgets('el botón muestra la carga y evita el doble envío', (
      tester,
    ) async {
      final done = Completer<void>();
      var presses = 0;
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Center(
              child: LoadingButton(
                label: 'Guardar',
                loadingLabel: 'Guardando…',
                onPressed: () {
                  presses++;
                  return done.future;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.tap(find.text('Guardar'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Guardando…'), findsOneWidget);

      await tester.tap(find.text('Guardando…'), warnIfMissed: false);
      await tester.pump();
      expect(presses, 1);

      done.complete();
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Guardar'), findsOneWidget);
    });

    testWidgets('el diálogo espera al servidor y muestra el error adentro', (
      tester,
    ) async {
      final done = Completer<void>();
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<bool>(
                  context: context,
                  builder: (_) => AsyncFormDialog(
                    title: 'Formulario',
                    content: const Text('Contenido'),
                    submitLabel: 'Enviar',
                    onSubmit: () async {
                      await done.future;
                      throw const FormMessage('Dato rechazado');
                    },
                  ),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enviar'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);

      done.complete();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Dato rechazado'), findsOneWidget);
    });

    testWidgets('actualizar consulta al servidor y lo confirma',
        (tester) async {
      var dashboardCalls = 0;
      await _open(
        tester,
        MainShell(
          repository: _repository(
            hook: (request) async {
              if (request.url.path.endsWith('/dashboard')) dashboardCalls++;
            },
          ),
        ),
      );
      final before = dashboardCalls;
      await tester.tap(find.byTooltip('Actualizar'));
      await tester.pumpAndSettle();
      expect(dashboardCalls, greaterThan(before));
      expect(find.text('Información actualizada.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('inicio y actualización:', () {
    testWidgets('el profesor ve su reserva primero y no el resumen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(411, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(MainShell(repository: _repository()), role: 'professor'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tu próxima reserva'), findsOneWidget);
      expect(find.textContaining('LAB-201'), findsWidgets);
      expect(find.text('Reservar un aula'), findsOneWidget);
      expect(find.text('Aulas disponibles'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('el administrador sí ve el resumen', (tester) async {
      tester.view.physicalSize = const Size(411, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(MainShell(repository: _repository())));
      await tester.pumpAndSettle();

      expect(find.text('Aulas disponibles'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('guardar algo actualiza inicio y alertas sin recargar', (
      tester,
    ) async {
      var notificationCalls = 0;
      var dashboardCalls = 0;
      final repository = _repository(
        hook: (request) async {
          if (request.url.path.endsWith('/notifications')) notificationCalls++;
          if (request.url.path.endsWith('/dashboard')) dashboardCalls++;
        },
      );
      await _open(tester, MainShell(repository: repository));
      final notificationsBefore = notificationCalls;
      final dashboardBefore = dashboardCalls;

      await repository.markAllNotificationsRead();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(notificationCalls, greaterThan(notificationsBefore));
      expect(dashboardCalls, greaterThan(dashboardBefore));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('abrir la pestaña Alertas consulta de nuevo', (tester) async {
      var notificationCalls = 0;
      await _open(
        tester,
        MainShell(
          repository: _repository(
            hook: (request) async {
              if (request.url.path.endsWith('/notifications')) {
                notificationCalls++;
              }
            },
          ),
        ),
      );
      final before = notificationCalls;
      await tester.tap(find.text('Alertas').last);
      await tester.pumpAndSettle();
      expect(notificationCalls, greaterThan(before));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('si el servidor responde con error no dice "sin conexión"', (
      tester,
    ) async {
      final repository = SchoolRepository(
        ApiClient(
          baseUrl: 'http://test/api',
          httpClient: MockClient((request) async {
            if (request.url.path.endsWith('/notifications/alerts')) {
              return http.Response('{"message":"Not found"}', 404);
            }
            return http.Response.bytes(
              utf8.encode(
                jsonEncode({'data': _response(request, withAlerts: false)}),
              ),
              200,
            );
          }),
        ),
      );
      await _open(tester, MainShell(repository: repository));
      await tester.tap(find.byTooltip('Actualizar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No hay conexión'), findsNothing);
      expect(find.textContaining('El servidor no pudo'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('formulario de aula:', () {
    testWidgets('explica los campos y valida el formato del código', (
      tester,
    ) async {
      await _open(
        tester,
        ClassroomsScreen(repository: _repository(), managementMode: true),
      );
      await tester.tap(find.text('Nueva aula'));
      await tester.pumpAndSettle();

      expect(find.text('Ej.: A-101'), findsOneWidget);
      expect(find.text('Ej.: Bloque A, piso 2'), findsOneWidget);
      expect(find.textContaining('Máximo de personas'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Código'),
        'aula uno',
      );
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('un guion'), findsWidgets);
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group('alertas:', () {
    testWidgets('confirmar la alerta la marca como leída y la cierra', (
      tester,
    ) async {
      final marked = <String>[];
      var alertsActive = true;
      final repository = SchoolRepository(
        ApiClient(
          baseUrl: 'http://test/api',
          httpClient: MockClient((request) async {
            if (request.method == 'PATCH') {
              marked.add(request.url.path);
              alertsActive = false;
            }
            return http.Response.bytes(
              utf8.encode(
                jsonEncode({
                  'data': _response(request, withAlerts: alertsActive),
                }),
              ),
              200,
            );
          }),
        ),
      );
      await _open(tester, MainShell(repository: repository));
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();

      expect(marked, ['/api/notifications/7/read']);
      expect(find.byType(AlertDialog), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('la consulta periódica hace saltar una alerta nueva', (
      tester,
    ) async {
      var alertsActive = false;
      final repository = SchoolRepository(
        ApiClient(
          baseUrl: 'http://test/api',
          httpClient: MockClient((request) async {
            return http.Response.bytes(
              utf8.encode(
                jsonEncode({
                  'data': _response(request, withAlerts: alertsActive),
                }),
              ),
              200,
            );
          }),
        ),
      );
      await _open(tester, MainShell(repository: repository));
      expect(find.byType(AlertDialog), findsNothing);

      alertsActive = true;
      await tester.pump(const Duration(seconds: 31));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
