<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone,
            // Passe par /api/media/ (MediaController) plutôt que le lien
            // statique storage/ direct — voir MediaController.php pour la
            // raison (CORS avec php artisan serve).
            'photo' => $this->photo ? url('/api/media/'.$this->photo) : null,
            'role' => $this->role,
            'is_active' => $this->is_active,
            'is_subscribed' => $this->is_subscribed,
            'subscription_expires_at' => $this->subscription_expires_at,
            'created_at' => $this->created_at,
        ];
    }
}
