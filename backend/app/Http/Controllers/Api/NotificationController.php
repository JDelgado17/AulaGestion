<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        return $this->success(
            $request->user()->appNotifications()->latest()->paginate(30)
        );
    }

    public function markRead(Request $request, AppNotification $notification)
    {
        if ($notification->user_id !== $request->user()->id) {
            return $this->error('No tienes permiso para modificar esta notificación.', 403);
        }

        $notification->update(['read_at' => now()]);

        return $this->success($notification, 'Notificación marcada como leída.');
    }

    public function markAllRead(Request $request)
    {
        $request->user()->appNotifications()->whereNull('read_at')->update(['read_at' => now()]);

        return $this->success(null, 'Notificaciones actualizadas.');
    }
}
