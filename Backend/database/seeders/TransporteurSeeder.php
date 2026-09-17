<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

/**
 * Transporteurs de test — à lancer avec :
 *   php artisan db:seed --class=TransporteurSeeder
 *
 * Identifiants (email + mot de passe) pour se connecter dans l'app et
 * tester le matching par proximité / accepter / refuser.
 *
 * Coordonnées autour de Yaoundé pour que le calcul de distance ait du
 * sens par rapport à un acheteur de test situé aussi à Yaoundé.
 */
class TransporteurSeeder extends Seeder
{
    public function run(): void
    {
        $transporteurs = [
            [
                'name' => 'Transporteur Centre-ville',
                'email' => 'transporteur1@agrilink.test',
                // Proche du centre de Yaoundé
                'latitude' => 3.8480,
                'longitude' => 11.5021,
            ],
            [
                'name' => 'Transporteur Bastos',
                'email' => 'transporteur2@agrilink.test',
                // Quartier Bastos, un peu plus au nord
                'latitude' => 3.8820,
                'longitude' => 11.5140,
            ],
            [
                'name' => 'Transporteur Mvan',
                'email' => 'transporteur3@agrilink.test',
                // Mvan, plus au sud — volontairement plus loin pour tester le tri par distance
                'latitude' => 3.8050,
                'longitude' => 11.5310,
            ],
        ];

        foreach ($transporteurs as $t) {
            User::updateOrCreate(
                ['email' => $t['email']],
                [
                    'name' => $t['name'],
                    'phone' => '699000000',
                    'password' => Hash::make('password'),
                    'role' => 'transporteur',
                    'is_active' => true,
                    'is_subscribed' => false,
                    'latitude' => $t['latitude'],
                    'longitude' => $t['longitude'],
                    'position_updated_at' => now(),
                ]
            );
        }
    }
}
