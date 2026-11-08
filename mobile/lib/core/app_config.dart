abstract final class AppConfig {
  static const appName = 'AulaGestión';
  static const appVersion = '1.2.0';

  /// Tope del tamaño de letra del sistema para el que está diseñada la app.
  static const maxTextScale = 1.6;
  static const institutionName = 'Institución Educativa';
  static const institutionShortName = 'IE';
  static const supportEmail = 'soporte@institucion.edu.co';
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );
}
