<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MessageResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'livraison_id' => $this->livraison_id,
            'expediteur_id' => $this->expediteur_id,
            'expediteur_role' => $this->expediteur->role,
            'contenu' => $this->contenu,
            'lu' => $this->lu,
            'created_at' => $this->created_at,
        ];
    }
}
