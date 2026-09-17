<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreProduitRequest extends FormRequest
{
    /**
     * Listes fermées plutôt qu'un enum MySQL — plus simple à faire évoluer
     * (pas de migration ALTER TABLE si on ajoute une catégorie/unité plus
     * tard), partagées avec UpdateProduitRequest.
     */
    public const CATEGORIES = [
        'Fruits', 'Légumes', 'Céréales', 'Tubercules', 'Légumineuses', 'Épices & Condiments', 'Autres',
    ];

    public const UNITES = [
        'KG', 'Sac', 'Filet', 'Cageot', 'Tas', 'Botte', 'Caisse', 'Unité (pièce)',
    ];

    public function authorize(): bool
    {
        return $this->user()->role === 'agriculteur';
    }

    public function rules(): array
    {
        return [
            'nom' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'categorie' => ['nullable', 'string', Rule::in(self::CATEGORIES)],
            'prix' => ['required', 'integer', 'min:0'],
            'quantite_disponible' => ['required', 'integer', 'min:0'],
            'unite' => ['required', 'string', Rule::in(self::UNITES)],
            // Vrai fichier envoyé en multipart/form-data (max 4 Mo, jpg/png/webp).
            'image' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:4096'],
        ];
    }
}
