<?php

namespace App\Services;

use App\Models\Classroom;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Collection;

class RecommendationService
{
    public function recommend(array $criteria): array
    {
        $startsAt = Carbon::parse($criteria['starts_at']);
        $endsAt = Carbon::parse($criteria['ends_at']);
        $required = $this->normalizeResources($criteria['required_resources'] ?? []);
        $optional = $this->normalizeResources($criteria['optional_resources'] ?? []);

        $available = $this->availableClassrooms(
            $startsAt,
            $endsAt,
            (int) $criteria['attendees'],
        )->get();

        $ranked = $available
            ->map(fn (Classroom $room) => $this->score($room, (int) $criteria['attendees'], $required, $optional, $criteria['activity_type']))
            ->sortByDesc('match_percent')
            ->values();

        $exact = $ranked->filter(fn (array $item) => $item['is_exact_match'])->values();

        return [
            'criteria' => [
                ...$criteria,
                'starts_at' => $startsAt->toIso8601String(),
                'ends_at' => $endsAt->toIso8601String(),
            ],
            'recommendations' => $exact,
            'alternatives' => $exact->isEmpty() ? $ranked->take(5)->values() : collect(),
            'alternative_times' => $exact->isEmpty()
                ? $this->findAlternativeTimes($criteria, $startsAt, $endsAt, $required)
                : [],
            'summary' => [
                'available_before_resources' => $available->count(),
                'exact_matches' => $exact->count(),
            ],
        ];
    }

    public function validateClassroom(
        Classroom $classroom,
        Carbon $startsAt,
        Carbon $endsAt,
        int $attendees,
        array $requiredResources,
        ?int $excludeReservationId = null,
    ): array {
        $errors = [];

        if (! $classroom->is_active || $classroom->status !== 'available') {
            $errors[] = 'El aula no se encuentra habilitada.';
        }

        if ($classroom->capacity < $attendees) {
            $errors[] = 'La capacidad del aula es inferior a la cantidad de asistentes.';
        }

        if (! $this->isWithinSchedule($classroom, $startsAt, $endsAt)) {
            $errors[] = 'La franja está fuera del horario institucional configurado.';
        }

        if ($classroom->blocks()->where('starts_at', '<', $endsAt)->where('ends_at', '>', $startsAt)->exists()) {
            $errors[] = 'El aula tiene un bloqueo institucional en esa franja.';
        }

        $overlap = $classroom->reservations()
            ->where('status', 'confirmed')
            ->when($excludeReservationId, fn (Builder $query) => $query->where('id', '!=', $excludeReservationId))
            ->where('starts_at', '<', $endsAt)
            ->where('ends_at', '>', $startsAt)
            ->exists();

        if ($overlap) {
            $errors[] = 'Ya existe una reserva que se superpone con la franja solicitada.';
        }

        $resourceNames = $this->functionalResourceNames($classroom);
        $missing = array_values(array_diff($this->normalizeResources($requiredResources), $resourceNames));
        if ($missing !== []) {
            $errors[] = 'Faltan recursos obligatorios funcionales: '.implode(', ', $missing).'.';
        }

        return $errors;
    }

    private function availableClassrooms(Carbon $startsAt, Carbon $endsAt, int $attendees): Builder
    {
        $weekday = $startsAt->isoWeekday();
        $startTime = $startsAt->format('H:i:s');
        $endTime = $endsAt->format('H:i:s');

        return Classroom::query()
            ->with(['inventoryItems' => fn ($query) => $query->orderBy('name')])
            ->where('is_active', true)
            ->where('status', 'available')
            ->where('capacity', '>=', $attendees)
            ->whereHas('schedules', fn (Builder $query) => $query
                ->where('is_active', true)
                ->where('weekday', $weekday)
                ->where('start_time', '<=', $startTime)
                ->where('end_time', '>=', $endTime))
            ->whereDoesntHave('blocks', fn (Builder $query) => $query
                ->where('starts_at', '<', $endsAt)
                ->where('ends_at', '>', $startsAt))
            ->whereDoesntHave('reservations', fn (Builder $query) => $query
                ->where('status', 'confirmed')
                ->where('starts_at', '<', $endsAt)
                ->where('ends_at', '>', $startsAt));
    }

    private function score(Classroom $room, int $attendees, array $required, array $optional, string $activityType): array
    {
        $functional = $this->functionalResourceNames($room);
        $missingRequired = array_values(array_diff($required, $functional));
        $presentOptional = array_values(array_intersect($optional, $functional));
        $capacityGap = max(0, $room->capacity - $attendees);

        $score = 55;
        $score += max(0, 25 - min(25, (int) round($capacityGap / 2)));
        $score += $required === [] ? 10 : (int) round(10 * (count($required) - count($missingRequired)) / count($required));
        $score += $optional === [] ? 5 : (int) round(5 * count($presentOptional) / count($optional));
        $score += mb_stripos($room->type, $activityType) !== false ? 5 : 0;
        $score = max(0, min(100, $score - count($missingRequired) * 20));

        $reasons = [
            "Capacidad para {$room->capacity} personas ({$capacityGap} cupos libres)",
            'Disponible durante toda la franja solicitada',
        ];

        if ($required !== [] && $missingRequired === []) {
            $reasons[] = 'Incluye todos los recursos obligatorios';
        }
        if ($presentOptional !== []) {
            $reasons[] = 'Recursos opcionales: '.implode(', ', $presentOptional);
        }

        return [
            'classroom' => $room,
            'match_percent' => $score,
            'match_level' => $score >= 90 ? 'Alta' : ($score >= 70 ? 'Media' : 'Baja'),
            'is_exact_match' => $missingRequired === [],
            'reasons' => $reasons,
            'missing_resources' => $missingRequired,
        ];
    }

    private function functionalResourceNames(Classroom $classroom): array
    {
        return $classroom->inventoryItems
            ->filter(fn ($item) => $item->status === 'available' && $item->available_quantity > 0)
            ->map(fn ($item) => mb_strtolower(trim($item->name)))
            ->unique()
            ->values()
            ->all();
    }

    private function normalizeResources(array $resources): array
    {
        return collect($resources)
            ->map(fn ($resource) => mb_strtolower(trim((string) $resource)))
            ->filter()
            ->unique()
            ->values()
            ->all();
    }

    private function isWithinSchedule(Classroom $classroom, Carbon $startsAt, Carbon $endsAt): bool
    {
        return $classroom->schedules()
            ->where('is_active', true)
            ->where('weekday', $startsAt->isoWeekday())
            ->where('start_time', '<=', $startsAt->format('H:i:s'))
            ->where('end_time', '>=', $endsAt->format('H:i:s'))
            ->exists();
    }

    private function findAlternativeTimes(array $criteria, Carbon $startsAt, Carbon $endsAt, array $required): array
    {
        $durationMinutes = $startsAt->diffInMinutes($endsAt);
        $alternatives = [];

        for ($day = 0; $day <= 3 && count($alternatives) < 3; $day++) {
            for ($hour = 1; $hour <= 4 && count($alternatives) < 3; $hour++) {
                $candidateStart = $startsAt->copy()->addDays($day)->addHours($hour);
                $candidateEnd = $candidateStart->copy()->addMinutes($durationMinutes);
                $rooms = $this->availableClassrooms($candidateStart, $candidateEnd, (int) $criteria['attendees'])->get();
                $hasExact = $rooms->contains(fn (Classroom $room) => array_diff($required, $this->functionalResourceNames($room)) === []);

                if ($hasExact) {
                    $alternatives[] = [
                        'starts_at' => $candidateStart->toIso8601String(),
                        'ends_at' => $candidateEnd->toIso8601String(),
                        'available_rooms' => $rooms->count(),
                    ];
                }
            }
        }

        return $alternatives;
    }
}
