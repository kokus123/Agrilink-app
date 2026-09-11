<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\StoreCommandeRequest;
use App\Http\Resources\CommandeResource;
use App\Models\Commande;
use App\Models\Paiement;
use App\Models\Produit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CommandeController extends Controller
{
    /**
     * GET /api/commandes
     * Historique des commandes de l'acheteur connecté
     */
    public function index(Request $request)
    {
        $commandes = $request->user()
            ->commandes()
            ->with(['produits', 'livraison.transporteur'])
            ->latest()
            ->paginate(15);

        return CommandeResource::collection($commandes);
    }

    /**
     * POST /api/commandes
     * Passer une commande avec un ou plusieurs produits
     */
    public function store(StoreCommandeRequest $request)
    {
        $commande = DB::transaction(function () use ($request) {
            $montantTotal = 0;
            $lignesProduits = [];

            foreach ($request->produits as $ligne) {
                $produit = Produit::findOrFail($ligne['id']);

                if ($produit->quantite_disponible < $ligne['quantite']) {
                    abort(422, "Stock insuffisant pour le produit : {$produit->nom}");
                }

                $sousTotal = $produit->prix * $ligne['quantite'];
                $montantTotal += $sousTotal;

                $lignesProduits[$produit->id] = [
                    'quantite' => $ligne['quantite'],
                    'prix_unitaire' => $produit->prix,
                ];

                // Décrémente le stock
                $produit->decrement('quantite_disponible', $ligne['quantite']);
            }

            $commande = Commande::create([
                'acheteur_id' => $request->user()->id,
                'montant_total' => $montantTotal,
                'statut' => 'en_attente',
            ]);

            $commande->produits()->attach($lignesProduits);

            // Trace du paiement à venir (statut réel mis à jour par le webhook API de paiement)
            Paiement::create([
                'user_id' => $request->user()->id,
                'type' => 'commande',
                'commande_id' => $commande->id,
                'montant' => $montantTotal,
                'statut' => 'en_attente',
            ]);

            return $commande;
        });

        $commande->load('produits');

        return new CommandeResource($commande);
    }

    /**
     * GET /api/commandes/{commande}
     */
    public function show(Commande $commande)
    {
        $this->authorize('view', $commande);

        $commande->load(['produits', 'livraison.transporteur']);

        return new CommandeResource($commande);
    }
}
