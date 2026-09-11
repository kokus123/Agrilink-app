<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\ProduitResource;
use App\Models\Produit;
use Illuminate\Http\Request;

class ProduitController extends Controller
{
    /**
     * GET /api/produits
     * Catalogue avec recherche et filtres (Rechercher produit, Gerer catalogue)
     */
    public function index(Request $request)
    {
        $produits = Produit::with('agriculteur')
            ->disponibles()
            ->when($request->search, function ($query, $search) {
                $query->where('nom', 'like', "%{$search}%");
            })
            ->when($request->categorie, function ($query, $categorie) {
                $query->where('categorie', $categorie);
            })
            ->when($request->prix_max, function ($query, $prixMax) {
                $query->where('prix', '<=', $prixMax);
            })
            ->latest()
            ->paginate(20);

        return ProduitResource::collection($produits);
    }

    /**
     * GET /api/produits/{produit}
     */
    public function show(Produit $produit)
    {
        $produit->load('agriculteur');

        return new ProduitResource($produit);
    }
}
