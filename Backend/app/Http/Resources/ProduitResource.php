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
            'image' => $this->image,
            'statut' => $this->statut,
            'agriculteur' => [
                'id' => $this->agriculteur->id,
                'name' => $this->agriculteur->name,
                'moyenne_note' => $this->agriculteur->moyenne_note,
            ],
            'created_at' => $this->created_at,
        ];
    }
}
