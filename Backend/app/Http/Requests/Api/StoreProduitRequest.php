<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class StoreProduitRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->role === 'agriculteur';
    }

    public function rules(): array
    {
        return [
            'nom' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'categorie' => ['nullable', 'string', 'max:100'],
            'prix' => ['required', 'numeric', 'min:0'],
            'quantite_disponible' => ['required', 'integer', 'min:0'],
            // Vrai fichier envoyé en multipart/form-data (max 4 Mo, jpg/png/webp).
            'image' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:4096'],
        ];
    }
}
