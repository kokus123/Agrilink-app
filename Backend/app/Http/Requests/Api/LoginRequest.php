<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class LoginRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
            // Optionnel : Flutter peut envoyer un nom d'appareil pour identifier le token
            'device_name' => ['nullable', 'string', 'max:255'],
        ];
    }
}
