<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Paiement;
use Illuminate\Http\Request;

class AbonnementController extends Controller
{
    /** Forfait Premium unique — FCFA par mois. */
    private const TARIF_PREMIUM = 5000;

    /**
     * POST /api/abonnement/souscrire
     * Crée le paiement en attente pour 1 mois de Premium. Le client doit
     * ensuite appeler POST /api/paiements/{id}/payer pour déclencher le
     * Mobile Money. L'activation réelle (is_subscribed = true) se fait
     * uniquement via PaiementWebhookController, jamais ici.
     */
    public function souscrire(Request $request)
    {
        $validated = $request->validate([
            'methode' => ['required', 'string'],
        ]);

        $paiement = Paiement::create([
            'user_id' => $request->user()->id,
            'type' => 'abonnement',
            'montant' => self::TARIF_PREMIUM,
            'methode' => $validated['methode'],
            'statut' => 'en_attente',
            'duree_mois' => 1,
        ]);

        return response()->json([
            'message' => 'Souscription initiée, en attente de confirmation du paiement.',
            'paiement_id' => $paiement->id,
            'montant' => self::TARIF_PREMIUM,
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
