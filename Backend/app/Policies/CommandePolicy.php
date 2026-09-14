<?php

namespace App\Policies;

use App\Models\Commande;
use App\Models\User;

class CommandePolicy
{
    public function view(User $user, Commande $commande): bool
    {
        return $user->id === $commande->acheteur_id;
    }

    /**
     * Modifier une commande : uniquement le propriétaire, et uniquement
     * tant qu'elle est encore en_attente (le producteur n'a pas commencé
     * à la traiter).
     */
    public function update(User $user, Commande $commande): bool
    {
        return $user->id === $commande->acheteur_id && $commande->statut === 'en_attente';
    }

    /**
     * Annuler une commande : mêmes conditions que la modification.
     */
    public function delete(User $user, Commande $commande): bool
    {
        return $user->id === $commande->acheteur_id && $commande->statut === 'en_attente';
    }
}
