<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\StoreProduitRequest;
use App\Http\Requests\Api\UpdateProduitRequest;
use App\Http\Resources\ProduitResource;
use App\Models\Produit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

/**
 * Limite du forfait gratuit — nombre max de produits publiés simultanément.
 * Au-delà, l'agriculteur doit passer premium (voir store()).
 */
class AgriculteurProduitController extends Controller
{
    private const LIMITE_PRODUITS_GRATUIT = 2;

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
     * multipart/form-data si une photo est envoyée.
     */
    public function store(StoreProduitRequest $request)
    {
        $user = $request->user();

        if (! $user->is_subscribed && $user->produits()->count() >= self::LIMITE_PRODUITS_GRATUIT) {
            return response()->json([
                'message' => 'Le forfait gratuit est limité à '.self::LIMITE_PRODUITS_GRATUIT.' produits publiés. Passe au premium pour publier sans limite.',
                'limite_atteinte' => true,
            ], 403);
        }

        $data = $request->validated();

        if ($request->hasFile('image')) {
            $data['image'] = $request->file('image')->store('produits', 'public');
        }

        $produit = $user->produits()->create($data);

        return new ProduitResource($produit->load('agriculteur'));
    }

    /**
     * PUT/PATCH /api/mes-produits/{produit}
     * multipart/form-data si une nouvelle photo est envoyée.
     */
    public function update(UpdateProduitRequest $request, Produit $produit)
    {
        $this->authorize('update', $produit);

        $data = $request->validated();

        if ($request->hasFile('image')) {
            if ($produit->image) {
                Storage::disk('public')->delete($produit->image);
            }
            $data['image'] = $request->file('image')->store('produits', 'public');
        }

        $produit->update($data);

        return new ProduitResource($produit->load('agriculteur'));
    }

    /**
     * DELETE /api/mes-produits/{produit}
     */
    public function destroy(Request $request, Produit $produit)
    {
        $this->authorize('delete', $produit);

        if ($produit->image) {
            Storage::disk('public')->delete($produit->image);
        }

        $produit->delete();

        return response()->json(['message' => 'Produit supprimé.']);
    }
}
