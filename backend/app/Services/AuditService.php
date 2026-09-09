<?php

namespace App\Services;

use App\Models\AuditLog;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;

class AuditService
{
    public function record(
        Request $request,
        string $action,
        Model $subject,
        ?array $before = null,
        ?array $after = null,
    ): void {
        AuditLog::create([
            'user_id' => $request->user()?->id,
            'action' => $action,
            'auditable_type' => $subject::class,
            'auditable_id' => $subject->getKey(),
            'before_data' => $before,
            'after_data' => $after,
            'ip_address' => $request->ip(),
            'created_at' => now(),
        ]);
    }
}

