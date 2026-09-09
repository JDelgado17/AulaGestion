<?php

namespace Tests\Feature;

use App\Models\Classroom;
use App\Models\ClassroomSchedule;
use App\Models\Reservation;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ReservationConflictTest extends TestCase
{
    use RefreshDatabase;

    public function test_overlapping_reservation_is_rejected(): void
    {
        $professor = User::create([
            'name' => 'Profesor', 'email' => 'profesor@test.co', 'password' => 'password123',
            'role' => 'professor', 'is_active' => true,
        ]);
        Sanctum::actingAs($professor);

        $startsAt = Carbon::now()->next(Carbon::TUESDAY)->setTime(10, 0);
        $room = Classroom::create([
            'code' => 'B-201', 'name' => 'Aula B-201', 'location' => 'Bloque B',
            'capacity' => 40, 'type' => 'Clase', 'status' => 'available', 'is_active' => true,
        ]);
        ClassroomSchedule::create([
            'classroom_id' => $room->id, 'weekday' => $startsAt->isoWeekday(),
            'start_time' => '07:00', 'end_time' => '19:00', 'is_active' => true,
        ]);
        Reservation::create([
            'user_id' => $professor->id, 'classroom_id' => $room->id,
            'starts_at' => $startsAt, 'ends_at' => $startsAt->copy()->addHours(2),
            'attendees' => 20, 'activity_type' => 'Clase', 'purpose' => 'Reserva existente',
            'required_resources' => [], 'optional_resources' => [], 'status' => 'confirmed',
        ]);

        $this->postJson('/api/reservations', [
            'classroom_id' => $room->id,
            'starts_at' => $startsAt->copy()->addHour()->toIso8601String(),
            'ends_at' => $startsAt->copy()->addHours(3)->toIso8601String(),
            'attendees' => 20,
            'activity_type' => 'Clase',
            'purpose' => 'Reserva superpuesta',
            'required_resources' => [],
            'optional_resources' => [],
        ])->assertStatus(409)
            ->assertJsonPath('success', false);

        $this->assertDatabaseCount('reservations', 1);
    }
}
