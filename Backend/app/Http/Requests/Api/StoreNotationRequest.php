<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class StoreNotationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // real access check is NotationPolicy::create in the controller
    }

    public function rules(): array
    {
        return [
            'commande_id' => ['required', 'integer', 'exists:commandes,id'],
            'agriculteur_id' => ['required', 'integer', 'exists:users,id'],
            'note' => ['required', 'integer', 'between:1,5'],
            'commentaire' => ['nullable', 'string', 'max:1000'],
        ];
    }
}
