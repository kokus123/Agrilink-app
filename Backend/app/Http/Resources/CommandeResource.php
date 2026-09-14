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
            'acheteur' => $this->whenLoaded('acheteur', fn () => [
                'id' => $this->acheteur->id,
                'name' => $this->acheteur->name,
                'phone' => $this->acheteur->phone,
            ]),
            'produits' => $this->produits->map(fn ($produit) => [
                'id' => $produit->id,
                'nom' => $produit->nom,
                'quantite' => $produit->pivot->quantite,
                'prix_unitaire' => (float) $produit->pivot->prix_unitaire,
                'agriculteur_id' => $produit->agriculteur?->id,
                'agriculteur_nom' => $produit->agriculteur?->name,
            ]),
            'livraison' => $this->when($this->livraison, fn () => [
                'id' => $this->livraison->id,
                'statut' => $this->livraison->statut,
                'transporteur' => $this->livraison->transporteur?->name,
                // Nécessaire pour "Consulter transporteur"
                'transporteur_telephone' => $this->livraison->transporteur?->phone,
                'date_livraison_prevue' => $this->livraison->date_livraison_prevue,
            ]),
            'created_at' => $this->created_at,
        ];
    }
}
