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

    /**
     * "Demander un transporteur" : n'importe quel agriculteur ayant AU
     * MOINS un de ses produits dans cette commande — c'est le même
     * critère qu'AgriculteurCommandeController::index() utilise pour
     * lister les commandes visibles par un agriculteur.
     *
     * Cette méthode était absente jusqu'ici — le contrôleur appelait déjà
     * authorize('notifierTransporteur', ...) mais Laravel refuse toujours
     * (403) quand la Policy existe sans la méthode demandée, quel que soit
     * l'utilisateur connecté.
     */
    public function notifierTransporteur(User $user, Commande $commande): bool
    {
        return $user->role === 'agriculteur'
            && $commande->produits()->where('agriculteur_id', $user->id)->exists();
    }
}
