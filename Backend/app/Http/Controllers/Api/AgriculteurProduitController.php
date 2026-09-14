<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\StoreProduitRequest;
use App\Http\Requests\Api\UpdateProduitRequest;
use App\Http\Resources\ProduitResource;
use App\Models\Produit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

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
     * multipart/form-data si une photo est envoyée.
     */
    public function store(StoreProduitRequest $request)
    {
        $data = $request->validated();

        if ($request->hasFile('image')) {
            // Stocké sur le disque "public" (storage/app/public/produits/...),
            // accessible ensuite via /storage/produits/... après `php artisan storage:link`.
            $data['image'] = $request->file('image')->store('produits', 'public');
        }

        $produit = $request->user()->produits()->create($data);

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
            // Supprime l'ancienne photo avant d'enregistrer la nouvelle,
            // pour ne pas accumuler des fichiers orphelins sur le disque.
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
