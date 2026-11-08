<?php

namespace Tests\Feature;

use App\Models\Classroom;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ClassroomRegistrationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Sanctum::actingAs(User::create([
            'name' => 'Administradora', 'email' => 'admin@test.co', 'password' => 'password123',
            'role' => 'admin', 'is_active' => true,
        ]));
    }

    private function payload(array $overrides = []): array
    {
        return [
            'code' => 'A-101', 'name' => 'Aula Interactiva', 'location' => 'Bloque A, piso 1',
            'capacity' => 30, 'type' => 'Multimedia', 'status' => 'available', 'is_active' => true,
            ...$overrides,
        ];
    }

    public function test_new_classroom_appears_in_search_without_extra_steps(): void
    {
        $this->postJson('/api/classrooms', $this->payload())->assertCreated();

        $startsAt = Carbon::now()->next(Carbon::MONDAY)->setTime(9, 0);
        $this->postJson('/api/recommendations/search', [
            'starts_at' => $startsAt->toIso8601String(),
            'ends_at' => $startsAt->copy()->addHours(2)->toIso8601String(),
            'attendees' => 25,
            'activity_type' => 'Clase',
            'required_resources' => [],
            'optional_resources' => [],
        ])
            ->assertOk()
            ->assertJsonPath('data.recommendations.0.classroom.code', 'A-101');
    }

    public function test_code_must_follow_the_format(): void
    {
        foreach (['A101', 'aula uno', 'a-101', 'A-'] as $code) {
            $this->postJson('/api/classrooms', $this->payload(['code' => $code]))
                ->assertUnprocessable();
        }
        $this->assertSame(0, Classroom::count());
    }

    public function test_type_must_come_from_the_catalog(): void
    {
        $this->postJson('/api/classrooms', $this->payload(['type' => 'Salón raro']))
            ->assertUnprocessable();
    }

    public function test_existing_type_outside_the_catalog_can_still_be_edited(): void
    {
        $room = Classroom::create($this->payload(['type' => 'Tipo antiguo']));

        $this->putJson("/api/classrooms/{$room->id}", $this->payload(['type' => 'Tipo antiguo', 'name' => 'Nuevo nombre']))
            ->assertOk()
            ->assertJsonPath('data.name', 'Nuevo nombre');
    }

    public function test_activity_gets_points_for_a_suitable_room_type(): void
    {
        $this->postJson('/api/classrooms', $this->payload(['code' => 'B-301', 'type' => 'Informática']))->assertCreated();
        $this->postJson('/api/classrooms', $this->payload(['code' => 'C-102', 'type' => 'Actividad lúdica']))->assertCreated();

        $startsAt = Carbon::now()->next(Carbon::MONDAY)->setTime(9, 0);
        $this->postJson('/api/recommendations/search', [
            'starts_at' => $startsAt->toIso8601String(),
            'ends_at' => $startsAt->copy()->addHours(2)->toIso8601String(),
            'attendees' => 25,
            'activity_type' => 'Trabajo en computadores',
            'required_resources' => [],
            'optional_resources' => [],
        ])
            ->assertOk()
            ->assertJsonPath('data.recommendations.0.classroom.code', 'B-301');
    }
}
