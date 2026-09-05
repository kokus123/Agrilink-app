<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\LoginRequest;
use App\Http\Requests\Api\RegisterRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * POST /api/register
     */
    public function register(RegisterRequest $request)
    {
        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'phone' => $request->phone,
            'password' => Hash::make($request->password),
            'role' => $request->role,
            'is_active' => true,
            'is_subscribed' => false,
        ]);

        $token = $user->createToken($request->device_name ?? 'flutter-app')->plainTextToken;

        return response()->json([
            'message' => 'Compte créé avec succès.',
            'user' => new UserResource($user),
            'token' => $token,
        ], 201);
    }

    /**
     * POST /api/login
     */
    public function login(LoginRequest $request)
    {
        $user = User::where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Identifiants incorrects.'],
            ]);
        }

        if (! $user->is_active) {
            throw ValidationException::withMessages([
                'email' => ['Votre compte a été suspendu par l\'administrateur.'],
            ]);
        }

        $token = $user->createToken($request->device_name ?? 'flutter-app')->plainTextToken;

        return response()->json([
            'message' => 'Connexion réussie.',
            'user' => new UserResource($user),
            'token' => $token,
        ]);
    }

    /**
     * POST /api/logout
     * Protégée par le middleware 'auth:sanctum'
     */
    public function logout(Request $request)
    {
        // Révoque uniquement le token utilisé pour cette requête
        // (l'utilisateur reste connecté sur ses autres appareils)
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Déconnexion réussie.',
        ]);
    }

    /**
     * GET /api/me
     * Protégée par le middleware 'auth:sanctum'
     */
    public function me(Request $request)
    {
        return new UserResource($request->user());
    }
}