<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Classroom;
use App\Models\InventoryItem;
use App\Models\Reservation;
use App\Models\User;
use App\Services\ReservationAlertService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    public function summary(Request $request)
    {
        $from = $request->filled('from') ? Carbon::parse((string) $request->string('from')) : now()->startOfMonth();
        $to = $request->filled('to') ? Carbon::parse((string) $request->string('to')) : now()->endOfMonth();

        $reservationBase = Reservation::query()
            ->whereBetween('starts_at', [$from, $to])
            ->where('status', 'confirmed');

        $topRooms = (clone $reservationBase)
            ->select('classroom_id', DB::raw('COUNT(*) as reservations_count'), DB::raw('SUM(TIMESTAMPDIFF(MINUTE, starts_at, ends_at)) as reserved_minutes'))
            ->groupBy('classroom_id')
            ->orderByDesc('reservations_count')
            ->with('classroom:id,code,name,capacity')
            ->limit(8)
            ->get();

        $inventoryByStatus = InventoryItem::query()
            ->select('status', DB::raw('COUNT(*) as item_types'), DB::raw('SUM(quantity) as units'))
            ->groupBy('status')
            ->get();

        return $this->success([
            'period' => ['from' => $from->toDateString(), 'to' => $to->toDateString()],
            'indicators' => [
                'active_users' => User::where('is_active', true)->count(),
                'active_classrooms' => Classroom::where('is_active', true)->count(),
                'confirmed_reservations' => (clone $reservationBase)->count(),
                'inventory_units' => InventoryItem::sum('quantity'),
                'inventory_alerts' => InventoryItem::whereIn('status', ['maintenance', 'damaged', 'out_of_service'])->count(),
            ],
            'top_classrooms' => $topRooms,
            'inventory_by_status' => $inventoryByStatus,
        ]);
    }

    public function dashboard(Request $request, ReservationAlertService $alerts)
    {
        $user = $request->user();
        $alerts->syncFor($user);

        $nextReservations = Reservation::with('classroom:id,code,name,location,capacity,status,is_active')
            ->where('user_id', $user->id)
            ->where('status', 'confirmed')
            ->where('ends_at', '>', now())
            ->orderBy('starts_at')
            ->limit(3)
            ->get();
        $alerts->annotate($nextReservations);

        $baseReservations = Reservation::query();
        if (! $user->hasRole(User::ROLE_ADMIN)) {
            $baseReservations->where('user_id', $user->id);
        }

        return $this->success([
            'classrooms_available' => Classroom::where('is_active', true)->where('status', 'available')->count(),
            'classrooms_attention' => Classroom::where('is_active', true)->whereIn('status', ['maintenance', 'out_of_service'])->count(),
            'reservations_today' => (clone $baseReservations)->whereDate('starts_at', today())->where('status', 'confirmed')->count(),
            'upcoming_reservations' => (clone $baseReservations)->where('starts_at', '>=', now())->where('status', 'confirmed')->count(),
            'inventory_alerts' => InventoryItem::whereIn('status', ['maintenance', 'damaged', 'out_of_service'])->count(),
            'unread_notifications' => $user->appNotifications()->whereNull('read_at')->count(),
            'active_alerts' => $user->appNotifications()->where('type', ReservationAlertService::TYPE_UNAVAILABLE)->get()
                ->filter(fn ($alert) => $alerts->isActive($alert))->count(),
            'next_reservations' => $nextReservations,
        ]);
    }
}
