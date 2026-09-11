<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\StoreProduitRequest;
use App\Http\Requests\Api\UpdateProduitRequest;
use App\Http\Resources\ProduitResource;
use App\Models\Produit;
use Illuminate\Http\Request;

class AgriculteurProduitController extends Controller
{
    /**
     * GET /api/mes-produits
     */
    public function index(Request $request)
    {
        $produits = $request->user()
            ->produits()
            ->latest()
            ->paginate(20);

        return ProduitResource::collection($produits);
    }

    /**
     * POST /api/mes-produits
     */
    public function store(StoreProduitRequest $request)
    {
        $produit = $request->user()->produits()->create($request->validated());

        return new ProduitResource($produit->load('agriculteur'));
    }

    /**
     * PUT/PATCH /api/mes-produits/{produit}
     */
    public function update(UpdateProduitRequest $request, Produit $produit)
    {
        $this->authorize('update', $produit);

        $produit->update($request->validated());

        return new ProduitResource($produit->load('agriculteur'));
    }

    /**
     * DELETE /api/mes-produits/{produit}
     */
    public function destroy(Request $request, Produit $produit)
    {
        $this->authorize('delete', $produit);

        $produit->delete();

        return response()->json(['message' => 'Produit supprimé.']);
    }
}
