/// Opciones cerradas de los formularios. El sistema compara estos valores entre
/// sí, por lo que no pueden quedar a criterio de quien escribe.
abstract final class Catalogs {
  /// Debe coincidir con `Classroom::TYPES` de la API.
  static const classroomTypes = {
    'Clase interactiva': 'Clases y talleres con mesas o sillas móviles',
    'Multimedia': 'Presentaciones y video con equipos audiovisuales',
    'Informática': 'Actividades con un computador por persona',
    'Laboratorio': 'Prácticas con mesones y equipos especializados',
    'Actividad lúdica': 'Juegos y dinámicas con espacio libre',
    'Auditorio': 'Eventos y charlas con muchos asistentes',
  };

  /// Debe coincidir con `RecommendationService::ACTIVITY_ROOM_TYPES` de la API.
  static const activities = [
    'Clase',
    'Taller',
    'Presentación o video',
    'Trabajo en computadores',
    'Práctica de laboratorio',
    'Actividad lúdica',
    'Reunión o evento',
  ];

  /// Nombres que usa el buscador: un elemento solo cuenta como recurso del aula
  /// si se registra con el mismo nombre.
  static const searchableResources = [
    'Videobeam',
    'Televisor',
    'Computador',
    'Parlantes',
    'Aire acondicionado',
    'Tablero acrílico',
    'Microscopio',
  ];

  static const inventoryCategories = [
    'Tecnología',
    'Mobiliario',
    'Infraestructura',
    'Laboratorio',
    'Seguridad',
  ];

  static const roleDescriptions = {
    'admin': 'Administra usuarios, aulas, horarios y reportes.',
    'professor': 'Busca, reserva y cancela aulas.',
    'inventory': 'Registra los elementos de cada aula y sus novedades.',
  };
}
