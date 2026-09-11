<?php

namespace App\Policies;

use App\Models\Produit;
use App\Models\User;

class ProduitPolicy
{
    /**
     * Modifier un produit : uniquement l'agriculteur propriétaire.
     */
    public function update(User $user, Produit $produit): bool
    {
        return $user->id === $produit->agriculteur_id;
    }

    /**
     * Supprimer un produit : uniquement l'agriculteur propriétaire.
     */
    public function delete(User $user, Produit $produit): bool
    {
        return $user->id === $produit->agriculteur_id;
    }
}
