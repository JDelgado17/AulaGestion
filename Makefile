.PHONY: install backend-install mobile-install database test format

install: backend-install mobile-install

backend-install:
	cd backend && composer install && cp -n .env.example .env || true && php artisan key:generate

mobile-install:
	cd mobile && flutter pub get

database:
	docker compose up -d && cd backend && php artisan migrate:fresh --seed

test:
	cd backend && php artisan test
	cd mobile && flutter analyze && flutter test

format:
	cd backend && vendor/bin/pint
	cd mobile && dart format lib test
