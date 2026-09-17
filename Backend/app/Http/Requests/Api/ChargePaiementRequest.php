<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class ChargePaiementRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // ownership check is in PaiementController::payer
    }

    public function rules(): array
    {
        return [
            'operateur' => ['required', 'in:mtn,orange'],
            'phone' => ['required', 'regex:/^\+237[0-9]{9}$/'],
        ];
    }

    public function messages(): array
    {
        return [
            'phone.regex' => 'Le numéro doit être au format +237XXXXXXXXX.',
        ];
    }
}
