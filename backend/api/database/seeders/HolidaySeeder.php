<?php

namespace Database\Seeders;

use App\Models\Holiday;
use Illuminate\Database\Seeder;

class HolidaySeeder extends Seeder
{
    public function run(): void
    {
        $year = 2026;

        $holidays = [
            ['date' => "$year-01-01", 'name' => 'Tahun Baru Masehi', 'is_mass_leave' => false],
            ['date' => "$year-01-16", 'name' => 'Isra Mikraj Nabi Muhammad SAW', 'is_mass_leave' => false],
            ['date' => "$year-02-16", 'name' => 'Cuti Bersama Tahun Baru Imlek', 'is_mass_leave' => true],
            ['date' => "$year-02-17", 'name' => 'Tahun Baru Imlek 2577 Kongzili', 'is_mass_leave' => false],
            ['date' => "$year-03-18", 'name' => 'Cuti Bersama Nyepi', 'is_mass_leave' => true],
            ['date' => "$year-03-19", 'name' => 'Hari Suci Nyepi Tahun Baru Saka 1948', 'is_mass_leave' => false],
            ['date' => "$year-03-20", 'name' => 'Cuti Bersama Idul Fitri', 'is_mass_leave' => true],
            ['date' => "$year-03-21", 'name' => 'Hari Raya Idul Fitri 1447 H', 'is_mass_leave' => false],
            ['date' => "$year-03-22", 'name' => 'Hari Raya Idul Fitri 1447 H (Hari Kedua)', 'is_mass_leave' => false],
            ['date' => "$year-03-23", 'name' => 'Cuti Bersama Idul Fitri', 'is_mass_leave' => true],
            ['date' => "$year-03-24", 'name' => 'Cuti Bersama Idul Fitri', 'is_mass_leave' => true],
            ['date' => "$year-04-03", 'name' => 'Wafat Yesus Kristus', 'is_mass_leave' => false],
            ['date' => "$year-05-01", 'name' => 'Hari Buruh Internasional', 'is_mass_leave' => false],
            ['date' => "$year-05-14", 'name' => 'Kenaikan Yesus Kristus', 'is_mass_leave' => false],
            ['date' => "$year-05-15", 'name' => 'Cuti Bersama Kenaikan Yesus Kristus', 'is_mass_leave' => true],
            ['date' => "$year-05-27", 'name' => 'Hari Raya Idul Adha 1447 H', 'is_mass_leave' => false],
            ['date' => "$year-05-28", 'name' => 'Cuti Bersama Idul Adha', 'is_mass_leave' => true],
            ['date' => "$year-05-31", 'name' => 'Hari Raya Waisak 2570 BE', 'is_mass_leave' => false],
            ['date' => "$year-06-01", 'name' => 'Hari Lahir Pancasila', 'is_mass_leave' => false],
            ['date' => "$year-06-16", 'name' => '1 Muharam 1448 H', 'is_mass_leave' => false],
            ['date' => "$year-08-17", 'name' => 'Hari Kemerdekaan Republik Indonesia', 'is_mass_leave' => false],
            ['date' => "$year-08-25", 'name' => 'Maulid Nabi Muhammad SAW', 'is_mass_leave' => false],
            ['date' => "$year-12-24", 'name' => 'Cuti Bersama Natal', 'is_mass_leave' => true],
            ['date' => "$year-12-25", 'name' => 'Hari Raya Natal', 'is_mass_leave' => false],
        ];

        foreach ($holidays as $holiday) {
            Holiday::updateOrCreate(
                ['date' => $holiday['date']],
                [
                    'name' => $holiday['name'],
                    'is_mass_leave' => $holiday['is_mass_leave'],
                ]
            );
        }

        // Keep only canonical holiday rows for seeded year.
        Holiday::query()
            ->whereYear('date', $year)
            ->whereNotIn('date', array_column($holidays, 'date'))
            ->delete();
    }
}
