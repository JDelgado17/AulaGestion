# Plan de pruebas y evidencias

## Uso

Ejecute primero las pruebas automatizadas y después los doce casos de aceptación. Guarde capturas en una carpeta `evidencias/` del repositorio con nombres como `CA01_login_profesor.png`.

> Versión 1.2.1. La integración continua de GitHub Actions ejecuta estas pruebas en cada push o pull request hacia `main` y `develop`.

## Pruebas automatizadas

| Archivo | Verificación |
| --- | --- |
| `backend/tests/Feature/AuthTest.php` | Acceso correcto, token, rol y rechazo de cuenta deshabilitada. |
| `backend/tests/Feature/RecommendationTest.php` | Exclusión de aula sin recurso obligatorio. |
| `backend/tests/Feature/ReservationConflictTest.php` | Rechazo HTTP 409 y ausencia de segundo registro superpuesto. |
| `backend/tests/Feature/ClassroomRegistrationTest.php` | Aula nueva visible en búsquedas, formato del código, tipo del catálogo y afinidad con la actividad (5 casos). |
| `backend/tests/Feature/ReservationAlertTest.php` | Ciclo de alertas: creación sin duplicados, cambios directos en la base de datos, resolución, avisos, recordatorio y aislamiento entre usuarios (12 casos). |
| `mobile/test/domain_models_test.dart` | Conversión segura de JSON de aula, inventario y recomendación. |
| `mobile/test/ui_behavior_test.dart` | Pantallas sin desbordes en varios anchos y tamaños de letra, indicadores de carga, errores dentro del formulario, inicio por rol, alertas y avisos, pausa en segundo plano. |

Comandos:

```bash
cd backend
php artisan test

cd ../mobile
flutter analyze
flutter test
```

## Casos de aceptación manual

| Código | Precondición | Pasos resumidos | Resultado esperado | Evidencia |
| --- | --- | --- | --- | --- |
| CA-01 | Seeders ejecutados | Iniciar sesión con los tres usuarios | Cada rol ve solo sus módulos | Captura de cada menú |
| CA-02 | Sesión admin | Crear aula D-201, capacidad 32 | Aula visible con ubicación, tipo y estado | Formulario y lista |
| CA-03 | Sesión inventario | Agregar videobeam a D-201 y actualizar cantidad | Recurso actualizado | Tarjeta de inventario |
| CA-04 | Aula ocupada/bloqueada | Buscar la franja en conflicto | El aula no aparece como coincidencia | Resultado de búsqueda |
| CA-05 | Varias aulas válidas | Buscar 25 estudiantes + videobeam | Resultados ordenados con porcentaje y razones | Pantalla de recomendaciones |
| CA-06 | Reserva confirmada | Repetir la misma franja y aula | Respuesta de conflicto; no hay duplicado | Respuesta Postman y BD |
| CA-07 | Reserva futura | Cancelar con un motivo y volver a buscar | Estado cancelado y franja disponible | Antes/después |
| CA-08 | Elemento existente | Registrar daño y revisar historial | Usuario, fecha y descripción conservados | Historial de novedades |
| CA-09 | App abierta | Detener Laravel y actualizar una lista | Mensaje de red sin cierre inesperado | Mensaje visible |
| CA-10 | APK 1.2.1 instalado | Iniciar sesión contra la API pública en Render | La app funciona con datos móviles o cualquier Wi-Fi | Pantalla de inicio |
| CA-11 | Reserva futura confirmada | Poner el aula en mantenimiento y luego habilitarla | Alerta emergente; al habilitar se resuelve y llega el aviso | Alerta e historial |
| CA-12 | Reserva en menos de 24 h | Abrir la app | Aviso «Tu reserva es pronto» una sola vez | Aviso visible |

## Prueba de permisos

Compruebe en Postman:

- un profesor recibe HTTP 403 al crear usuarios;
- inventario recibe HTTP 403 al crear horarios;
- un profesor no puede consultar la reserva de otro;
- inventario sí puede consultar el reporte de inventario;
- una cuenta deshabilitada pierde sus tokens.

## Prueba de límites

- Cero estudiantes: HTTP 422.
- Capacidad superior a 1000: HTTP 422.
- Hora final anterior o igual a la inicial: HTTP 422.
- Reserva de menos de 30 minutos: HTTP 422.
- Reserva mayor de 8 horas: HTTP 422.
- Cantidad disponible mayor que la cantidad total: HTTP 422.
- Motivo de cancelación menor de 5 caracteres: HTTP 422.

## Correcciones preventivas incorporadas

1. Se normalizan correos y nombres de recursos para evitar diferencias por mayúsculas.
2. La disponibilidad se revalida dentro de la transacción de confirmación.
3. Se bloquea la fila del aula para serializar reservas concurrentes sobre el mismo espacio.
4. La cancelación no elimina registros y exige motivo.
5. Los cambios de inventario se limitan entre cero y la cantidad total.
6. Las rutas administrativas se protegen también en el servidor.
7. Los tokens tienen vencimiento y se revocan al cerrar sesión o deshabilitar la cuenta.
8. Las respuestas de validación mantienen un formato JSON uniforme.

## Formato de acta de ejecución

| Fecha | Versión | Responsable | Backend | Flutter analyze | Flutter test | Casos manuales | Observaciones |
| --- | --- | --- | --- | --- | --- | --- | --- |
| ____ | 1.2.1 | ____ | ____/21 | Aprobado/Pendiente | ____/____ | ____/12 | ____ |
