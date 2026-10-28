<?php

use Illuminate\Support\Facades\Artisan;

Artisan::command('aula:info', function () {
    $this->info('AulaGestión API lista para operar.');
})->purpose('Muestra el estado básico del proyecto');
