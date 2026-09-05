<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rules\Password;

class RegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // route publique, pas besoin d'être connecté pour s'inscrire
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users,email'],
            'phone' => ['nullable', 'string', 'max:30'],
            'password' => ['required', 'confirmed', Password::defaults()],

            // Inscription publique limitée à Acheteur et Agriculteur.
            // Transporteur : compte créé exclusivement par l'administrateur (traçabilité).
            'role' => ['required', 'in:acheteur,agriculteur'],
        ];
    }

    public function messages(): array
    {
        return [
            'email.unique' => 'Cet email est déjà utilisé.',
            'role.in' => 'Vous ne pouvez vous inscrire qu\'en tant qu\'Acheteur ou Agriculteur.',
        ];
    }
}
