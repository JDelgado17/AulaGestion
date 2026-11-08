<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use App\Services\ReservationAlertService;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function __construct(private readonly ReservationAlertService $alerts) {}

    public function index(Request $request)
    {
        $this->alerts->syncFor($request->user());

        return $this->success(
            $request->user()->appNotifications()->latest()->paginate(30)
        );
    }

    /** Consulta periódica de la app: contador de no leídas y alertas que deben saltar. */
    public function alerts(Request $request)
    {
        $user = $request->user();
        $this->alerts->syncFor($user);

        $unread = $user->appNotifications()->whereNull('read_at')->latest()->get();

        return $this->success([
            'unread_count' => $unread->count(),
            'alerts' => $unread
                ->where('type', ReservationAlertService::TYPE_UNAVAILABLE)
                ->filter(fn (AppNotification $alert) => $this->alerts->isActive($alert))
                ->values(),
            'notices' => $this->alerts->takeNotices($unread),
        ]);
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
