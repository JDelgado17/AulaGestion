<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use App\Models\Classroom;
use App\Models\Reservation;
use App\Models\User;
use App\Services\AuditService;
use App\Services\RecommendationService;
use App\Services\ReservationAlertService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReservationController extends Controller
{
    public function __construct(
        private readonly RecommendationService $recommendations,
        private readonly AuditService $audit,
        private readonly ReservationAlertService $alerts,
    ) {}

    public function index(Request $request)
    {
        $query = Reservation::with(['classroom:id,code,name,location,capacity,status,is_active', 'user:id,name,email']);

        if (! $request->user()->hasRole(User::ROLE_ADMIN)) {
            $query->where('user_id', $request->user()->id);
        }

        $reservations = $query
            ->when($request->filled('status'), fn ($builder) => $builder->where('status', $request->string('status')))
            ->when($request->filled('classroom_id'), fn ($builder) => $builder->where('classroom_id', $request->integer('classroom_id')))
            ->when($request->filled('from'), fn ($builder) => $builder->where('ends_at', '>=', $request->date('from')))
            ->when($request->filled('to'), fn ($builder) => $builder->where('starts_at', '<=', $request->date('to')))
            ->orderByDesc('starts_at')
            ->paginate(30);

        $this->alerts->annotate($reservations->getCollection());

        return $this->success($reservations);
    }

    public function store(Request $request)
    {
        $data = $this->validated($request);
        $startsAt = Carbon::parse($data['starts_at']);
        $endsAt = Carbon::parse($data['ends_at']);

        if ($startsAt->diffInMinutes($endsAt) < 30 || $startsAt->diffInMinutes($endsAt) > 480) {
            return $this->error('La reserva debe durar entre 30 minutos y 8 horas.', 422);
        }

        $result = DB::transaction(function () use ($request, $data, $startsAt, $endsAt) {
            $classroom = Classroom::with(['inventoryItems', 'schedules'])
                ->lockForUpdate()
                ->findOrFail($data['classroom_id']);

            $errors = $this->recommendations->validateClassroom(
                $classroom,
                $startsAt,
                $endsAt,
                (int) $data['attendees'],
                $data['required_resources'] ?? [],
            );

            if ($errors !== []) {
                return ['errors' => $errors];
            }

            $reservation = Reservation::create([
                ...$data,
                'user_id' => $request->user()->id,
                'status' => 'confirmed',
            ]);

            AppNotification::create([
                'user_id' => $request->user()->id,
                'title' => 'Reserva confirmada',
                'message' => "{$classroom->code} fue reservada para el {$startsAt->format('d/m/Y')} de {$startsAt->format('H:i')} a {$endsAt->format('H:i')}.",
                'type' => 'reservation_confirmed',
                'metadata' => ['reservation_id' => $reservation->id],
            ]);

            $this->audit->record($request, 'reservation.created', $reservation, null, $reservation->toArray());

            return ['reservation' => $reservation->load(['classroom', 'user:id,name,email'])];
        }, 3);

        if (isset($result['errors'])) {
            return $this->error('La reserva no pudo confirmarse porque la disponibilidad cambió.', 409, $result['errors']);
        }

        return $this->success($result['reservation'], 'Reserva confirmada correctamente.', 201);
    }

    public function show(Request $request, Reservation $reservation)
    {
        if (! $request->user()->hasRole(User::ROLE_ADMIN) && $reservation->user_id !== $request->user()->id) {
            return $this->error('No tienes permiso para consultar esta reserva.', 403);
        }

        return $this->success($reservation->load(['classroom.inventoryItems', 'user:id,name,email']));
    }

    public function cancel(Request $request, Reservation $reservation)
    {
        if (! $request->user()->hasRole(User::ROLE_ADMIN) && $reservation->user_id !== $request->user()->id) {
            return $this->error('Solo puedes cancelar tus propias reservas.', 403);
        }

        $data = $request->validate(['reason' => ['required', 'string', 'min:5', 'max:500']]);

        if ($reservation->status !== 'confirmed') {
            return $this->error('Solo se pueden cancelar reservas confirmadas.', 422);
        }
        if ($reservation->starts_at->isPast()) {
            return $this->error('No se puede cancelar una reserva que ya inició.', 422);
        }

        DB::transaction(function () use ($request, $reservation, $data) {
            $before = $reservation->toArray();
            $reservation->update([
                'status' => 'cancelled',
                'cancellation_reason' => $data['reason'],
                'cancelled_at' => now(),
            ]);

            AppNotification::create([
                'user_id' => $reservation->user_id,
                'title' => 'Reserva cancelada',
                'message' => "La reserva #{$reservation->id} fue cancelada. La franja volvió a estar disponible.",
                'type' => 'reservation_cancelled',
                'metadata' => ['reservation_id' => $reservation->id],
            ]);

            $this->audit->record($request, 'reservation.cancelled', $reservation, $before, $reservation->fresh()->toArray());
        });

        return $this->success($reservation->fresh()->load('classroom:id,code,name'), 'Reserva cancelada. La franja vuelve a estar disponible.');
    }

    private function validated(Request $request): array
    {
        return $request->validate([
            'classroom_id' => ['required', 'exists:classrooms,id'],
            'starts_at' => ['required', 'date', 'after_or_equal:now'],
            'ends_at' => ['required', 'date', 'after:starts_at'],
            'attendees' => ['required', 'integer', 'min:1', 'max:1000'],
            'activity_type' => ['required', 'string', 'max:80'],
            'required_resources' => ['sometimes', 'array', 'max:20'],
            'required_resources.*' => ['string', 'max:120'],
            'optional_resources' => ['sometimes', 'array', 'max:20'],
            'optional_resources.*' => ['string', 'max:120'],
            'purpose' => ['required', 'string', 'min:5', 'max:255'],
        ]);
    }
}
