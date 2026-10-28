<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ClassroomBlock;
use App\Models\ClassroomSchedule;
use App\Models\Reservation;
use App\Services\AuditService;
use Illuminate\Http\Request;

class ScheduleController extends Controller
{
    public function __construct(private readonly AuditService $audit) {}

    public function index(Request $request)
    {
        $schedules = ClassroomSchedule::with('classroom:id,code,name')
            ->when($request->filled('classroom_id'), fn ($query) => $query->where('classroom_id', $request->integer('classroom_id')))
            ->orderBy('weekday')
            ->orderBy('start_time')
            ->get();

        return $this->success($schedules);
    }

    public function store(Request $request)
    {
        $schedule = ClassroomSchedule::create($this->validatedSchedule($request));
        $this->audit->record($request, 'schedule.created', $schedule, null, $schedule->toArray());

        return $this->success($schedule->load('classroom:id,code,name'), 'Horario configurado.', 201);
    }

    public function update(Request $request, ClassroomSchedule $schedule)
    {
        $before = $schedule->toArray();
        $schedule->update($this->validatedSchedule($request));
        $this->audit->record($request, 'schedule.updated', $schedule, $before, $schedule->fresh()->toArray());

        return $this->success($schedule->fresh(), 'Horario actualizado.');
    }

    public function destroy(Request $request, ClassroomSchedule $schedule)
    {
        $this->audit->record($request, 'schedule.deleted', $schedule, $schedule->toArray(), null);
        $schedule->delete();

        return $this->success(null, 'Horario eliminado.');
    }

    public function blocks(Request $request)
    {
        $blocks = ClassroomBlock::with(['classroom:id,code,name', 'creator:id,name'])
            ->when($request->filled('classroom_id'), fn ($query) => $query->where('classroom_id', $request->integer('classroom_id')))
            ->when($request->filled('from'), fn ($query) => $query->where('ends_at', '>=', $request->date('from')))
            ->orderBy('starts_at')
            ->paginate(30);

        return $this->success($blocks);
    }

    public function storeBlock(Request $request)
    {
        $data = $request->validate([
            'classroom_id' => ['required', 'exists:classrooms,id'],
            'starts_at' => ['required', 'date', 'after_or_equal:now'],
            'ends_at' => ['required', 'date', 'after:starts_at'],
            'reason' => ['required', 'string', 'max:255'],
        ]);

        $overlapsReservation = Reservation::where('classroom_id', $data['classroom_id'])
            ->where('status', 'confirmed')
            ->where('starts_at', '<', $data['ends_at'])
            ->where('ends_at', '>', $data['starts_at'])
            ->exists();

        if ($overlapsReservation) {
            return $this->error('No se puede bloquear una franja con reservas confirmadas.', 422);
        }

        $block = ClassroomBlock::create([...$data, 'created_by' => $request->user()->id]);
        $this->audit->record($request, 'block.created', $block, null, $block->toArray());

        return $this->success($block->load('classroom:id,code,name'), 'Bloqueo creado correctamente.', 201);
    }

    public function destroyBlock(Request $request, ClassroomBlock $block)
    {
        $this->audit->record($request, 'block.deleted', $block, $block->toArray(), null);
        $block->delete();

        return $this->success(null, 'Bloqueo eliminado.');
    }

    private function validatedSchedule(Request $request): array
    {
        return $request->validate([
            'classroom_id' => ['required', 'exists:classrooms,id'],
            'weekday' => ['required', 'integer', 'between:1,7'],
            'start_time' => ['required', 'date_format:H:i'],
            'end_time' => ['required', 'date_format:H:i', 'after:start_time'],
            'is_active' => ['sometimes', 'boolean'],
        ]);
    }
}
