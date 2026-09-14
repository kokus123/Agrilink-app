<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class UpdateCommandeRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // vérification réelle : CommandePolicy::update dans le contrôleur
    }

    public function rules(): array
    {
        return [
            'produits' => ['required', 'array', 'min:1'],
            'produits.*.id' => ['required', 'integer', 'exists:produits,id'],
            'produits.*.quantite' => ['required', 'integer', 'min:1'],
        ];
    }
}
