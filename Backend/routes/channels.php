<?php

use App\Models\Livraison;
use App\Models\User;
use Illuminate\Support\Facades\Broadcast;

/**
 * Canal privé de chat pour une livraison donnée.
 * Autorisé uniquement pour l'acheteur de la commande et le transporteur assigné
 * (le canal Pusher/Reverb correspondant côté Flutter est "private-livraison.{id}").
 */
Broadcast::channel('livraison.{livraisonId}', function (User $user, int $livraisonId) {
    $livraison = Livraison::with('commande')->find($livraisonId);

    if (! $livraison) {
        return false;
    }

    return $user->id === $livraison->transporteur_id
        || $user->id === $livraison->commande->acheteur_id;
});
