<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class InventoryEvent extends Model
{
    use HasFactory;

    protected $fillable = [
        'inventory_item_id', 'classroom_id', 'user_id', 'type', 'quantity_delta', 'description', 'occurred_at',
    ];

    protected function casts(): array
    {
        return ['quantity_delta' => 'integer', 'occurred_at' => 'datetime'];
    }

    public function item(): BelongsTo
    {
        return $this->belongsTo(InventoryItem::class, 'inventory_item_id');
    }

    public function classroom(): BelongsTo
    {
        return $this->belongsTo(Classroom::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}

