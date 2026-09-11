<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\UpdateLivraisonStatutRequest;
use App\Http\Resources\LivraisonResource;
use App\Models\Livraison;
use Illuminate\Http\Request;

class LivraisonController extends Controller
{
    /**
     * GET /api/livraisons/disponibles
     * Livraisons en attente, pas encore prises par un transporteur (Gerer livraison)
     */
    public function disponibles()
    {
        $livraisons = Livraison::whereNull('transporteur_id')
            ->where('statut', 'en_attente')
            ->with(['commande.acheteur', 'commande.produits'])
            ->latest()
            ->paginate(15);

        return LivraisonResource::collection($livraisons);
    }

    /**
     * GET /api/livraisons
     * Livraisons assignées au transporteur connecté
     */
    public function index(Request $request)
    {
        $livraisons = $request->user()
            ->livraisons()
            ->with(['commande.acheteur', 'commande.produits'])
            ->latest()
            ->paginate(15);

        return LivraisonResource::collection($livraisons);
    }

    /**
     * PATCH /api/livraisons/{livraison}/prendre-en-charge
     * Le transporteur s'assigne une livraison disponible
     */
    public function prendreEnCharge(Request $request, Livraison $livraison)
    {
        abort_if($livraison->transporteur_id !== null, 409, 'Cette livraison a déjà été prise en charge.');

        $this->authorize('prendreEnCharge', $livraison);

        $livraison->update([
            'transporteur_id' => $request->user()->id,
            'statut' => 'en_cours',
        ]);

        return new LivraisonResource($livraison->load('commande.acheteur', 'commande.produits'));
    }

    /**
     * PATCH /api/livraisons/{livraison}/statut
     */
    public function updateStatut(UpdateLivraisonStatutRequest $request, Livraison $livraison)
    {
        $this->authorize('update', $livraison);

        $livraison->update([
            'statut' => $request->statut,
            'date_livraison_reelle' => $request->statut === 'livree' ? now() : null,
        ]);

        // Répercute sur la commande liée
        if ($request->statut === 'livree') {
            $livraison->commande->update(['statut' => 'livree']);
        } elseif ($request->statut === 'annulee') {
            $livraison->commande->update(['statut' => 'annulee']);
        }

        return new LivraisonResource($livraison->load('commande.acheteur', 'commande.produits'));
    }

    /**
     * GET /api/livraisons/{livraison}/position-acheteur
     * Consulter position acheteur
     */
    public function positionAcheteur(Request $request, Livraison $livraison)
    {
        $this->authorize('view', $livraison);

        $acheteur = $livraison->commande->acheteur;

        return response()->json([
            'latitude' => $acheteur->latitude,
            'longitude' => $acheteur->longitude,
            'position_updated_at' => $acheteur->position_updated_at,
        ]);
    }
}
