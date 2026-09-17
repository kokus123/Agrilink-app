<?php

namespace App\Services;

use App\Models\Livraison;
use App\Models\LivraisonRefus;
use App\Models\User;

/**
 * Attribution des livraisons — façon Uber/Yango : propose au transporteur
 * disponible le plus proche de l'acheteur, en excluant ceux déjà occupés
 * (une livraison en_cours) et ceux ayant déjà refusé CETTE livraison.
 *
 * Si l'acheteur n'a jamais partagé sa position (elle est optionnelle),
 * on se rabat sur "le transporteur le plus récemment actif" plutôt que
 * d'échouer complètement.
 */
class LivraisonMatchingService
{
    public function trouverProchainTransporteur(Livraison $livraison): ?User
    {
        $acheteur = $livraison->commande->acheteur;

        $dejaRefuse = LivraisonRefus::where('livraison_id', $livraison->id)
            ->pluck('transporteur_id');

        $occupes = Livraison::where('statut', 'en_cours')
            ->whereNotNull('transporteur_id')
            ->pluck('transporteur_id');

        $exclus = $dejaRefuse->merge($occupes)->unique()->values();

        $query = User::where('role', 'transporteur')
            ->where('is_active', true)
            ->whereNotIn('id', $exclus);

        if ($acheteur && $acheteur->latitude !== null && $acheteur->longitude !== null) {
            return $query->whereNotNull('latitude')
                ->whereNotNull('longitude')
                ->selectRaw(
                    'users.*, (6371 * acos(cos(radians(?)) * cos(radians(latitude)) * cos(radians(longitude) - radians(?)) + sin(radians(?)) * sin(radians(latitude)))) as distance_km',
                    [$acheteur->latitude, $acheteur->longitude, $acheteur->latitude]
                )
                ->orderBy('distance_km')
                ->first();
        }

        // Repli : pas de position acheteur connue — on prend le
        // transporteur le plus récemment actif plutôt que d'échouer.
        return $query->orderByDesc('position_updated_at')->first();
    }
}
