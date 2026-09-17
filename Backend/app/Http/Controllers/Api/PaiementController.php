<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\ChargePaiementRequest;
use App\Models\Paiement;
use App\Services\NotchPayService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Str;

class PaiementController extends Controller
{
    /**
     * POST /api/paiements/{paiement}/payer
     *
     * Deux points importants, découverts en testant contre la vraie API :
     *
     * 1. NotchPay génère SA PROPRE référence (transaction.reference, ex:
     *    "trx.xxxxx") dans la réponse d'initialize() — c'est CELLE-LÀ qu'il
     *    faut utiliser pour l'étape de charge, pas notre référence interne.
     *
     * 2. Notre référence interne (envoyée comme `reference` à initialize())
     *    doit être UNIQUE À CHAQUE TENTATIVE, pas juste par paiement — si
     *    l'utilisateur retente après un échec, réutiliser la même valeur
     *    ("paiement_6" par ex.) donne une 409 "Reference already existing"
     *    côté NotchPay, qui se souvient de toutes les références déjà vues.
     */
    public function payer(ChargePaiementRequest $request, Paiement $paiement): JsonResponse
    {
        abort_if($paiement->user_id !== $request->user()->id, 403, "Ce paiement ne t'appartient pas.");
        abort_if($paiement->statut !== 'en_attente', 409, 'Ce paiement a déjà été traité.');

        $validated = $request->validated();
        $notreReference = "paiement_{$paiement->id}_".Str::random(8);
        $channel = $validated['operateur'] === 'orange' ? 'cm.orange' : 'cm.mtn';

        $notchpay = new NotchPayService(config('services.notchpay.public_key'));

        $init = $notchpay->initialize([
            'amount' => (int) $paiement->montant,
            'currency' => 'XAF',
            'phone' => $validated['phone'],
            'reference' => $notreReference,
            'description' => $paiement->type === 'abonnement'
                ? 'Abonnement premium AGRILINK'
                : "Commande AGRILINK #{$paiement->commande_id}",
        ]);

        $referenceNotchPay = $init['transaction']['reference'] ?? null;

        if (! $referenceNotchPay) {
            return response()->json([
                'message' => "Réponse NotchPay inattendue — impossible de récupérer la référence de transaction.",
            ], 502);
        }

        $paiement->update([
            'methode' => $validated['operateur'],
            'reference_api' => $referenceNotchPay,
        ]);

        $notchpay->chargeMobileMoney($referenceNotchPay, $channel, $validated['phone']);

        return response()->json([
            'message' => 'Paiement initié — vérifie ton téléphone pour confirmer.',
            'reference' => $referenceNotchPay,
        ], 202);
    }
}
