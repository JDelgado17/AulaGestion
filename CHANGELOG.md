# Registro de cambios

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

