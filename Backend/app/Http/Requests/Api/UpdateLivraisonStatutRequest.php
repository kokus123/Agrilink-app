<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateLivraisonStatutRequest extends FormRequest
{
    public function authorize(): bool
    {
        // Le rôle est déjà vérifié par le middleware 'role.api:transporteur'.
        // L'appartenance de la livraison est vérifiée par LivraisonPolicy dans le contrôleur.
        return true;
    }

    public function rules(): array
    {
        return [
            'statut' => ['required', Rule::in(['en_cours', 'livree', 'annulee'])],
        ];
    }
}
