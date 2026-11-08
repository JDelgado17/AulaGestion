<?php

namespace Tests\Feature;

use App\Models\AppNotification;
use App\Models\Classroom;
use App\Models\ClassroomBlock;
use App\Models\Reservation;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ReservationAlertTest extends TestCase
{
    use RefreshDatabase;

    private User $professor;

    private Classroom $room;

    private Reservation $reservation;

    protected function setUp(): void
    {
        parent::setUp();

        $this->professor = User::create([
            'name' => 'Profesor', 'email' => 'profesor@test.co', 'password' => 'password123',
            'role' => 'professor', 'is_active' => true,
        ]);
        Sanctum::actingAs($this->professor);

        $this->room = Classroom::create([
            'code' => 'B-201', 'name' => 'Aula B-201', 'location' => 'Bloque B',
            'capacity' => 40, 'type' => 'Clase', 'status' => 'available', 'is_active' => true,
        ]);
        $startsAt = Carbon::now()->addDays(2)->setTime(10, 0);
        $this->reservation = Reservation::create([
            'user_id' => $this->professor->id, 'classroom_id' => $this->room->id,
            'starts_at' => $startsAt, 'ends_at' => $startsAt->copy()->addHours(2),
            'attendees' => 20, 'activity_type' => 'Clase', 'purpose' => 'Clase de prueba',
            'required_resources' => [], 'optional_resources' => [], 'status' => 'confirmed',
        ]);
    }

    public function test_no_alert_while_the_classroom_is_available(): void
    {
        $this->getJson('/api/notifications/alerts')
            ->assertOk()
            ->assertJsonPath('data.unread_count', 0)
            ->assertJsonCount(0, 'data.alerts');
    }

    public function test_disabling_directly_in_the_database_creates_one_alert(): void
    {
        // Sin pasar por el modelo ni la API, como un UPDATE desde la consola de MySQL.
        Classroom::query()->update(['is_active' => false]);

        $this->getJson('/api/notifications/alerts')
            ->assertOk()
            ->assertJsonPath('data.unread_count', 1)
            ->assertJsonCount(1, 'data.alerts')
            ->assertJsonPath('data.alerts.0.type', 'classroom_unavailable')
            ->assertJsonPath('data.alerts.0.metadata.alert_state', 'active');

        $this->getJson('/api/notifications/alerts')->assertJsonCount(1, 'data.alerts');
        $this->assertSame(1, AppNotification::count());
    }

    public function test_read_alert_stops_popping_up_but_stays_active_in_history(): void
    {
        $this->room->update(['status' => 'maintenance']);
        $alertId = $this->getJson('/api/notifications/alerts')->json('data.alerts.0.id');

        $this->patchJson("/api/notifications/{$alertId}/read")->assertOk();

        $this->getJson('/api/notifications/alerts')->assertJsonCount(0, 'data.alerts');
        $this->assertSame(1, AppNotification::count());
        $this->getJson('/api/notifications')
            ->assertJsonPath('data.data.0.metadata.alert_state', 'active');
    }

    public function test_restored_classroom_resolves_the_alert_and_notifies(): void
    {
        $this->room->update(['status' => 'out_of_service']);
        $this->getJson('/api/notifications/alerts')->assertJsonCount(1, 'data.alerts');

        $this->room->update(['status' => 'available']);

        $this->getJson('/api/notifications/alerts')
            ->assertJsonCount(0, 'data.alerts')
            ->assertJsonPath('data.unread_count', 2);
        $alert = AppNotification::where('type', 'classroom_unavailable')->first();
        $this->assertSame('resolved', $alert->metadata['alert_state']);
        $this->assertTrue(AppNotification::where('type', 'classroom_restored')->exists());
    }

    public function test_cancelled_reservation_resolves_the_alert_without_restored_notice(): void
    {
        $this->room->update(['is_active' => false]);
        $this->getJson('/api/notifications/alerts')->assertJsonCount(1, 'data.alerts');

        $this->patchJson("/api/reservations/{$this->reservation->id}/cancel", ['reason' => 'Aula deshabilitada'])
            ->assertOk();

        $this->getJson('/api/notifications/alerts')->assertJsonCount(0, 'data.alerts');
        $this->assertFalse(AppNotification::where('type', 'classroom_restored')->exists());
    }

    public function test_overlapping_block_creates_alert_and_non_overlapping_does_not(): void
    {
        $block = ClassroomBlock::create([
            'classroom_id' => $this->room->id, 'created_by' => $this->professor->id, 'reason' => 'Fumigación',
            'starts_at' => $this->reservation->ends_at->copy()->addHour(),
            'ends_at' => $this->reservation->ends_at->copy()->addHours(2),
        ]);
        $this->getJson('/api/notifications/alerts')->assertJsonCount(0, 'data.alerts');

        $block->update(['starts_at' => $this->reservation->starts_at, 'ends_at' => $this->reservation->ends_at]);

        $response = $this->getJson('/api/notifications/alerts')->assertJsonCount(1, 'data.alerts');
        $this->assertStringContainsString('Fumigación', $response->json('data.alerts.0.message'));
    }

    public function test_reservation_list_reports_the_availability_issue(): void
    {
        $this->getJson('/api/reservations')
            ->assertJsonPath('data.data.0.availability_issue', null);

        $this->room->update(['is_active' => false]);

        $this->getJson('/api/reservations')
            ->assertJsonPath('data.data.0.availability_issue', 'el aula fue deshabilitada');
    }

    public function test_reminder_is_created_once_when_the_reservation_is_near(): void
    {
        $this->getJson('/api/notifications')->assertOk();
        $this->assertFalse(AppNotification::where('type', 'reservation_reminder')->exists());

        $this->travelTo($this->reservation->starts_at->copy()->subHours(5));

        $this->getJson('/api/notifications')->assertOk();
        $this->getJson('/api/notifications')->assertOk();
        $this->assertSame(1, AppNotification::where('type', 'reservation_reminder')->count());
    }

    public function test_dashboard_returns_the_next_reservations_of_the_user(): void
    {
        $this->room->update(['status' => 'maintenance']);

        $this->getJson('/api/dashboard')
            ->assertOk()
            ->assertJsonPath('data.active_alerts', 1)
            ->assertJsonCount(1, 'data.next_reservations')
            ->assertJsonPath('data.next_reservations.0.id', $this->reservation->id)
            ->assertJsonPath('data.next_reservations.0.classroom.code', 'B-201')
            ->assertJsonPath('data.next_reservations.0.availability_issue', 'el aula está en mantenimiento');

        Sanctum::actingAs(User::create([
            'name' => 'Otra', 'email' => 'otra@test.co', 'password' => 'password123',
            'role' => 'professor', 'is_active' => true,
        ]));
        $this->getJson('/api/dashboard')->assertJsonCount(0, 'data.next_reservations');
    }

    public function test_alerts_of_other_users_are_not_visible(): void
    {
        $this->room->update(['is_active' => false]);
        $this->getJson('/api/notifications/alerts')->assertJsonCount(1, 'data.alerts');

        Sanctum::actingAs(User::create([
            'name' => 'Otro', 'email' => 'otro@test.co', 'password' => 'password123',
            'role' => 'professor', 'is_active' => true,
        ]));

        $this->getJson('/api/notifications/alerts')
            ->assertJsonPath('data.unread_count', 0)
            ->assertJsonCount(0, 'data.alerts');
    }
}
