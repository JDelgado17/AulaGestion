<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Servicios registrados mediante resolución automática del contenedor.
    }

    public function boot(): void
    {
        // Punto de extensión para políticas institucionales futuras.
    }
}
