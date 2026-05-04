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

        $employeesActive = User::where('role', 'employee')->where('is_active', true)->count();

        $approvedLeaveToday = Leave::query()
            ->where('status', 'approved')
            ->whereDate('start_date', '<=', $today)
            ->whereDate('end_date', '>=', $today)
            ->distinct('user_id')
            ->count('user_id');

        $checkinToday = Attendance::where('date', $today)->whereNotNull('check_in')->distinct('user_id')->count('user_id');
        $checkoutToday = Attendance::where('date', $today)->whereNotNull('check_out')->distinct('user_id')->count('user_id');

        $stats = [
            'employees_total' => User::where('role', 'employee')->count(),
            'employees_active' => $employeesActive,
            'leaves_pending' => Leave::where('status', 'pending')->count(),
            'attendances_today' => Attendance::where('date', $today)->count(),
            'checkin_today' => $checkinToday,
            'checkout_today' => $checkoutToday,
            // Not-yet-checked-in employees excluding approved leave
            'absent_today_estimate' => max(0, $employeesActive - $approvedLeaveToday - $checkinToday),
        ];

        $office = OfficeSetting::query()->orderByDesc('id')->first();

        return view('hrd.dashboard', [
            'stats' => $stats,
            'office' => $office,
            'today' => $today,
        ]);
    }
}
