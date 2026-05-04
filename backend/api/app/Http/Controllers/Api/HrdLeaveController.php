<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Leave;
use Illuminate\Http\Request;

class HrdLeaveController extends Controller
{
    /**
     * GET /api/hrd/leaves
     */
    public function index(Request $request)
    {
        $q = Leave::query();
        if ($request->filled('status')) {
            $q->where('status', $request->query('status'));
        }
        if ($request->filled('user_id')) {
            $q->where('user_id', (int) $request->query('user_id'));
        }

        return response()->json($q->orderByDesc('created_at')->limit(500)->get());
    }

    /**
     * PATCH /api/hrd/leaves/{id}
     * Body: { status: approved|rejected, decision_note? }
     */
    public function decide(Request $request, string $id)
    {
        $data = $request->validate([
            'status' => 'required|in:approved,rejected',
            'decision_note' => 'nullable|string',
        ]);

        $leave = Leave::findOrFail($id);
        $leave->status = $data['status'];
        $leave->decision_note = $data['decision_note'] ?? null;
        $leave->decided_by = $request->user()?->id;
        $leave->decided_at = now();
        $leave->save();

        return response()->json(['ok' => true, 'leave' => $leave]);
    }
}
