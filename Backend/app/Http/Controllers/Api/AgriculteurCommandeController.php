<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\CommandeResource;
use App\Models\Commande;
use App\Models\Livraison;
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
     * Crée (ou confirme) la demande de livraison, visible ensuite par les transporteurs disponibles.
     */
    public function notifierTransporteur(Request $request, Commande $commande)
    {
        $this->authorize('notifierTransporteur', $commande);

        $livraison = Livraison::firstOrCreate(
            ['commande_id' => $commande->id],
            ['statut' => 'en_attente']
        );

        $commande->update(['statut' => 'confirmee']);

        // TODO : notification push réelle aux transporteurs (FCM) une fois configurée côté Flutter

        return response()->json([
            'message' => 'Transporteur notifié, en attente de prise en charge.',
            'livraison_id' => $livraison->id,
        ]);
    }
}
