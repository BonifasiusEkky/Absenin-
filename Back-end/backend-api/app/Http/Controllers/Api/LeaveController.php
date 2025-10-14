<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Leave;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class LeaveController extends Controller
{
    public function index(Request $request)
    {
        $userId = $request->query('user_id');
        $q = Leave::query();
        if ($userId) $q->where('user_id', $userId);
        return response()->json($q->orderByDesc('created_at')->limit(200)->get());
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'user_id' => 'required|string',
            'type' => 'required|string',
            'start_date' => 'required|date',
            'end_date' => 'required|date',
            'reason' => 'nullable|string',
        ]);
        $data['id'] = (string) Str::uuid();
        $leave = Leave::create($data);
        return response()->json($leave, 201);
    }
}
