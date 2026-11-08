<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Classroom extends Model
{
    use HasFactory;

    /** Debe coincidir con el catálogo de la app (mobile/lib/core/catalogs.dart). */
    public const TYPES = [
        'Clase interactiva', 'Multimedia', 'Informática', 'Laboratorio', 'Actividad lúdica', 'Auditorio',
    ];

    protected $fillable = [
        'code', 'name', 'location', 'capacity', 'type', 'description', 'status', 'is_active',
    ];

    protected function casts(): array
    {
        return ['capacity' => 'integer', 'is_active' => 'boolean'];
    }

    public function inventoryItems(): HasMany
    {
        return $this->hasMany(InventoryItem::class);
    }

    public function schedules(): HasMany
    {
        return $this->hasMany(ClassroomSchedule::class);
    }

    public function blocks(): HasMany
    {
        return $this->hasMany(ClassroomBlock::class);
    }

    public function reservations(): HasMany
    {
        return $this->hasMany(Reservation::class);
    }
}
