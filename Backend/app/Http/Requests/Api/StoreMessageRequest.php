<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class StoreMessageRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // real access check is LivraisonPolicy::chat in the controller
    }

    public function rules(): array
    {
        return [
            'contenu' => ['required', 'string', 'max:1000'],
        ];
    }
}
