<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ClassroomSchedule extends Model
{
    use HasFactory;

    protected $fillable = ['classroom_id', 'weekday', 'start_time', 'end_time', 'is_active'];

    protected function casts(): array
    {
        return ['weekday' => 'integer', 'is_active' => 'boolean'];
    }

    public function classroom(): BelongsTo
    {
        return $this->belongsTo(Classroom::class);
    }
}
