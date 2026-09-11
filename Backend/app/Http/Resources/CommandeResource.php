<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CommandeResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'montant_total' => (float) $this->montant_total,
            'statut' => $this->statut,
            'produits' => $this->produits->map(fn ($produit) => [
                'id' => $produit->id,
                'nom' => $produit->nom,
                'quantite' => $produit->pivot->quantite,
                'prix_unitaire' => (float) $produit->pivot->prix_unitaire,
            ]),
            'livraison' => $this->when($this->livraison, fn () => [
                'statut' => $this->livraison->statut,
                'transporteur' => $this->livraison->transporteur?->name,
                'date_livraison_prevue' => $this->livraison->date_livraison_prevue,
            ]),
            'created_at' => $this->created_at,
        ];
    }
}
