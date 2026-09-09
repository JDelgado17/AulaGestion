<?php

namespace Tests\Feature;

use App\Models\Classroom;
use App\Models\ClassroomSchedule;
use App\Models\InventoryItem;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class RecommendationTest extends TestCase
{
    use RefreshDatabase;

    public function test_recommendation_excludes_rooms_without_required_resources(): void
    {
        $professor = User::create([
            'name' => 'Profesor', 'email' => 'profesor@test.co', 'password' => 'password123',
            'role' => 'professor', 'is_active' => true,
        ]);
        Sanctum::actingAs($professor);

        $startsAt = Carbon::now()->next(Carbon::MONDAY)->setTime(9, 0);
        $endsAt = $startsAt->copy()->addHours(2);

        $withProjector = $this->room('A-101', 30, $startsAt->isoWeekday());
        $withoutProjector = $this->room('A-102', 35, $startsAt->isoWeekday());
        InventoryItem::create([
            'classroom_id' => $withProjector->id, 'name' => 'Videobeam', 'category' => 'Tecnología',
            'quantity' => 1, 'available_quantity' => 1, 'status' => 'available',
        ]);

        $response = $this->postJson('/api/recommendations/search', [
            'starts_at' => $startsAt->toIso8601String(),
            'ends_at' => $endsAt->toIso8601String(),
            'attendees' => 25,
            'activity_type' => 'Clase',
            'required_resources' => ['Videobeam'],
            'optional_resources' => [],
        ])->assertOk();

        $response->assertJsonPath('data.recommendations.0.classroom.code', 'A-101');
        $codes = collect($response->json('data.recommendations'))->pluck('classroom.code');
        $this->assertFalse($codes->contains($withoutProjector->code));
    }

    private function room(string $code, int $capacity, int $weekday): Classroom
    {
        $room = Classroom::create([
            'code' => $code, 'name' => "Aula {$code}", 'location' => 'Bloque A',
            'capacity' => $capacity, 'type' => 'Clase', 'status' => 'available', 'is_active' => true,
        ]);
        ClassroomSchedule::create([
            'classroom_id' => $room->id, 'weekday' => $weekday,
            'start_time' => '07:00', 'end_time' => '19:00', 'is_active' => true,
        ]);
        return $room;
    }
}

