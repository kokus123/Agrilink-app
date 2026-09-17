<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Paiement;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Log;

class PaiementWebhookController extends Controller
{
    /**
     * POST /api/webhooks/notchpay
     * Route publique (pas de auth:sanctum) mais protégée par la signature HMAC
     * Notch Pay — c'est ce webhook qui confirme réellement un paiement, jamais
     * la réponse synchrone de PaiementController::payer().
     */
    public function handle(Request $request): Response
    {
        $signature = (string) $request->header('x-notch-signature', '');
        $payload = $request->getContent();
        $hash = (string) config('services.notchpay.webhook_hash');

        $expected = hash_hmac('sha256', $payload, $hash);

        if ($signature === '' || ! hash_equals($expected, $signature)) {
            Log::warning('NotchPay webhook: invalid signature');

            return response('Invalid signature', 400);
        }

        // La doc NotchPay utilise tantôt "event", tantôt "type" pour le nom
        // de l'événement selon la page — on gère les deux par sécurité.
        $event = $request->input('event') ?? $request->input('type');

        // data.reference est la référence NotchPay ("trx.xxxxx"), PAS notre
        // référence interne — on la fait correspondre à ce qu'on a stocké
        // dans reference_api lors de PaiementController::payer().
        $referenceNotchPay = $request->input('data.reference');

        if (! $referenceNotchPay) {
            return response('OK', 200); // événement sans référence exploitable
        }

        $paiement = Paiement::where('reference_api', $referenceNotchPay)->first();

        // Idempotent : paiement inconnu ou déjà traité (webhook potentiellement rejoué)
        if (! $paiement || $paiement->statut !== 'en_attente') {
            return response('OK', 200);
        }

        match ($event) {
            'payment.complete' => $this->marquerReussi($paiement),
            'payment.failed' => $paiement->update(['statut' => 'echoue']),
            default => null,
        };

        return response('OK', 200);
    }

    private function marquerReussi(Paiement $paiement): void
    {
        $paiement->update(['statut' => 'reussi']);

        if ($paiement->type === 'abonnement' && $paiement->duree_mois) {
            $paiement->user->update([
                'is_subscribed' => true,
                'subscription_expires_at' => now()->addMonths($paiement->duree_mois),
            ]);
        }
    }
}
