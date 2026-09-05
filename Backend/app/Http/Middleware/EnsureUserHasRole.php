<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureUserHasRole
{
    /**
     * Vérifie que l'utilisateur connecté a l'un des rôles autorisés.
     * Usage dans les routes : ->middleware('role:admin')
     * Plusieurs rôles possibles : ->middleware('role:admin,agriculteur')
     */
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();

        if (! $user) {
            return redirect()->route('login');
        }

        if (! $user->is_active) {
            abort(403, "Votre compte a été suspendu par l'administrateur.");
        }

        if (! in_array($user->role, $roles, true)) {
            abort(403, "Accès non autorisé pour votre rôle.");
        }

        return $next($request);
    }
}
