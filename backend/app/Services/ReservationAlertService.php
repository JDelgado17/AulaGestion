<?php

namespace App\Services;

use App\Models\AppNotification;
use App\Models\ClassroomBlock;
use App\Models\Reservation;
use App\Models\User;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

/**
 * Compara las reservas vigentes con el estado real de las aulas. Se calcula al
 * consultar y no al editar el aula, para detectar también los cambios hechos
 * directamente en la base de datos.
 */
class ReservationAlertService
{
    public const TYPE_UNAVAILABLE = 'classroom_unavailable';

    public const TYPE_RESTORED = 'classroom_restored';

    public const TYPE_REMINDER = 'reservation_reminder';

    public const STATE_ACTIVE = 'active';

    public const STATE_RESOLVED = 'resolved';

    public function syncFor(User $user): void
    {
        DB::transaction(function () use ($user) {
            // Evita alertas duplicadas si llegan dos consultas al mismo tiempo.
            User::whereKey($user->id)->lockForUpdate()->first();

            $openAlerts = $user->appNotifications()
                ->where('type', self::TYPE_UNAVAILABLE)
                ->get()
                ->filter(fn (AppNotification $alert) => $this->isActive($alert))
                ->keyBy(fn (AppNotification $alert) => $alert->metadata['reservation_id'] ?? 0);

            $reservations = Reservation::with('classroom')
                ->where('user_id', $user->id)
                ->where('status', 'confirmed')
                ->where('ends_at', '>', now())
                ->get();
            $blocks = $this->blocksFor($reservations);
            $reminded = $user->appNotifications()
                ->where('type', self::TYPE_REMINDER)
                ->get()
                ->pluck('metadata.reservation_id');

            foreach ($reservations as $reservation) {
                $issue = $this->issueFor($reservation, $blocks);

                if ($issue === null && ! $reminded->contains($reservation->id) && $this->isDueForReminder($reservation)) {
                    $this->notifyReminder($reservation);
                }

                $alert = $openAlerts->pull($reservation->id);

                if ($issue !== null && $alert === null) {
                    $this->createAlert($reservation, $issue);
                }
                if ($issue === null && $alert !== null) {
                    $this->resolve($alert);
                    $this->notifyRestored($reservation);
                }
            }

            // Las alertas restantes son de reservas canceladas o ya finalizadas.
            $openAlerts->each(fn (AppNotification $alert) => $this->resolve($alert));
        });
    }

    /** Agrega `availability_issue` a cada reserva vigente para mostrarlo en la app. */
    public function annotate(Collection $reservations): void
    {
        $blocks = $this->blocksFor($reservations);

        foreach ($reservations as $reservation) {
            $isCurrent = $reservation->status === 'confirmed' && $reservation->ends_at->isFuture();
            $reservation->setAttribute('availability_issue', $isCurrent ? $this->issueFor($reservation, $blocks) : null);
        }
    }

    public function isActive(AppNotification $alert): bool
    {
        return ($alert->metadata['alert_state'] ?? null) === self::STATE_ACTIVE;
    }

    private function issueFor(Reservation $reservation, Collection $blocks): ?string
    {
        $room = $reservation->classroom;

        if (! $room->is_active) {
            return 'el aula fue deshabilitada';
        }
        if ($room->status === 'maintenance') {
            return 'el aula está en mantenimiento';
        }
        if ($room->status === 'out_of_service') {
            return 'el aula está fuera de servicio';
        }

        $block = $blocks->first(fn (ClassroomBlock $block) => $block->classroom_id === $room->id
            && $block->starts_at->lt($reservation->ends_at)
            && $block->ends_at->gt($reservation->starts_at));

        return $block ? "el aula fue bloqueada: {$block->reason}" : null;
    }

    private function blocksFor(Collection $reservations): Collection
    {
        return ClassroomBlock::whereIn('classroom_id', $reservations->pluck('classroom_id')->unique())
            ->where('ends_at', '>', now())
            ->get();
    }

    private function createAlert(Reservation $reservation, string $issue): void
    {
        AppNotification::create([
            'user_id' => $reservation->user_id,
            'title' => 'Aula no disponible',
            'message' => "Tu reserva de {$reservation->classroom->code} del {$this->schedule($reservation)} se ve afectada: {$issue}. Cancélala o busca otra aula.",
            'type' => self::TYPE_UNAVAILABLE,
            'metadata' => [
                'reservation_id' => $reservation->id,
                'classroom_id' => $reservation->classroom_id,
                'alert_state' => self::STATE_ACTIVE,
            ],
        ]);
    }

    private function notifyRestored(Reservation $reservation): void
    {
        AppNotification::create([
            'user_id' => $reservation->user_id,
            'title' => 'Aula disponible de nuevo',
            'message' => "{$reservation->classroom->code} volvió a estar disponible y tu reserva del {$this->schedule($reservation)} sigue confirmada.",
            'type' => self::TYPE_RESTORED,
            'metadata' => ['reservation_id' => $reservation->id, 'classroom_id' => $reservation->classroom_id],
        ]);
    }

    /** Menos de un día para empezar, sin repetir lo que se acaba de confirmar al reservar. */
    private function isDueForReminder(Reservation $reservation): bool
    {
        return $reservation->starts_at->isFuture()
            && $reservation->starts_at->lte(now()->addDay())
            && $reservation->created_at->lte(now()->subHour());
    }

    private function notifyReminder(Reservation $reservation): void
    {
        AppNotification::create([
            'user_id' => $reservation->user_id,
            'title' => 'Tu reserva es pronto',
            'message' => "Tienes {$reservation->classroom->code} reservada el {$this->schedule($reservation)}.",
            'type' => self::TYPE_REMINDER,
            'metadata' => ['reservation_id' => $reservation->id, 'classroom_id' => $reservation->classroom_id],
        ]);
    }

    private function resolve(AppNotification $alert): void
    {
        $alert->update([
            'metadata' => [...$alert->metadata, 'alert_state' => self::STATE_RESOLVED, 'resolved_at' => now()->toIso8601String()],
        ]);
    }

    private function schedule(Reservation $reservation): string
    {
        return "{$reservation->starts_at->format('d/m/Y')} de {$reservation->starts_at->format('H:i')} a {$reservation->ends_at->format('H:i')}";
    }
}
