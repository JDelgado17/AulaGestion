<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\RecommendationService;
use Carbon\Carbon;
use Illuminate\Http\Request;

class RecommendationController extends Controller
{
    public function __construct(private readonly RecommendationService $recommendations) {}

    public function search(Request $request)
    {
        $criteria = $request->validate([
            'starts_at' => ['required', 'date', 'after_or_equal:now'],
            'ends_at' => ['required', 'date', 'after:starts_at'],
            'attendees' => ['required', 'integer', 'min:1', 'max:1000'],
            'activity_type' => ['required', 'string', 'max:80'],
            'required_resources' => ['sometimes', 'array', 'max:20'],
            'required_resources.*' => ['string', 'max:120'],
            'optional_resources' => ['sometimes', 'array', 'max:20'],
            'optional_resources.*' => ['string', 'max:120'],
        ]);

        $duration = Carbon::parse($criteria['starts_at'])->diffInMinutes(Carbon::parse($criteria['ends_at']));
        if ($duration < 30 || $duration > 480) {
            return $this->error('La reserva debe durar entre 30 minutos y 8 horas.', 422);
        }

        return $this->success(
            $this->recommendations->recommend($criteria),
            'Búsqueda completada correctamente.',
        );
    }
}

