# AulaGestión

Aplicativo móvil para gestionar inventario, buscar, recomendar y reservar aulas de una institución educativa. El repositorio implementa los 12 requerimientos funcionales consolidados del proyecto académico mediante una arquitectura cliente-servidor.

## Entregables incluidos

- `mobile/`: aplicación Flutter con Material 3, navegación y permisos por rol.
- `backend/`: API REST Laravel 13 con Sanctum, validaciones, auditoría y MySQL.
- `docs/`: arquitectura, endpoints, manual de instalación, manual de usuario y matriz de trazabilidad.
- `postman/`: colección y entorno para probar la API.
- `docker-compose.yml`: MySQL y phpMyAdmin para desarrollo local.

## Arquitectura

```mermaid
flowchart LR
    A["Flutter Android"] -->|"HTTPS / JSON + Bearer token"| B["API REST Laravel 13"]
    B --> C["Servicios de dominio"]
    C --> D[("MySQL 8")]
    C --> E["Auditoría y notificaciones"]
```

## Requisitos

- Flutter estable 3.35 o superior y Android Studio.
- PHP 8.3 o superior y Composer 2.
- MySQL 8, o Docker Desktop para iniciar la base de datos.
- Git.

## Inicio rápido

### 1. Base de datos

Desde la raíz:

```bash
docker compose up -d
```

Esto inicia MySQL en `127.0.0.1:3307` y phpMyAdmin en `http://localhost:8081`.

### 2. API Laravel

```bash
cd backend
cp .env.example .env
composer install
php artisan key:generate
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8000
```

Comprueba la API en `http://127.0.0.1:8000/api/health`.

### 3. Aplicación Flutter

En otra terminal:

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

`10.0.2.2` permite que el emulador Android acceda al servidor del computador. En un dispositivo físico, reemplázalo por la IP local del computador, por ejemplo `http://192.168.1.20:8000/api`.

## Configuración (.env)

El archivo `backend/.env` **no se sube a GitHub** porque contiene contraseñas y la llave de cifrado (está en `.gitignore`). En su lugar se publica la plantilla [`backend/.env.example`](backend/.env.example), con un comentario por variable. Para crear el `.env` local:

```bash
cd backend
cp .env.example .env
php artisan key:generate
```

En producción no existe un archivo `.env`: las mismas variables se definen en el panel **Environment** de Render.

## Despliegue en la nube (Render + Aiven)

La API corre gratis en [Render](https://render.com) con el `backend/Dockerfile`, y la base MySQL en [Aiven](https://aiven.io) (plan Free).

1. En Aiven, crear un servicio MySQL Free y descargar su certificado `ca.pem`.
2. En Render, crear un **Web Service** desde este repositorio: Root Directory `backend`, Runtime Docker, plan Free.
3. En **Environment**, definir `APP_ENV=production`, `APP_DEBUG=false`, `APP_KEY`, `LOG_CHANNEL=stderr`, `DB_*` (datos de Aiven), `MYSQL_ATTR_SSL_CA=/etc/secrets/ca.pem` y, solo en el primer despliegue, `SEED_DEMO=true`.
4. En **Secret Files**, subir `ca.pem`.
5. Generar el APK apuntando a la URL pública:

```bash
cd mobile
flutter build apk --release --dart-define=API_BASE_URL=https://<servicio>.onrender.com/api
```

El plan gratuito de Render suspende la API tras 15 minutos sin uso; la primera petición posterior tarda cerca de un minuto.

## Usuarios de demostración

Los crea `DatabaseSeeder`; no corresponden a personas reales.

| Rol | Correo | Contraseña |
| --- | --- | --- |
| Administrador | `admin@demo.edu.co` | `Demo2026*` |
| Profesor | `profesor@demo.edu.co` | `Demo2026*` |
| Inventario | `inventario@demo.edu.co` | `Demo2026*` |

Cambie estas claves antes de desplegar el sistema.

## Pruebas

```bash
cd backend
php artisan test

cd ../mobile
flutter analyze
flutter test
```

## Personalización institucional

Modifique `mobile/lib/core/app_config.dart` para cambiar nombre, sigla, textos y datos de contacto. La paleta se encuentra en `mobile/lib/core/app_theme.dart`.

## Seguridad

- Contraseñas almacenadas con hash por Laravel.
- Tokens Sanctum guardados en almacenamiento seguro del dispositivo.
- Autorización por roles en servidor y cliente.
- Validación del servidor para todos los datos críticos.
- Transacciones y bloqueos para evitar reservas superpuestas.
- Registro de auditoría para reservas e inventario.
- No se incluyen secretos ni credenciales reales.

## Equipo Scrum

- María Alejandra Vallejo Zamora: Product Owner.
- Juan David Delgado Muñoz: Scrum Master e integración.
- Julián Andrés Ceballos Eraso: backend, datos y reglas de negocio.
- David Esteban Ortiz Ortiz: Flutter, interfaces y experiencia de usuario.

La guía completa está en `docs/GUIA_TECNICA_Y_USUARIO.md`.
