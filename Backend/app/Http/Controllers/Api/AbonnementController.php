<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Paiement;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AbonnementController extends Controller
{
    /**
     * POST /api/abonnement/souscrire
     * Initie une souscription premium. Le statut réel du paiement sera confirmé
     * par le webhook de l'API de paiement (Phase 4 de la feuille de route).
     */
    public function souscrire(Request $request)
    {
        $validated = $request->validate([
            'duree_mois' => ['required', Rule::in([1, 3, 6, 12])],
            'methode' => ['required', 'string'],
        ]);

        $tarifs = [1 => 2000, 3 => 5500, 6 => 10000, 12 => 18000]; // FCFA, à ajuster
        $montant = $tarifs[$validated['duree_mois']];

        $paiement = Paiement::create([
            'user_id' => $request->user()->id,
            'type' => 'abonnement',
            'montant' => $montant,
            'methode' => $validated['methode'],
            'statut' => 'en_attente',
        ]);

        // NOTE : l'activation réelle (is_subscribed = true) se fera via le webhook
        // de confirmation de paiement, pas ici directement — pour éviter d'activer
        // un abonnement qui n'a pas été payé.

        return response()->json([
            'message' => 'Souscription initiée, en attente de confirmation du paiement.',
            'paiement_id' => $paiement->id,
            'montant' => $montant,
        ], 201);
    }

    /**
     * GET /api/abonnement/statut
     */
    public function statut(Request $request)
    {
        $user = $request->user();

        return response()->json([
            'is_subscribed' => $user->is_subscribed,
            'subscription_expires_at' => $user->subscription_expires_at,
        ]);
    }
}
