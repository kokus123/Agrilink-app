<?php

namespace App\Policies;

use App\Models\Livraison;
use App\Models\User;

class LivraisonPolicy
{
    /**
     * Mettre à jour le statut ou consulter la position acheteur :
     * uniquement le transporteur assigné à cette livraison.
     */
    public function update(User $user, Livraison $livraison): bool
    {
        return $user->id === $livraison->transporteur_id;
    }

    public function view(User $user, Livraison $livraison): bool
    {
        return $user->id === $livraison->transporteur_id;
    }

    /**
     * Prendre en charge : n'importe quel transporteur, tant que la livraison
     * n'est pas déjà assignée (vérifié séparément dans le contrôleur, car
     * ce n'est pas une question de "propriété" mais de disponibilité).
     */
    public function prendreEnCharge(User $user, Livraison $livraison): bool
    {
        return $user->role === 'transporteur' && $livraison->transporteur_id === null;
    }
}
