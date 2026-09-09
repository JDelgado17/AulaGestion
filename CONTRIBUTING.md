# Guía de contribución

## Ramas

- `main`: versión estable.
- `develop`: integración del Sprint.
- `feature/RFXX-descripcion`: una historia o módulo.
- `fix/descripcion`: corrección puntual.

## Antes de abrir un pull request

1. Actualizar la rama desde `develop`.
2. No incluir `.env`, secretos ni archivos generados.
3. Ejecutar `vendor/bin/pint` en backend.
4. Ejecutar `php artisan test`.
5. Ejecutar `dart format lib test`, `flutter analyze` y `flutter test`.
6. Actualizar documentación si cambia una ruta, regla o pantalla.
7. Describir el requerimiento y la evidencia de prueba.

## Definición de terminado

- Cumple criterios de aceptación.
- Valida datos en Flutter y Laravel.
- Respeta permisos por rol.
- No introduce cruces de reserva ni inconsistencias.
- Incluye mensajes comprensibles.
- Tiene pruebas y revisión de otro integrante.
- Está integrada en `develop` y aceptada por Product Owner.

