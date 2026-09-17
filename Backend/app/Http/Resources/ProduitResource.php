<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProduitResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'nom' => $this->nom,
            'description' => $this->description,
            'categorie' => $this->categorie,
            'prix' => (float) $this->prix,
            'quantite_disponible' => $this->quantite_disponible,
            'unite' => $this->unite,
            'image' => $this->image ? url('/api/media/'.$this->image) : null,
            'statut' => $this->statut,
            'agriculteur' => [
                'id' => $this->agriculteur->id,
                'name' => $this->agriculteur->name,
                'moyenne_note' => $this->agriculteur->moyenne_note,
                'is_subscribed' => (bool) $this->agriculteur->is_subscribed,
            ],
            'created_at' => $this->created_at,
        ];
    }
}
