<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Leave;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Storage;

class LeaveController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        $q = Leave::query()->where('user_id', $user->id);
        return response()->json($q->orderByDesc('created_at')->limit(200)->get());
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'type' => 'required|string',
            'start_date' => 'required|date',
            'end_date' => 'required|date',
            'reason' => 'nullable|string',
            'attachment' => 'sometimes|file|mimes:pdf,jpg,jpeg,png|max:5120',
        ]);

        $user = $request->user();
        $payload = [
            'id' => (string) Str::uuid(),
            'user_id' => $user->id,
            'type' => $data['type'],
            'start_date' => $data['start_date'],
            'end_date' => $data['end_date'],
            'reason' => $data['reason'] ?? null,
            'status' => 'pending',
        ];

        if ($request->hasFile('attachment')) {
            $path = $request->file('attachment')->store('public/leave-attachments');
            $payload['attachment_path'] = $path;
        }

        $leave = Leave::create($payload);
        return response()->json($leave, 201);
    }
}
