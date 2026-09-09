import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aula_gestion/core/api_client.dart';
import 'package:aula_gestion/core/app_config.dart';
import 'package:aula_gestion/core/app_session.dart';
import 'package:aula_gestion/main.dart';
import 'package:aula_gestion/repositories/auth_repository.dart';
import 'package:aula_gestion/repositories/school_repository.dart';

void main() {
  testWidgets('AulaGestion inicia correctamente', (WidgetTester tester) async {
    final client = ApiClient(baseUrl: AppConfig.apiBaseUrl);
    final session = AppSession(AuthRepository(client));
    final repository = SchoolRepository(client);

    await tester.pumpWidget(
      AulaGestionApp(
        session: session,
        repository: repository,
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);

    final materialApp = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );

    expect(materialApp.title, AppConfig.appName);
    expect(materialApp.debugShowCheckedModeBanner, isFalse);
  });
}
