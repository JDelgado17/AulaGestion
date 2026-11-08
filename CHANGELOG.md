# Registro de cambios

## 1.2.1 - 2026-11-08

- Aviso breve que no interrumpe cuando un aula vuelve a estar disponible o una reserva está próxima; queda sin leer en el historial.
- La alerta de aula no disponible se cierra sola si el problema desaparece mientras está abierta.
- Una alerta resuelta ya no suma como sin leer junto con su aviso.
- Con la app en segundo plano no se consulta al servidor, para no perder avisos ni gastar datos.

## 1.2.0 - 2026-11-08

- Alerta emergente cuando un aula reservada deja de estar disponible, incluso si el cambio se hizo directamente en la base de datos.
- Historial de alertas y avisos con su estado (activa, resuelta, nuevo, leído) y contador en la barra inferior.
- Las reservas afectadas indican que el aula no está disponible.
- El administrador puede ver las aulas deshabilitadas y volver a habilitarlas.
- Indicador de carga en todos los botones que esperan al servidor; los formularios permanecen abiertos hasta guardar y muestran el error sin perder lo escrito.
- El botón de actualizar ahora consulta el servidor.
- Textos completos y sin desbordes con cualquier tamaño de letra del sistema.
- Mayor tiempo de espera para que el servidor gratuito alcance a despertar.
- El inicio del profesor muestra primero su próxima reserva; el resumen numérico queda para el administrador.
- Recordatorio cuando falta menos de un día para una reserva.
- Inicio y alertas se actualizan de inmediato al guardar, sin recargar.
- Formularios explicados con ejemplos y ayudas; código de aula con formato y tipo de aula, actividad y categoría elegidos de una lista.
- Las aulas nuevas quedan con horario inicial, para que aparezcan en las búsquedas.

## 1.1.0 - 2026-11-02

- Despliegue gratuito en la nube: API en Render (Dockerfile) y MySQL en Aiven con SSL.
- La API confía en el proxy HTTPS de Render.
- El APK de release solo usa HTTPS; el tráfico HTTP queda permitido únicamente en desarrollo.
- Plantilla `.env.example` comentada y sección de configuración en el README.

## 1.0.1 - 2026-10-27

- App Android lista para instalarse como APK: permiso de Internet, tráfico HTTP en red local y nombre "AulaGestión".
- Corrección de desbordes en la barra superior con ventanas pequeñas.
- Formato del backend con Pint para cumplir el CI.

## 1.0.0 - 2026-09-07

- Autenticación Sanctum y autorización por roles.
- Gestión de usuarios, aulas, inventario, novedades, horarios y bloqueos.
- Recomendación explicable por reglas y puntuación.
- Reservas transaccionales con prevención de superposición.
- Lista y calendario semanal de reservas.
- Notificaciones internas, panel y reportes.
- Datos iniciales, pruebas, OpenAPI, colección Postman y manuales.

