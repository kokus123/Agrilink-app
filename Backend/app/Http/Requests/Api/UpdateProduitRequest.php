<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

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
            'categorie' => ['nullable', 'string', Rule::in(StoreProduitRequest::CATEGORIES)],
            'prix' => ['sometimes', 'required', 'integer', 'min:0'],
            'quantite_disponible' => ['sometimes', 'required', 'integer', 'min:0'],
            'unite' => ['sometimes', 'required', 'string', Rule::in(StoreProduitRequest::UNITES)],
            'statut' => ['sometimes', 'in:disponible,rupture,archive'],
            // Vrai fichier envoyé en multipart/form-data (max 4 Mo, jpg/png/webp).
            // Absent du form => on garde l'image existante (voir contrôleur).
            'image' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:4096'],
        ];
    }
}
