# Imagen de producción de la API para Render (plan gratuito).
FROM php:8.4-cli

RUN apt-get update \
    && apt-get install -y --no-install-recommends unzip libzip-dev \
    && docker-php-ext-install pdo_mysql zip \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app
COPY . .

RUN composer install --no-dev --optimize-autoloader --no-interaction --no-progress \
    && chmod -R ug+rwX storage bootstrap/cache

# Varios procesos para atender peticiones en paralelo con `artisan serve`.
ENV PHP_CLI_SERVER_WORKERS=4

# Aplica las migraciones en cada arranque. Con SEED_DEMO=true carga además los
# datos de demostración (si ya existen, el seeder falla y se ignora).
CMD ["sh", "-c", "php artisan migrate --force && if [ \"$SEED_DEMO\" = \"true\" ]; then php artisan db:seed --force || true; fi && php artisan serve --host=0.0.0.0 --port=${PORT:-8000}"]
