<?php

namespace App\Policies;

use App\Models\Commande;
use App\Models\User;

class CommandePolicy
{
    /**
     * Voir une commande :
     * - l'acheteur qui l'a passée
     * - un agriculteur dont au moins un produit est dans la commande
     * - le transporteur assigné à sa livraison
     */
    public function view(User $user, Commande $commande): bool
    {
        if ($user->role === 'acheteur') {
            return $user->id === $commande->acheteur_id;
        }

        if ($user->role === 'agriculteur') {
            return $commande->produits()->where('agriculteur_id', $user->id)->exists();
        }

        if ($user->role === 'transporteur') {
            return $commande->livraison && $commande->livraison->transporteur_id === $user->id;
        }

        return false;
    }

    /**
     * Notifier un transporteur : uniquement un agriculteur ayant un produit dans la commande.
     */
    public function notifierTransporteur(User $user, Commande $commande): bool
    {
        return $user->role === 'agriculteur'
            && $commande->produits()->where('agriculteur_id', $user->id)->exists();
    }
}
