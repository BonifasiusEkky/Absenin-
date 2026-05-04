<?php

namespace Database\Seeders;

use App\Models\Leave;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;
use Carbon\Carbon;

class LeaveSeeder extends Seeder
{
    public function run(): void
    {
        $users = User::where('role', 'employee')->get();
        
        foreach ($users as $user) {
            // Create 1-2 leave records for each user in the past 2 weeks
            $count = rand(1, 2);
            for ($i = 0; $i < $count; $i++) {
                $startDate = Carbon::create(2026, 5, rand(1, 4));
                $endDate = $startDate->copy()->addDays(rand(0, 2));

                Leave::create([
                    'id' => Str::uuid(),
                    'user_id' => $user->id,
                    'type' => rand(0, 1) ? 'sick' : 'leave',
                    'start_date' => $startDate->format('Y-m-d'),
                    'end_date' => $endDate->format('Y-m-d'),
                    'reason' => 'Keperluan mendesak / Sakit',
                    'status' => 'approved',
                    'decided_by' => 1, // HRD
                    'decided_at' => now(),
                ]);
            }
        }
    }
}
