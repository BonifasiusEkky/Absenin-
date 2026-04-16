<?php

namespace App\Http\Controllers\Hrd;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\Leave;
use App\Models\OfficeSetting;
use App\Models\User;

class DashboardController extends Controller
{
    public function index()
    {
        $today = now()->toDateString();

        $stats = [
            'employees_total' => User::where('role', 'employee')->count(),
            'employees_active' => User::where('role', 'employee')->where('is_active', true)->count(),
            'leaves_pending' => Leave::where('status', 'pending')->count(),
            'attendances_today' => Attendance::where('date', $today)->count(),
            'checkin_today' => Attendance::where('date', $today)->whereNotNull('check_in')->count(),
            'checkout_today' => Attendance::where('date', $today)->whereNotNull('check_out')->count(),
        ];

        $office = OfficeSetting::query()->orderByDesc('id')->first();

        return view('hrd.dashboard', [
            'stats' => $stats,
            'office' => $office,
            'today' => $today,
        ]);
    }
}
