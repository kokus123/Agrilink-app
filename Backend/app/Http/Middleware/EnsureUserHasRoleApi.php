<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureUserHasRoleApi
{
    /**
     * Équivalent API de EnsureUserHasRole : renvoie du JSON au lieu de rediriger.
     * Usage : ->middleware('role:acheteur')
     */
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();

        if (! $user) {
            return response()->json(['message' => 'Non authentifié.'], 401);
        }

        if (! $user->is_active) {
            return response()->json(['message' => "Votre compte a été suspendu par l'administrateur."], 403);
        }

        if (! in_array($user->role, $roles, true)) {
            return response()->json(['message' => 'Accès non autorisé pour votre rôle.'], 403);
        }

        return $next($request);
    }
}
