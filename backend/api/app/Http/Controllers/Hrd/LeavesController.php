<?php

namespace App\Http\Controllers\Hrd;

use App\Http\Controllers\Controller;
use App\Models\Leave;
use App\Models\User;
use Illuminate\Http\Request;

class LeavesController extends Controller
{
    public function index(Request $request)
    {
        $q = Leave::query()->with('user')->orderByDesc('created_at');

        if ($request->filled('status')) {
            $q->where('status', $request->query('status'));
        }

        if ($request->filled('user_id')) {
            $q->where('user_id', (int) $request->query('user_id'));
        }

        $leaves = $q->limit(500)->get();
        $users = User::orderBy('name')->get(['id', 'name', 'email']);

        return view('hrd.leaves.index', [
            'leaves' => $leaves,
            'users' => $users,
            'filters' => [
                'status' => $request->query('status', ''),
                'user_id' => $request->query('user_id', ''),
            ],
        ]);
    }

    public function decide(Request $request, int $id)
    {
        $data = $request->validate([
            'status' => 'required|in:approved,rejected',
            'decision_note' => 'nullable|string|max:1000',
        ]);

        $leave = Leave::findOrFail($id);
        $leave->status = $data['status'];
        $leave->decision_note = $data['decision_note'] ?? null;
        $leave->decided_by = $request->user()?->id;
        $leave->decided_at = now();
        $leave->save();

        return back()->with('success', 'Cuti diproses.');
    }
}
