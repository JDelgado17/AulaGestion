abstract final class AppConfig {
  static const appName = 'AulaGestión';
  static const institutionName = 'Institución Educativa';
  static const institutionShortName = 'IE';
  static const supportEmail = 'soporte@institucion.edu.co';
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );
}

