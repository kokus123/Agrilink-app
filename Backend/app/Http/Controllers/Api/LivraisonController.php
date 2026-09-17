<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\UpdateLivraisonStatutRequest;
use App\Http\Resources\LivraisonResource;
use App\Models\Livraison;
use App\Models\LivraisonRefus;
use App\Services\LivraisonMatchingService;
use Illuminate\Http\Request;

class LivraisonController extends Controller
{
    /**
     * GET /api/livraisons/disponibles
     * Filet de sécurité : livraisons pour lesquelles le matching
     * automatique n'a trouvé personne (statut encore 'en_attente',
     * jamais proposées) — un transporteur peut les prendre manuellement.
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
     * GET /api/livraisons/propositions
     * Livraisons actuellement proposées au transporteur connecté,
     * en attente de sa décision (Accepter / Refuser).
     */
    public function propositions(Request $request)
    {
        $livraisons = Livraison::where('transporteur_id', $request->user()->id)
            ->where('statut', 'proposee')
            ->with(['commande.acheteur', 'commande.produits'])
            ->latest()
            ->paginate(15);

        return LivraisonResource::collection($livraisons);
    }

    /**
     * GET /api/livraisons
     * Livraisons assignées et acceptées par le transporteur connecté
     * (exclut celles encore au stade 'proposee', qui vont dans
     * propositions() ci-dessus).
     */
    public function index(Request $request)
    {
        $livraisons = $request->user()
            ->livraisons()
            ->where('statut', '!=', 'proposee')
            ->with(['commande.acheteur', 'commande.produits'])
            ->latest()
            ->paginate(15);

        return LivraisonResource::collection($livraisons);
    }

    /**
     * PATCH /api/livraisons/{livraison}/prendre-en-charge
     * Filet de sécurité : prise en charge manuelle d'une livraison du
     * pool ouvert (disponibles()) — pas d'une livraison déjà proposée.
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
     * PATCH /api/livraisons/{livraison}/accepter
     * Le transporteur accepte une livraison qui lui a été proposée par
     * le matching automatique.
     */
    public function accepter(Request $request, Livraison $livraison)
    {
        $this->authorize('accepter', $livraison);
        abort_if($livraison->statut !== 'proposee', 409, "Cette livraison n'est plus en attente de ta décision.");

        $livraison->update(['statut' => 'en_cours']);

        return new LivraisonResource($livraison->load('commande.acheteur', 'commande.produits'));
    }

    /**
     * PATCH /api/livraisons/{livraison}/refuser
     * Le transporteur refuse — on l'exclut des propositions futures pour
     * CETTE livraison précise, puis on retente le matching pour trouver
     * le prochain candidat le plus proche. Si personne n'est disponible,
     * elle retombe dans le pool ouvert (disponibles()).
     */
    public function refuser(Request $request, Livraison $livraison)
    {
        $this->authorize('refuser', $livraison);
        abort_if($livraison->statut !== 'proposee', 409, "Cette livraison n'est plus en attente de ta décision.");

        LivraisonRefus::firstOrCreate([
            'livraison_id' => $livraison->id,
            'transporteur_id' => $request->user()->id,
        ]);

        $livraison->update(['transporteur_id' => null]);

        $candidat = (new LivraisonMatchingService())->trouverProchainTransporteur($livraison->fresh());

        if ($candidat) {
            $livraison->update(['transporteur_id' => $candidat->id, 'statut' => 'proposee']);
        } else {
            $livraison->update(['statut' => 'en_attente']);
        }

        return response()->json(['message' => 'Livraison refusée.']);
    }

    /**
     * PATCH /api/livraisons/{livraison}/statut
     * Une fois acceptée (en_cours) : faire avancer vers livree/annulee.
     */
    public function updateStatut(UpdateLivraisonStatutRequest $request, Livraison $livraison)
    {
        $this->authorize('update', $livraison);

        $livraison->update([
            'statut' => $request->statut,
            'date_livraison_reelle' => $request->statut === 'livree' ? now() : null,
        ]);

        if ($request->statut === 'livree') {
            $livraison->commande->update(['statut' => 'livree']);
        } elseif ($request->statut === 'annulee') {
            $livraison->commande->update(['statut' => 'annulee']);
        }

        return new LivraisonResource($livraison->load('commande.acheteur', 'commande.produits'));
    }

    /**
     * GET /api/livraisons/{livraison}/position-acheteur
     * Côté Transporteur : consulter position acheteur.
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

    /**
     * GET /api/livraisons/{livraison}/position-transporteur
     * Côté Acheteur : suivre le transporteur en temps réel (façon Yango).
     * Lit latitude_actuelle/longitude_actuelle sur la livraison elle-même
     * (déjà alimentées par PositionController quand statut = en_cours).
     */
    public function positionTransporteur(Request $request, Livraison $livraison)
    {
        $this->authorize('consulterPositionTransporteur', $livraison);

        return response()->json([
            'latitude' => $livraison->latitude_actuelle,
            'longitude' => $livraison->longitude_actuelle,
            'transporteur_nom' => $livraison->transporteur?->name,
        ]);
    }
}
