import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/api_client.dart';
import 'core/app_config.dart';
import 'core/app_session.dart';
import 'core/app_theme.dart';
import 'repositories/auth_repository.dart';
import 'repositories/school_repository.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  final client = ApiClient(baseUrl: AppConfig.apiBaseUrl);
  final session = AppSession(AuthRepository(client));
  final schoolRepository = SchoolRepository(client);
  await session.initialize();
  runApp(AulaGestionApp(session: session, repository: schoolRepository));
}

class AulaGestionApp extends StatelessWidget {
  const AulaGestionApp(
      {required this.session, required this.repository, super.key});

  final AppSession session;
  final SchoolRepository repository;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      session: session,
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('es', 'CO'),
        supportedLocales: const [Locale('es', 'CO'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: ListenableBuilder(
          listenable: session,
          builder: (context, _) {
            if (session.isInitializing) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }
            if (!session.isAuthenticated) return const LoginScreen();
            return MainShell(repository: repository);
          },
        ),
      ),
    );
  }
}
