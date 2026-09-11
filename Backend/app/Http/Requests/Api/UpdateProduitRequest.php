<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class UpdateProduitRequest extends FormRequest
{
    public function authorize(): bool
    {
        // Le rôle est déjà vérifié par le middleware 'role.api:agriculteur'.
        // La propriété du produit est vérifiée par ProduitPolicy dans le contrôleur.
        return true;
    }

    public function rules(): array
    {
        return [
            'nom' => ['sometimes', 'required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'categorie' => ['nullable', 'string', 'max:100'],
            'prix' => ['sometimes', 'required', 'numeric', 'min:0'],
            'quantite_disponible' => ['sometimes', 'required', 'integer', 'min:0'],
            'statut' => ['sometimes', 'in:disponible,rupture,archive'],
            'image' => ['nullable', 'string'],
        ];
    }
}
