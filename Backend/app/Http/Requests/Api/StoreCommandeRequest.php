<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class StoreCommandeRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->role === 'acheteur';
    }

    public function rules(): array
    {
        return [
            'produits' => ['required', 'array', 'min:1'],
            'produits.*.id' => ['required', 'exists:produits,id'],
            'produits.*.quantite' => ['required', 'integer', 'min:1'],
        ];
    }

    public function messages(): array
    {
        return [
            'produits.required' => 'La commande doit contenir au moins un produit.',
            'produits.*.id.exists' => 'Un des produits sélectionnés n\'existe pas.',
        ];
    }
}
