# Plan de pruebas y evidencias

## Uso

Ejecute primero las pruebas automatizadas y después los diez casos de aceptación. Guarde capturas en una carpeta `evidencias/` del repositorio con nombres como `CA01_login_profesor.png`.

> Estado inicial: los casos automatizados están implementados. La ejecución debe realizarse en un equipo con PHP 8.3, Composer y Flutter instalados.

## Pruebas automatizadas

| Archivo | Verificación |
| --- | --- |
| `backend/tests/Feature/AuthTest.php` | Acceso correcto, token, rol y rechazo de cuenta deshabilitada. |
| `backend/tests/Feature/RecommendationTest.php` | Exclusión de aula sin recurso obligatorio. |
| `backend/tests/Feature/ReservationConflictTest.php` | Rechazo HTTP 409 y ausencia de segundo registro superpuesto. |
| `mobile/test/domain_models_test.dart` | Conversión segura de JSON de aula, inventario y recomendación. |

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
| CA-10 | Repositorio limpio | Seguir README desde una copia nueva | API, BD y app se ejecutan | Terminales y pantalla login |

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
| ____ | 1.0.0 | ____ | ____/____ | Aprobado/Pendiente | ____/____ | ____/10 | ____ |
