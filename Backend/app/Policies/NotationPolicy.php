<?php

namespace App\Policies;

use App\Models\Commande;
use App\Models\User;

class NotationPolicy
{
    /**
     * Un acheteur ne peut noter que :
     * - une commande qui lui appartient,
     * - livrée (statut = 'livree'),
     * - contenant au moins un produit de l'agriculteur ciblé.
     * L'unicité (pas de doublon) est garantie par la contrainte SQL
     * "notations_unique_par_commande", pas ici.
     */
    public function create(User $user, Commande $commande, int $agriculteurId): bool
    {
        if ($user->id !== $commande->acheteur_id) {
            return false;
        }

        if ($commande->statut !== 'livree') {
            return false;
        }

        return $commande->produits()->where('agriculteur_id', $agriculteurId)->exists();
    }
}
