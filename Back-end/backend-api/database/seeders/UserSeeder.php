<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $names = [
            'Boni', 'Farrel', 'Juan', 'Diqi', 'Juan', 'Wildan', 'Filah', 'Fikri'
        ];

        $i = 1;
        foreach ($names as $name) {
            // Ensure unique emails even for duplicate names like "Juan"
            $emailLocal = strtolower($name);
            $email = sprintf('%s%d@example.com', $emailLocal, $i);
            $i++;

            User::updateOrCreate(
                ['email' => $email],
                [
                    'name' => $name,
                    'password' => Hash::make('password123'),
                    'email_verified_at' => now(),
                ]
            );
        }
    }
}
