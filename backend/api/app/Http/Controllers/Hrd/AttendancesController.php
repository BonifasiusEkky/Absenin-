<?php

namespace App\Http\Controllers\Hrd;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\User;
use Illuminate\Http\Request;

class AttendancesController extends Controller
{
    public function index(Request $request)
    {
        $q = Attendance::query()->with('user')->orderByDesc('date')->orderByDesc('id');

        if ($request->filled('date')) {
            $q->where('date', $request->query('date'));
        }

        if ($request->filled('user_id')) {
            $q->where('user_id', (int) $request->query('user_id'));
        }

        $attendances = $q->limit(500)->get();
        $users = User::orderBy('name')->get(['id', 'name', 'email']);

        return view('hrd.attendances.index', [
            'attendances' => $attendances,
            'users' => $users,
            'filters' => [
                'date' => $request->query('date', ''),
                'user_id' => $request->query('user_id', ''),
            ],
        ]);
    }
}
