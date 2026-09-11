<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\StoreNotationRequest;
use App\Models\Commande;
use App\Models\Notation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class NotationController extends Controller
{
    /**
     * POST /api/notations
     * Noter un agriculteur suite à une commande livrée.
     */
    public function store(StoreNotationRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $commande = Commande::findOrFail($validated['commande_id']);

        $this->authorize('create', [Notation::class, $commande, $validated['agriculteur_id']]);

        $notation = Notation::create([
            'acheteur_id' => $request->user()->id,
            'agriculteur_id' => $validated['agriculteur_id'],
            'commande_id' => $commande->id,
            'note' => $validated['note'],
            'commentaire' => $validated['commentaire'] ?? null,
        ]);

        return response()->json($notation, 201);
    }

    /**
     * GET /api/agriculteurs/{agriculteur}/notations
     * Consultable publiquement (fiche agriculteur, comme le catalogue produits).
     */
    public function index(int $agriculteur): AnonymousResourceCollection|JsonResponse
    {
        $notations = Notation::where('agriculteur_id', $agriculteur)
            ->with('acheteur:id,name')
            ->latest()
            ->paginate(15);

        return response()->json($notations);
    }
}
