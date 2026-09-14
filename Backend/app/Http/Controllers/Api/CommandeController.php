<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\StoreCommandeRequest;
use App\Http\Requests\Api\UpdateCommandeRequest;
use App\Http\Resources\CommandeResource;
use App\Models\Commande;
use App\Models\Produit;
use Illuminate\Support\Facades\DB;

class CommandeController extends Controller
{
    /**
     * GET /api/commandes
     */
    public function index(\Illuminate\Http\Request $request)
    {
        $commandes = $request->user()
            ->commandes()
            ->with(['produits.agriculteur', 'livraison.transporteur'])
            ->latest()
            ->paginate(15);

        return CommandeResource::collection($commandes);
    }

    /**
     * POST /api/commandes
     * Le paiement n'intervient jamais ici (voir note dans le contrôleur
     * d'origine) — "Effectuer paiement" n'est relié qu'à "Passer premium".
     */
    public function store(StoreCommandeRequest $request)
    {
        $commande = DB::transaction(function () use ($request) {
            [$montantTotal, $lignesProduits] = $this->calculerLignes($request->produits, decrementer: true);

            $commande = Commande::create([
                'acheteur_id' => $request->user()->id,
                'montant_total' => $montantTotal,
                'statut' => 'en_attente',
            ]);

            $commande->produits()->attach($lignesProduits);

            return $commande;
        });

        $commande->load('produits.agriculteur');

        return new CommandeResource($commande);
    }

    /**
     * GET /api/commandes/{commande}
     */
    public function show(Commande $commande)
    {
        $this->authorize('view', $commande);

        $commande->load(['produits.agriculteur', 'livraison.transporteur']);

        return new CommandeResource($commande);
    }

    /**
     * PATCH /api/commandes/{commande}
     * Remplace entièrement les lignes de la commande (quantités modifiées,
     * produits ajoutés ou retirés) — uniquement tant que statut = en_attente.
     * On restitue d'abord le stock des anciennes lignes, puis on décrémente
     * à nouveau selon les nouvelles lignes.
     */
    public function update(UpdateCommandeRequest $request, Commande $commande)
    {
        $this->authorize('update', $commande);

        $commande = DB::transaction(function () use ($request, $commande) {
            // Restitue le stock des lignes actuelles avant de les remplacer
            foreach ($commande->produits as $ancienProduit) {
                $ancienProduit->increment('quantite_disponible', $ancienProduit->pivot->quantite);
            }

            [$montantTotal, $lignesProduits] = $this->calculerLignes($request->produits, decrementer: true);

            $commande->produits()->sync($lignesProduits);
            $commande->update(['montant_total' => $montantTotal]);

            return $commande;
        });

        $commande->load('produits.agriculteur');

        return new CommandeResource($commande);
    }

    /**
     * DELETE /api/commandes/{commande}
     * Annulation (pas une suppression physique — on garde l'historique) :
     * passe statut à 'annulee' et restitue le stock. Uniquement tant que
     * statut = en_attente (le producteur n'a pas encore commencé à traiter).
     */
    public function destroy(Commande $commande)
    {
        $this->authorize('delete', $commande);

        DB::transaction(function () use ($commande) {
            foreach ($commande->produits as $produit) {
                $produit->increment('quantite_disponible', $produit->pivot->quantite);
            }
            $commande->update(['statut' => 'annulee']);
        });

        return response()->json(['message' => 'Commande annulée.']);
    }

    /**
     * Calcule le montant total et les lignes pivot à partir d'un tableau
     * [{id, quantite}, ...], en vérifiant le stock disponible. Décrémente
     * le stock si $decrementer est vrai.
     */
    private function calculerLignes(array $lignesDemandees, bool $decrementer): array
    {
        $montantTotal = 0;
        $lignesProduits = [];

        foreach ($lignesDemandees as $ligne) {
            $produit = Produit::findOrFail($ligne['id']);

            if ($produit->quantite_disponible < $ligne['quantite']) {
                abort(422, "Stock insuffisant pour le produit : {$produit->nom}");
            }

            $montantTotal += $produit->prix * $ligne['quantite'];

            $lignesProduits[$produit->id] = [
                'quantite' => $ligne['quantite'],
                'prix_unitaire' => $produit->prix,
            ];

            if ($decrementer) {
                $produit->decrement('quantite_disponible', $ligne['quantite']);
            }
        }

        return [$montantTotal, $lignesProduits];
    }
}
