<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class LivraisonResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'statut' => $this->statut,
            'latitude_actuelle' => $this->latitude_actuelle,
            'longitude_actuelle' => $this->longitude_actuelle,
            'date_livraison_prevue' => $this->date_livraison_prevue,
            'date_livraison_reelle' => $this->date_livraison_reelle,
            'commande' => [
                'id' => $this->commande->id,
                'montant_total' => (float) $this->commande->montant_total,
                'acheteur' => [
                    'id' => $this->commande->acheteur->id,
                    'name' => $this->commande->acheteur->name,
                    'phone' => $this->commande->acheteur->phone,
                    'latitude' => $this->commande->acheteur->latitude ?? null,
                    'longitude' => $this->commande->acheteur->longitude ?? null,
                ],
                'produits' => $this->commande->produits->map(fn ($p) => [
                    'nom' => $p->nom,
                    'quantite' => $p->pivot->quantite,
                ]),
            ],
        ];
    }
}
