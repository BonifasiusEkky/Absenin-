<?php

namespace App\Console\Commands;

use App\Models\Attendance;
use App\Models\Leave;
use App\Models\User;
use App\Models\Holiday;
use Carbon\Carbon;
use Carbon\CarbonPeriod;
use Illuminate\Console\Command;
use Illuminate\Support\Str;

class MarkDailyAbsences extends Command
{
    protected $signature = 'attendances:mark-absent {date? : Target date (YYYY-MM-DD). Default: yesterday}
                            {--from= : Start date (YYYY-MM-DD) for backfill}
                            {--to= : End date (YYYY-MM-DD) for backfill}
                            {--dry-run : Do not write to DB}';

    protected $description = 'Backfill leave attendance rows only; absent is represented by missing attendance records.';

    public function handle(): int
    {
        $fromOpt = $this->option('from');
        $toOpt = $this->option('to');

        if ($fromOpt || $toOpt) {
            if (!$fromOpt || !$toOpt) {
                $this->error('Both --from and --to must be provided together.');
                return self::FAILURE;
            }
            $from = Carbon::parse($fromOpt)->startOfDay();
            $to = Carbon::parse($toOpt)->startOfDay();
        } else {
            $dateArg = $this->argument('date');
            $target = $dateArg ? Carbon::parse($dateArg)->startOfDay() : now()->subDay()->startOfDay();
            $from = $target;
            $to = $target;
        }

        if ($to->lt($from)) {
            $this->error('--to must be >= --from');
            return self::FAILURE;
        }

        $dryRun = (bool) $this->option('dry-run');

        $employees = User::query()
            ->where('role', 'employee')
            ->where('is_active', true)
            ->get(['id', 'work_mode']);

        if ($employees->isEmpty()) {
            $this->info('No active employees found.');
            return self::SUCCESS;
        }

        $createdLeave = 0;
        $skippedExisting = 0;

        foreach (CarbonPeriod::create($from, $to) as $day) {
            // Only count bolos on weekdays (Mon–Fri)
            if ($day->isWeekend()) {
                continue;
            }

            $date = $day->toDateString();
            
            // Skip if it's a holiday
            if (Holiday::where('date', $date)->exists()) {
                $this->info("Skipping $date: Holiday/Mass Leave");
                continue;
            }

            // Preload who already has an attendance row for this date
            $existingUserIds = Attendance::query()
                ->where('date', $date)
                ->pluck('user_id')
                ->map(fn ($v) => (int) $v)
                ->all();
            $existingLookup = array_fill_keys($existingUserIds, true);

            foreach ($employees as $emp) {
                $userId = (int) $emp->id;

                if (isset($existingLookup[$userId])) {
                    $skippedExisting++;
                    continue;
                }

                $onApprovedLeave = Leave::query()
                    ->where('user_id', $userId)
                    ->where('status', 'approved')
                    ->whereDate('start_date', '<=', $date)
                    ->whereDate('end_date', '>=', $date)
                    ->exists();

                if ($dryRun) {
                    if ($onApprovedLeave) {
                        $createdLeave++;
                    }
                    continue;
                }

                if ($onApprovedLeave) {
                    Attendance::create([
                        'id' => (string) Str::uuid(),
                        'user_id' => $userId,
                        'date' => $date,
                        'status' => 'leave',
                        'work_mode' => $emp->work_mode,
                    ]);
                    $createdLeave++;
                }
            }
        }

        $this->info('Done.');
        $this->line('created_leave: ' . $createdLeave);
        $this->line('skipped_existing: ' . $skippedExisting);
        if ($dryRun) {
            $this->warn('dry-run enabled: no DB writes were performed.');
        }

        return self::SUCCESS;
    }
}
