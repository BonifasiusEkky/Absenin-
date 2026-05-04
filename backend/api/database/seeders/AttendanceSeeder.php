<?php

namespace Database\Seeders;

use App\Models\Attendance;
use App\Models\Holiday;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;
use Carbon\Carbon;

class AttendanceSeeder extends Seeder
{
    public function run(): void
    {
        $users = User::where('role', 'employee')->get();
        $startDate = Carbon::create(2026, 4, 1)->startOfDay();
        $endDate = Carbon::today();
        $holidayDates = Holiday::query()
            ->whereBetween('date', [$startDate->toDateString(), $endDate->toDateString()])
            ->pluck('date')
            ->map(fn ($date) => Carbon::parse($date)->toDateString())
            ->flip();

        foreach ($users as $user) {
            $currentDate = clone $startDate;
            while ($currentDate <= $endDate) {
                $dateString = $currentDate->toDateString();

                // Skip and clean weekends/holidays to keep attendance realistic.
                if ($currentDate->isWeekend() || $holidayDates->has($dateString)) {
                    Attendance::where('user_id', $user->id)
                        ->whereDate('date', $dateString)
                        ->delete();
                    $currentDate->addDay();
                    continue;
                }

                // Keep the seed stable across reruns for the same user/date.
                $rand = (crc32($user->id . '|' . $currentDate->format('Y-m-d')) % 100) + 1;

                if ($rand <= 90) {
                    // Present
                    $attendance = Attendance::firstOrNew([
                        'user_id' => $user->id,
                        'date' => $dateString,
                    ]);
                    if (!$attendance->exists) {
                        $attendance->id = (string) Str::uuid();
                    }
                    $attendance->fill([
                        'status' => 'present',
                        'check_in' => $currentDate->copy()->hour(8)->minute($rand % 46)->format('H:i:s'),
                        'check_out' => $currentDate->copy()->hour(17)->minute($rand % 31)->format('H:i:s'),
                        'work_mode' => 'wfo',
                        'location_status_in' => 'valid',
                        'location_status_out' => 'valid',
                        'check_in_verified' => true,
                        'check_out_verified' => true,
                        'activity_note' => null,
                    ]);
                    $attendance->save();
                } elseif ($rand <= 97) {
                    // Leave / sick
                    $attendance = Attendance::firstOrNew([
                        'user_id' => $user->id,
                        'date' => $dateString,
                    ]);
                    if (!$attendance->exists) {
                        $attendance->id = (string) Str::uuid();
                    }
                    $attendance->fill([
                        'status' => 'leave',
                        'activity_note' => 'Izin Sakit/Cuti',
                        'check_in' => null,
                        'check_out' => null,
                        'work_mode' => 'wfo',
                    ]);
                    $attendance->save();
                } else {
                    // Absent is represented by no row in DB.
                    Attendance::where('user_id', $user->id)
                        ->whereDate('date', $dateString)
                        ->delete();
                }

                $currentDate->addDay();
            }
        }
    }
}
