<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Administrateur par défaut
        User::updateOrCreate(
            ['email' => 'admin@agrilink.cm'],
            [
                'name' => 'Administrateur Agrilink',
                'password' => Hash::make('password123'),
                'role' => 'admin',
                'is_active' => true,
                'is_subscribed' => false,
            ]
        );
    }
}