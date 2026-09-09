import 'package:aula_gestion/models/domain_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('interpreta un aula y su inventario desde JSON', () {
    final room = Classroom.fromJson({
      'id': 1,
      'code': 'A-101',
      'name': 'Aula Interactiva',
      'location': 'Bloque A',
      'capacity': 30,
      'type': 'Clase',
      'status': 'available',
      'is_active': true,
      'inventory_items': [
        {
          'id': 2,
          'classroom_id': 1,
          'name': 'Videobeam',
          'category': 'Tecnología',
          'quantity': 1,
          'available_quantity': 1,
          'status': 'available',
        },
      ],
    });

    expect(room.code, 'A-101');
    expect(room.capacity, 30);
    expect(room.inventory.single.name, 'Videobeam');
  });

  test('interpreta la puntuación explicable de una recomendación', () {
    final recommendation = RoomRecommendation.fromJson({
      'classroom': {
        'id': 1,
        'code': 'A-101',
        'name': 'Aula Interactiva',
        'location': 'Bloque A',
        'capacity': 30,
        'type': 'Clase',
        'status': 'available',
        'is_active': true,
      },
      'match_percent': 96,
      'match_level': 'Alta',
      'is_exact_match': true,
      'reasons': ['Incluye todos los recursos obligatorios'],
      'missing_resources': [],
    });

    expect(recommendation.isExactMatch, isTrue);
    expect(recommendation.matchPercent, 96);
  });
}
