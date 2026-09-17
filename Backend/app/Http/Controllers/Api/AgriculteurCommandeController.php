<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\CommandeResource;
use App\Models\Commande;
use App\Models\Livraison;
use App\Services\LivraisonMatchingService;
use Illuminate\Http\Request;

class AgriculteurCommandeController extends Controller
{
    /**
     * GET /api/mes-commandes
     * Commandes contenant au moins un produit de l'agriculteur connecté
     */
    public function index(Request $request)
    {
        $commandes = Commande::whereHas('produits', function ($query) use ($request) {
                $query->where('agriculteur_id', $request->user()->id);
            })
            ->with(['produits' => function ($query) use ($request) {
                $query->where('agriculteur_id', $request->user()->id);
            }, 'acheteur', 'livraison.transporteur'])
            ->latest()
            ->paginate(15);

        return CommandeResource::collection($commandes);
    }

    /**
     * PATCH /api/commandes/{commande}/notifier-transporteur
     *
     * Crée la livraison puis tente de la proposer immédiatement au
     * transporteur disponible le plus proche (LivraisonMatchingService).
     * Si aucun n'est disponible, elle reste 'en_attente' — visible dans
     * le pool ouvert (GET /livraisons/disponibles) comme filet de
     * sécurité, un transporteur pourra toujours la prendre manuellement.
     */
    public function notifierTransporteur(Request $request, Commande $commande)
    {
        $this->authorize('notifierTransporteur', $commande);

        $livraison = Livraison::firstOrCreate(
            ['commande_id' => $commande->id],
            ['statut' => 'en_attente']
        );

        $commande->update(['statut' => 'confirmee']);

        if ($livraison->statut === 'en_attente' && $livraison->transporteur_id === null) {
            $candidat = (new LivraisonMatchingService())->trouverProchainTransporteur($livraison);

            if ($candidat) {
                $livraison->update(['transporteur_id' => $candidat->id, 'statut' => 'proposee']);
            }
        }

        return response()->json([
            'message' => $livraison->fresh()->statut === 'proposee'
                ? 'Transporteur notifié — une proposition a été envoyée.'
                : 'Transporteur notifié — aucun transporteur disponible pour le moment, en attente.',
            'livraison_id' => $livraison->id,
        ]);
    }
}
