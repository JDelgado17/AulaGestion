<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class InventoryItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'classroom_id', 'name', 'category', 'quantity', 'available_quantity', 'status', 'description',
    ];

    protected function casts(): array
    {
        return ['quantity' => 'integer', 'available_quantity' => 'integer'];
    }

    public function classroom(): BelongsTo
    {
        return $this->belongsTo(Classroom::class);
    }

    public function events(): HasMany
    {
        return $this->hasMany(InventoryEvent::class);
    }
}
