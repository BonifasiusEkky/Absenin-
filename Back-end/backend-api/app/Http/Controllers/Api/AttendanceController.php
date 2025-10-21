<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class AttendanceController extends Controller
{
    public function index(Request $request)
    {
        $userId = $request->query('user_id');
        $q = Attendance::query();
        if ($userId) $q->where('user_id', $userId);
        return response()->json($q->orderByDesc('date')->limit(200)->get());
    }

    public function checkIn(Request $request)
    {
        $data = $request->validate([
            'user_id' => 'required|integer',
            'date' => 'required|date',
            'time' => 'required', // expected format HH:MM:SS
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'distance_m' => 'nullable|numeric',
        ]);
        $att = Attendance::firstOrNew(['user_id' => $data['user_id'], 'date' => $data['date']]);
        if (!$att->exists) {
            $att->id = (string) Str::uuid();
        }
        $att->check_in = $data['time'];
        $att->latitude = $data['latitude'] ?? null;
        $att->longitude = $data['longitude'] ?? null;
        $att->distance_m = $data['distance_m'] ?? null;
        $att->save();
        return response()->json($att);
    }

    public function checkOut(Request $request)
    {
        $data = $request->validate([
            'user_id' => 'required|integer',
            'date' => 'required|date',
            'time' => 'required', // expected format HH:MM:SS
            'activity' => 'sometimes|string|nullable',
        ]);
        $att = Attendance::where('user_id', $data['user_id'])->where('date', $data['date'])->first();
        if (!$att) {
            return response()->json(['message' => 'Attendance not found'], 404);
        }
        $att->check_out = $data['time'];
        if (array_key_exists('activity', $data)) {
            $att->activity_note = $data['activity'];
        }
        $att->save();
        return response()->json($att);
    }
}
